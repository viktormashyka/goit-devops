# GoIT DevOps Terraform & Kubernetes Project (lesson-8-9)

## Опис проєкту

Це проєкт інфраструктурної автоматизації.  
Автоматично створюється S3, DynamoDB, VPC, ECR, Kubernetes-кластер (EKS), а Django-застосунок деплоїться у кластер за допомогою Helm-чарта з підтримкою autoscaling, LoadBalancer та ConfigMap.

---

## Структура проєкту

```
lesson-8-9/
├── backend.tf
├── LICENSE
├── main.tf
├── outputs.tf
├── variables.tf
├── README.md
├── .gitignore
├── charts/
│   └── django-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── terraform.tfstate
│       └── templates/
│           ├── configmap.yaml
│           ├── deployment.yaml
│           ├── hpa.yaml
│           └── service.yaml
├── django/
│   └── Jenkinsfile
├── modules/
│   ├── argo_cd/
│   │   ├── argo_cd.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── values.yaml
│   │   ├── variables.tf
│   │   └── charts/
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── application.yaml
│   │           └── repository.yaml
│   ├── ecr/
│   │   ├── ecr.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── eks/
│   │   ├── aws_ebs_csi_driver.tf
│   │   ├── eks.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── jenkins/
│   │   ├── jenkins.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── values.yaml
│   │   └── variables.tf
│   ├── s3-backend/
│   │   ├── dynamodb.tf
│   │   ├── outputs.tf
│   │   ├── s3.tf
│   │   └── variables.tf
│   └── vpc/
│       ├── outputs.tf
│       ├── routes.tf
│       ├── variables.tf
│       └── vpc.tf
├── nginx/
│   └── nginx.conf/
```

---

## Попередні вимоги

