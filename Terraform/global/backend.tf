provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "harish-tf-state-bucket"
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}