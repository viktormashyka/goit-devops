# GoIT DevOps Terraform Project

## Опис структури проєкту

```
goit-devops/
├── backend.tf                # Налаштування бекенду Terraform (S3 + DynamoDB)
├── main.tf                   # Основний файл для підключення модулів
├── outputs.tf                # Глобальні outputs для проєкту
├── modules/
│   ├── ecr/                  # Модуль для створення ECR-репозиторію
│   ├── s3-backend/           # Модуль для S3-бакета та DynamoDB для стейтів
│   └── vpc/                  # Модуль для створення VPC, підмереж, маршрутів
```

## Основні команди для роботи з Terraform

```bash
terraform init      # Ініціалізація проєкту та підключення бекенду/модулів
terraform plan      # Перегляд плану змін, які будуть внесені в інфраструктуру
terraform apply     # Застосування змін (створення/оновлення ресурсів)
terraform destroy   # Видалення всіх створених ресурсів
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

aws ecr create-repository --repository-name lesson-5-ecr --region us-west-2
```

### 2. Імпортуйте ресурси у Terraform state:

```bash
terraform import module.s3_backend.aws_s3_bucket.terraform_state victor-mashyka
terraform import module.s3_backend.aws_dynamodb_table.terraform_locks terraform-locks
terraform import module.ecr.aws_ecr_repository.this lesson-5-ecr
```

### 3. Далі працюйте як звичайно:

```bash
terraform plan
terraform apply
```

### 4. Очистіть S3-бакет перед видаленням

```bash
aws s3api delete-objects --bucket victor-mashyka --delete "$(aws s3api list-object-versions --bucket victor-mashyka --output=json --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
aws s3api delete-objects --bucket victor-mashyka --delete "$(aws s3api list-object-versions --bucket victor-mashyka --output=json --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"
```

### 5. Видалення інфраструктури без блокування стану

Якщо DynamoDB-таблиця для lock вже видалена, використовуйте:

```bash
terraform destroy -lock=false
```

---

## Вирішення типових помилок

- **S3 BucketNotEmpty:** Перед видаленням S3-бакета видаліть всі файли та версії об'єктів (див. крок 4).
- **DynamoDB ResourceNotFoundException:** Якщо таблиця для lock вже видалена, використовуйте `terraform destroy -lock=false`.
- **RepositoryAlreadyExistsException:** Якщо ECR-репозиторій вже існує, імпортуйте його у state.

---

## Опис модулів

### s3-backend

- Створює S3-бакет для зберігання стану Terraform (state file).
- Створює DynamoDB-таблицю для блокування стану (state locking).
- Додає версіонування та контроль власності для S3-бакета.
- Outputs: назва S3-бакета та DynamoDB-таблиці.

### vpc

- Створює VPC з підмережами, маршрутами, Internet Gateway.
- Outputs: ID VPC, списки ID підмереж, ID Internet Gateway.

### ecr

- Створює ECR-репозиторій для Docker-образів.
- Вмикає автоматичне сканування образів.
- Додає політику доступу.
- Outputs: URL ECR-репозиторію.

---

> **Примітка:** Якщо ресурси вже існують у вашому AWS акаунті, обов’язково імпортуйте їх у Terraform state перед запуском `terraform apply`, щоб уникнути помилок дублювання та забезпечити коректну роботу Terraform.
