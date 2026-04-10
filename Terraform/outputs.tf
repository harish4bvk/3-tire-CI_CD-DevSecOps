output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repo_url" {
  value = module.ecr.repository_url
}