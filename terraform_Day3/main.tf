resource "aws_instance" "sample_ins" {
  instance_type     = var.instance_type
  ami               = var.ami
  key_name          = aws_key_pair.aws_kp.key_name
  availability_zone = var.availability_zone
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price                      = 0.0030
      instance_interruption_behavior = "stop"
      spot_instance_type             = "persistent"
    }
  }
  tags = {
    "Name"        = "${local.resource_prefix}-instance-server"
    "Env"         = var.environ
    "Market_type" = "spot"
  }
}

resource "aws_key_pair" "aws_kp" {
  key_name   = "deployer_key"
  public_key = file("D:/Terraform/keys/wazdom1-mum-key2.pub")
}