- AWS акаунт з налаштованим профілем у `~/.aws/credentials`
- Встановлені: [Terraform](https://www.terraform.io/downloads), [kubectl](https://kubernetes.io/docs/tasks/tools/), [Helm](https://helm.sh/docs/intro/install/), [Docker](https://docs.docker.com/get-docker/)

> **Примітка:**  
> Для роботи з AWS всі команди використовують облікові дані з файлу `~/.aws/credentials`.  
> Якщо у вас кілька профілів, додайте параметр `--profile <profile_name>` до команд AWS CLI.

---

## Основні команди для роботи з Terraform

```bash
terraform init      # Ініціалізація проєкту та підключення бекенду/модулів
terraform plan      # Перегляд плану змін, які будуть внесені в інфраструктуру
terraform apply     # Застосування змін (створення/оновлення ресурсів)
terraform destroy   # Видалення всіх створених ресурсів
terraform init -upgrade
```

---

## Важливо: Імпорт існуючих ресурсів

Якщо S3-бакет, DynamoDB-таблиця або ECR-репозиторій були створені вручну через AWS Console або CLI, їх потрібно імпортувати у Terraform state, щоб уникнути помилок дублювання.

### 1. Створіть ресурси вручну (якщо потрібно):

```bash
aws s3api create-bucket --bucket victor-mashyka --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2

aws ecr create-repository --repository-name lesson-7-ecr --region us-west-2
```

### 2. Імпортуйте ресурси у Terraform state:

```bash
terraform import module.s3_backend.aws_s3_bucket.terraform_state victor-mashyka
terraform import module.s3_backend.aws_dynamodb_table.terraform_locks terraform-locks
terraform import module.ecr.aws_ecr_repository.this lesson-7-ecr
```

### 3. Ініціалізація Terraform

```bash
terraform init

```

> Буде створено S3, DynamoDB, VPC, ECR, EKS.

---

###

```bash
terraform import 'module.eks.module.eks.module.kms.aws_kms_alias.this["cluster"]' alias/eks/lesson-7-eks
terraform import 'module.eks.module.eks.aws_cloudwatch_log_group.this[0]' /aws/eks/lesson-7-eks/cluster
terraform import 'module.eks.module.eks.aws_iam_openid_connect_provider.oidc_provider[0]' arn:aws:iam::952279327296:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/04E9DC92AA8FA1914D4C5917DFFFA23D
```

### 3. Застосування Terraform

```bash
terraform plan
terraform apply
```

### 4. Налаштування доступу до EKS-кластера

```bash
aws eks --region us-west-2 update-kubeconfig --name lesson-7-eks
```

> Якщо використовуєте не дефолтний профіль:
>
> ```bash
> aws eks --region us-west-2 --profile <profile_name> update-kubeconfig --name victor-mashyka
> ```

---

Go to the AWS Console → EKS → Clusters → lesson-7-eks
Create access entry -> next -> choose AmazonEKSClusterAdminPolicy -> add policy -> next -> create

---

Go to IAM > Users > [Your User] > Security credentials.
create user -> user name - terraform user -> Attach policies directly -> add AdministratorAccess -> next -> cerate user
Click on terraform-user to view the user details.
Go to the "Security credentials" tab.
Create an access key (for programmatic ccess).
Select "Command Line Interface (CLI)"
Download or copy the Access Key ID and Secret Access Key.

```bash
export AWS_ACCESS_KEY_ID=AKIA53OCFMJAL7D3UZHR
export AWS_SECRET_ACCESS_KEY=<aws-secret-key-from-aws-credentials>
export AWS_DEFAULT_REGION=us-west-2
aws sts get-caller-identity
aws eks --region us-west-2 update-kubeconfig --name lesson-7-eks
terraform apply
```

Log in to the AWS Console as the user/role that created the EKS cluster.
Go to EKS > Clusters > lesson-7-eks > Configuration > Access > Add-ons > Create access entry > aws-auth ConfigMap.
Edit the aws-auth ConfigMap to add your terraform-user’s ARN under mapUsers, like this:
mapUsers: |

- userarn: arn:aws:iam::<account-id>:user/terraform-user
  username: terraform-user
  groups:

  - system:masters

### 5. Побудова та завантаження Docker-образу Django у ECR

```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com

docker build -t <repo_name>:<tag> .

docker tag <repo_name>:<tag> <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/<repo_name>:<tag>

docker push <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/<repo_name>:<tag>
```

> Якщо використовуєте не дефолтний профіль:
>
> ```bash
> aws ecr get-login-password --region us-west-2 --profile <profile_name> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com
> ```

---

## Встановлення postgresql

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install my-postgres bitnami/postgresql

helm upgrade my-django-app .
```

---

### 6. Деплой Django-застосунку через Helm

```bash
cd charts/django-app

helm install my-django-app .

```

---

### 7. Перевірка доступу

- Дізнайтесь публічну IP-адресу:
  ```bash
  kubectl get svc
  ```
- Перейдіть у браузері за цією IP.

---

### 8. Масштабування (HPA)

- HPA автоматично масштабує поди при навантаженні CPU > 70% (від 2 до 6 подів).

---

### 9. Видалення інфраструктури без блокування стану

Якщо DynamoDB-таблиця для lock вже видалена, використовуйте:

```bash
terraform destroy -lock=false
```

---

## Вирішення типових помилок (з lesson-7)

- **S3 BucketNotEmpty:** Перед видаленням S3-бакета видаліть всі файли та версії об'єктів.
- **DynamoDB ResourceNotFoundException:** Якщо таблиця для lock вже видалена, використовуйте `terraform destroy -lock=false`.
- **RepositoryAlreadyExistsException:** Якщо ECR-репозиторій вже існує, імпортуйте його у state.
- **EKS AlreadyExistsException:** Якщо кластер вже існує, імпортуйте його у state.

---

## Опис модулів

### s3-backend

- Створює S3-бакет для зберігання стану Terraform (state file).
- Створює DynamoDB-таблицю для блокування стану (state locking).

### vpc

- Створює VPC з підмережами, маршрутами, Internet Gateway.

### ecr

- Створює ECR-репозиторій для Docker-образів.

### eks

- Створює EKS-кластер для запуску Kubernetes workloads (ім'я кластера: `victor-mashyka`, регіон: `us-west-2`).

---

## Опис Helm-чарту

- **Deployment:** деплой Django з образом з ECR, підключення ConfigMap через envFrom.
- **Service:** типу LoadBalancer для зовнішнього доступу.
- **HPA:** автоскейлінг подів (2-6) при CPU > 70%.
- **ConfigMap:** для змінних середовища.
- **values.yaml:** параметри образу, сервісу, autoscaler, змінних.

---

## CI/CD: Як застосувати та перевірити

### 1. Застосування Terraform

1. Ініціалізуйте Terraform:
   ```bash
   terraform init
   ```
2. Перегляньте план змін:
   ```bash
   terraform plan
   ```
3. Застосуйте зміни (створіть інфраструктуру):
   ```bash
   terraform apply
   ```

### 2. Перевірка Jenkins job

1. Відкрийте веб-інтерфейс Jenkins (URL можна знайти у Terraform output або через Helm):
   - Зайдіть у браузері за адресою Jenkins.
2. Знайдіть pipeline job для Django (або створіть, якщо потрібно).
3. Запустіть job вручну або дочекайтесь автоматичного запуску (наприклад, при push у репозиторій).
4. Переконайтесь, що всі етапи виконуються:
   - Build & Push Docker Image
   - Update Chart Tag in Git
5. Перевірте логи job — має бути успішний пуш Docker-образу в ECR та оновлення Helm chart у Git.

### 3. Перевірка результату в Argo CD

1. Відкрийте веб-інтерфейс Argo CD (URL можна знайти у Terraform output або через Helm):
   - Зайдіть у браузері за адресою Argo CD.
2. Авторизуйтесь (логін/пароль — див. outputs).
3. Знайдіть Application, який відповідає вашому Django-деплою.
4. Переконайтесь, що статус Application — "Synced" та "Healthy".
5. Перевірте, що у кластері деплойнувся новий Docker-образ із актуальним тегом (див. details у Argo CD).

---
