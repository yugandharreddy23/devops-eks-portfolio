output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "fargate_profile_name" {
  value = aws_eks_fargate_profile.devops.fargate_profile_name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}
