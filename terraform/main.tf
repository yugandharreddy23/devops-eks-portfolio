# main.tf

data "aws_caller_identity" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni = { most_recent = true }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

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

module "eks_aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.8.5"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = var.github_actions_role_arn
      username = "github-actions"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_users = [
    {
      userarn  = data.aws_caller_identity.current.arn
      username = "admin"
      groups   = ["system:masters"]
    }
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
