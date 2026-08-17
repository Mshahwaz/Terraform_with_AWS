terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~>6.0"
    }
  }
  required_version = ">= 1.15"
  # backend "s3" {
  #   bucket = "my-terraform-state-bucket-shah99009"
  #   key = "origin/tfstate"
  #   region = "ap-south-1"
  #   use_lockfile = true
  #   encrypt = true
  # }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "s3-state-bucket-01" {
  bucket = "my-terraform-state-bucket-shah99009"
  tags = {
    Name        = "tf-state-bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "s3-state-versioning" {
  bucket = aws_s3_bucket.s3-state-bucket-01.id
  versioning_configuration {
    status = "Enabled"
  }
}
