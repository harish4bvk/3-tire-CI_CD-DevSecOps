terraform {
  backend "s3" {
    bucket         = "harish-tf-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
  }
}