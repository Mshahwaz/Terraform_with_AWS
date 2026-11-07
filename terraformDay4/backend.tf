terraform {

  backend "s3" {

    bucket       = "terraform-buket-shah9009"
    key          = "dev/tfstate"
    region       = "ap-south-1"
    use_lockfile = true

  }


}
