
locals {
  resource_prefix = "${var.environ}-${var.region}"
}

# locals are the defined/calculated values inside module,for reusability / combining mulitple variables to derive meaningfull value
