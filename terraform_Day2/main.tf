terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~>6.0"
      }
    }

    required_version = ">=1.15"

    backend "s3" {
      bucket = "my-terraform-state-bucket-shah99009"
      key = "tfstate"
      region = "ap-south-1"
      use_lockfile = true
      encrypt = true
    }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "sample_bucket" {
  bucket = "sample-bucket-mshahwaz001"
}