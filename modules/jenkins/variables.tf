variable "oidc_provider_arn" {
  description = "OIDC provider ARN for EKS"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL for EKS"
  type        = string
}
variable "kubeconfig" {
  description = "Шлях до kubeconfig файлу"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Назва Kubernetes кластера"
  type        = string
}
