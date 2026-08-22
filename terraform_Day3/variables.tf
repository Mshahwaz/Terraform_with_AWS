
variable "region" {
  default = "ap-south-1"
  type    = string
}

variable "environ" {
  default = "dev"
  type    = string
}
variable "ami" {
  default = "ami-01a00762f46d584a1"
  type    = string
}

variable "instance_type" {
  default = "t3.micro"
  type    = string
}
variable "key_name" {
  default = "wazdom1-mum-kp"
  type    = string
}
variable "availability_zone" {
  default = "ap-south-1c"
  type    = string
}