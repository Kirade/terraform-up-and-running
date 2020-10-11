terraform {
  backend "s3" {
    bucket  = "terraform-up-and-running-example-123"
    key     = "terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
  }
}

provider "aws" {
  region = "ap-northeast-2"
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-example-123"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}


resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-up-and-running-lock"
  hash_key       = "LockID"
  read_capacity  = 2
  write_capacity = 2

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}