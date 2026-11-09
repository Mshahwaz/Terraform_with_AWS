resource "aws_vpc" "terra_demo_vpc" {

  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {

    Name = "demo_vpc"

  }

}

resource "aws_subnet" "terra_publicsub1" {

  vpc_id                  = aws_vpc.terra_demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {

    Name = "demo_public_subnet1"

  }

}



resource "aws_subnet" "terra_privatesub1" {

  vpc_id            = aws_vpc.terra_demo_vpc.id
  cidr_block        = "10.0.120.0/25"
  availability_zone = "ap-south-1b"
  tags = {

    Name = "demo_private_subnet1"

  }
}


resource "aws_subnet" "terra_publicsub2" {

  vpc_id                  = aws_vpc.terra_demo_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1c"
  map_public_ip_on_launch = true
  tags = {

    Name = "demo_public_subnet2"

  }

}



resource "aws_subnet" "terra_privatesub2" {

  vpc_id            = aws_vpc.terra_demo_vpc.id
  cidr_block        = "10.0.121.0/25"
  availability_zone = "ap-south-1c"
  tags = {

    Name = "demo_private_subnet2"

  }

}


resource "aws_internet_gateway" "terra_demo_vpc_igw" {

  vpc_id = aws_vpc.terra_demo_vpc.id

  tags = {

    Name = "demo_vpc_igw"
  }

}


resource "aws_route_table" "demo_vpc_public_route" {

  vpc_id = aws_vpc.terra_demo_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.terra_demo_vpc_igw.id

  }

  tags = {

    Name = "demo_public_route_table"

  }
}


# resource "aws_eip" "demo_nat_eip" {

#   domain = "vpc"

#   tags = {

#     Name = "demo-nat-eip"


#   }

# }

# resource "aws_nat_gateway" "demo_natgtw" {

#   allocation_id = aws_eip.demo_nat_eip.id

#   subnet_id = aws_subnet.terra_publicsub1.id

#   tags = {


#     Name = "demo-nat_gtw"
#   }

#   depends_on = [

#     aws_internet_gateway.terra_demo_vpc_igw


#   ]

# }

resource "aws_route_table_association" "public1" {

  subnet_id      = aws_subnet.terra_publicsub1.id
  route_table_id = aws_route_table.demo_vpc_public_route.id

}

resource "aws_route_table_association" "public2" {

  subnet_id      = aws_subnet.terra_publicsub2.id
  route_table_id = aws_route_table.demo_vpc_public_route.id

}

resource "aws_route_table" "demo_vpc_private_route" {
  vpc_id = aws_vpc.terra_demo_vpc.id

  # route {

  #   cidr_block = "0.0.0.0/0"

  #   # nat_gateway_id = aws_nat_gateway.demo_natgtw.id

  # }

  tags = {
    Name = "demo_private_route_table"
  }
}

resource "aws_route_table_association" "private1" {

  subnet_id      = aws_subnet.terra_privatesub1.id
  route_table_id = aws_route_table.demo_vpc_private_route.id

}

resource "aws_route_table_association" "private2" {

  subnet_id      = aws_subnet.terra_privatesub2.id
  route_table_id = aws_route_table.demo_vpc_private_route.id

}


resource "aws_security_group" "demo_bastion_sg" {

  name = "demo-bastion-sg"

  vpc_id = aws_vpc.terra_demo_vpc.id

  ingress {

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = "demo-bastion-ssh-sg"

  }

}

# resource "aws_security_group" "demo_app_sg" {

#   name = "demo-app-sg"

#   vpc_id = aws_vpc.terra_demo_vpc.id

#   ingress {

#     from_port       = 22
#     to_port         = 22
#     protocol        = "tcp"
#     security_groups = [aws_security_group.demo_bastion_sg.id]

#   }

#   ingress {

#     from_port       = 8
#     to_port         = -1
#     protocol        = "icmp"
#     security_groups = [aws_security_group.demo_bastion_sg.id]

#   }
#   egress {

#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]

#   }

#   tags = {

#     Name = "demo-app-ssh-sg"

#   }

# }

resource "aws_key_pair" "terra_key" {

  key_name   = "terra_key"
  public_key = file("terra_key.pub")
}

resource "aws_instance" "demo_bastion_ins" {

  ami           = "ami-0c7632fb77f35db43"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.terra_publicsub2.id

  vpc_security_group_ids = [
    aws_security_group.demo_bastion_sg.id
  ]

  associate_public_ip_address = true
  key_name                    = aws_key_pair.terra_key.key_name

  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
      spot_instance_type             = "one-time"
      max_price                      = "0.0040"
    }

  }

  tags = {

    Name = "demo_bastion_host"

  }

}

# resource "aws_instance" "demo_app_ins" {

#   ami           = "ami-0c7632fb77f35db43"
#   instance_type = "t3.micro"

#   subnet_id = aws_subnet.terra_privatesub1.id

#   vpc_security_group_ids = [
#     aws_security_group.demo_app_sg.id
#   ]
#   key_name = aws_key_pair.terra_key.key_name

#   instance_market_options {
#     market_type = "spot"
#     spot_options {
#       instance_interruption_behavior = "terminate"
#       spot_instance_type             = "one-time"
#       max_price                      = "0.0040"
#     }

#   }
#   tags = {

#     Name = "demo_app_server"

#   }

# }

resource "aws_security_group" "demo_rds_sg" {
  name   = "demo-rds-sg"
  vpc_id = aws_vpc.terra_demo_vpc.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"

    security_groups = [
      aws_security_group.demo_bastion_sg.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-rds-sg"
  }
}

resource "aws_db_subnet_group" "demo_db_subnetgrp" {
  name = "demo-db-subnet-group"

  subnet_ids = [
    aws_subnet.terra_privatesub1.id,
    aws_subnet.terra_privatesub2.id
  ]

  tags = {
    Name = "demo-db-subnetgrp"
  }
}

resource "aws_db_instance" "demo-rds-ins" {
  identifier = "demo-postgresql"

  allocated_storage     = 20
  storage_type          = "gp3"
  max_allocated_storage = 0

  engine         = "postgres"
  engine_version = "17.7"

  instance_class = "db.t3.micro"

  db_name  = "app_db"
  username = "Shahadminpsql"
  password = "Argonday120!021"

  vpc_security_group_ids = [
    aws_security_group.demo_rds_sg.id
  ]
  db_subnet_group_name = aws_db_subnet_group.demo_db_subnetgrp.name
  multi_az             = false
  availability_zone    = "ap-south-1c"

  publicly_accessible = false

  skip_final_snapshot = true

  tags = {
    Name = "demo-rds-postgresql"
  }
}