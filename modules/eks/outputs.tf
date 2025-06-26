output "cluster_id" {
  value = module.eks.cluster_id
}

# output "kubeconfig" {
#   value = module.eks.kubeconfig
# }

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}