# GoIT DevOps Terraform & Kubernetes Project (lesson-8-9)

## Опис проєкту

Це проєкт інфраструктурної автоматизації.  
Автоматично створюється S3, DynamoDB, VPC, ECR, Kubernetes-кластер (EKS), а Django-застосунок деплоїться у кластер за допомогою Helm-чарта з підтримкою autoscaling, LoadBalancer та ConfigMap.

---

## Структура проєкту

```
lesson-7/
├── main.tf
├── backend.tf
├── outputs.tf
├── modules/
│   ├── s3-backend/
│   ├── vpc/
│   ├── ecr/
│   └── eks/
├── charts/
│   └── django-app/
│       ├── templates/
│       ├── Chart.yaml
│       └── values.yaml
└── README.md
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

### 3. Ініціалізація та застосування Terraform

```bash
terraform init
terraform plan
terraform apply
```

> Буде створено S3, DynamoDB, VPC, ECR, EKS.

---

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

### 5. Побудова та завантаження Docker-образу Django у ECR

```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com

docker build -t <repo_name>:<tag> .

docker tag <repo_name>:<tag> <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/<repo_name>:<tag>

docker push <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/<repo_name>:<tag>
```

<!-- aws_account_id = 952279327296 -->
<!-- docker tag goit-devops-web:latest 952279327296.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr:latest -->
<!-- docker push 952279327296.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr:latest -->

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
