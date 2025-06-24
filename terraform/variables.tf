variable "region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "devops-eks"
}

variable "cluster_name" {
  default = "devops-eks-portfolio-cluster"
}

variable "fargate_profile_name" {
  default = "devops-eks-fargate-profile"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
