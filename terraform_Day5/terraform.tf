terraform {

  required_version = "~>1.17.0"

  required_providers {

    aws = {

      source  = "hashicorp/aws"
      version = "~>6.60.0"
    }
  }
}

provider "aws" {

  region = "ap-south-1"

}
