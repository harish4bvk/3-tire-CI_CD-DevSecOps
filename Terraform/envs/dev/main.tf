provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source     = "../../modules/vpc"
  cidr_block = "10.0.0.0/16"
}

module "eks" {
  source       = "../../modules/eks"
  cluster_name = "dev-eks"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
}

module "ecr" {
  source    = "../../modules/ecr"
  repo_name = "dev-app-repo"
}