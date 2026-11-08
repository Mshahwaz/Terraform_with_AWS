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

  vpc_id               = aws_vpc.terra_demo_vpc.id
  cidr_block           = "10.0.120.0/25"
  availability_zone    = "ap-south-1b"
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

  vpc_id               = aws_vpc.terra_demo_vpc.id
  cidr_block           = "10.0.121.0/25"
  availability_zone    = "ap-south-1c"
  tags = {

    Name = "demo_private_subnet"

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

# resource "aws_route_table" "demo_vpc_private_route" {
#   vpc_id = aws_vpc.terra_demo_vpc.id

#   route {

#     cidr_block = "0.0.0.0/0"

#     nat_gateway_id = aws_nat_gateway.demo_natgtw.id

#   }

#   tags = {
#     Name = "demo_private_route_table"
#   }
# }

# resource "aws_route_table_association" "private1" {

#   subnet_id      = aws_subnet.terra_privatesub1.id
#   route_table_id = aws_route_table.demo_vpc_private_route.id

# }

# resource "aws_route_table_association" "private2" {

#   subnet_id      = aws_subnet.terra_privatesub2.id
#   route_table_id = aws_route_table.demo_vpc_private_route.id

# }


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

resource "aws_security_group" "demo_app_sg" {

  name = "demo-app-sg"

  vpc_id = aws_vpc.terra_demo_vpc.id

  ingress {

    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.demo_bastion_sg.id]

  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = "demo-app-ssh-sg"

  }

}



resource "aws_instance" "demo_bastion_ins" {

  ami           = "ami-0c7632fb77f35db43"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.terra_publicsub1.id

  vpc_security_group_ids = [
    aws_security_group.demo_bastion_sg.id
  ]

  associate_public_ip_address = true
  key_name                    = "test_off_infy.key.pub"
  tags = {

    Name = "demo_bastion_host"

  }

}

# resource "aws_instance" "demo_app_ins" {

#   ami           = "ami-0c7632fb77f35db43"
#   instance_type = "t3.micro"

#   subnet_id = aws_subnet.terra_privatesub1.id
#   key_name  = "test_off_infy.key.pub"
#   vpc_security_group_ids = [
#     aws_security_group.demo_app_sg.id
#   ]

#   tags = {

#     Name = "demo_app_server"

#   }

# }
