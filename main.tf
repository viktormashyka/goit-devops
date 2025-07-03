# Terraform конфігурація для Lesson 7
## Використовуємо AWS як провайдер з регіоном us-west-2
provider "aws" {
  region = "us-west-2"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
    }
  }
}

## Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "victor-mashyka"
  table_name  = "terraform-locks"
}

## Підключаємо модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-7-vpc"
}

## Підключаємо модуль ECR
module "ecr" {
  source      = "./modules/ecr"
  ecr_name    = "lesson-7-ecr"
  scan_on_push = true
}

## Підключаємо модуль EKS
module "eks" {
  source         = "./modules/eks"
  cluster_name   = "lesson-7-eks"
  cluster_version = "1.29"
  subnet_ids     = module.vpc.public_subnets
  vpc_id         = module.vpc.vpc_id
  oidc_issuer_url = module.eks.cluster_oidc_issuer_url
}

module "jenkins" {
  source       = "./modules/jenkins"
  cluster_name = module.eks.cluster_id

  providers = {
    helm = helm
  }
}