# Get current AWS caller identity
data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Configure the Kubernetes provider to connect to the newly created EKS cluster
# This configuration relies on outputs from the EKS module and the aws_eks_cluster_auth data source
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token

  # Set a short timeout if you're frequently hitting issues, but default is usually fine
  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   command     = "aws"
  #   args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
  # }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "BOTTLEROCKET_x86_64"
    instance_types = ["m5.large"]
  }

  eks_managed_node_groups = {
    devops-eks-cluster = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      tags = {
        ExtraTag = "helloworld"
      }
    }
  }

  tags = local.tags
}
# **NEW:** Manage aws-auth ConfigMap directly with Kubernetes provider
# This replaces the entire null_resource.aws_auth block
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = <<-EOT
      - rolearn: ${var.github_actions_role_arn}
        username: github-actions
        groups:
          - system:masters
    EOT
    mapUsers = <<-EOT
      - userarn: ${data.aws_caller_identity.current.arn}
        username: admin
        groups:
          - system:masters
    EOT
  }

  # Ensure this resource is created only after the EKS cluster is fully
  # provisioned and the Kubernetes provider can successfully authenticate.
  depends_on = [
    module.eks # Ensures EKS cluster is ready
  ]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets   = local.intra_subnets

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = 1
    "kubernetes.io/cluster/devops-eks-portfolio-cluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}