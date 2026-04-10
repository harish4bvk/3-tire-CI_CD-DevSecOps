terraform {
  backend "s3" {
    bucket         = "harish-terraform-state-dev-jerney"
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
  }
}