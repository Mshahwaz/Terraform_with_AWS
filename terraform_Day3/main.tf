resource "aws_instance" "sample_ins" {
  instance_type = var.instance_type
  ami           = var.ami
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
