variable "aws_region" {
  description = "aws region"
  type        = string
  default     = "ap-south-1"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC Cidr"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "name of the cluster"
  type        = string
  default     = "App-eks"
}

variable "cluster_version" {
  description = "version of the eks cluster"
  type        = string
  default     = "1.32"
}
