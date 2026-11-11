terraform {

  backend "s3" {

    bucket       = "terraform-buket-shah9009"
    region       = "ap-south-1"
    key          = "eks_dev/tfstate"
    use_lockfile = true

  }

}
