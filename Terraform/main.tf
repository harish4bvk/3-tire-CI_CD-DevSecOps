############################################################
############## aws_availability_zones#######################
############################################################


data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}


locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}


##############################################################
#################### VPC Module ##############################
##############################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>5.0"
  ### VPC cluster_name
  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  #### Subnets Cidr
  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true # Cost-saving for dev; use one per AZ for prod

  ###### Tags required for EKS Auto Mode to discover subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

#######################################################
############### EKS Cluster Module#####################
#######################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"
  ### Cluster details
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  ### Cluster Network and environment
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets


  #### endpoints of the cluster
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true


  ### Cluster auth mode for auto mode
  authentication_mode = "API"


  ### cluster encryption for secutry
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = aws_kms_key.eks.arn
  }


  #### allow the current caller to manage the cluster
  enable_cluster_creator_admin_permissions = true

  ############### Node eks_managed_node_groups
  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.micro"]
    }
  }

  ##### depending on network creation
  depends_on = [module.vpc]

}

#######################################################
############### KMS key for EKS#####################
#######################################################

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.cluster_name}-eks-kms"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}