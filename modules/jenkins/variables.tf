variable "kubeconfig" {
  description = "Шлях до kubeconfig файлу"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Назва Kubernetes кластера"
  type        = string
}
