resource "aws_vpc" "demo_eks_vpc" {

  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {

    Name = "demo_eks_vpc"

  }

}

resource "aws_subnet" "demo_eks_publicsub1" {

  vpc_id                  = aws_vpc.demo_eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {

    Name = "demo_eks_public_subnet1"

  }

}



resource "aws_subnet" "demo_eks_privatesub1" {

  vpc_id            = aws_vpc.demo_eks_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-south-1a"
  tags = {

    Name = "demo_eks_private_subnet1"

  }
}


resource "aws_subnet" "demo_eks_publicsub2" {

  vpc_id                  = aws_vpc.demo_eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {

    Name = "demo_eks_public_subnet2"

  }

}



resource "aws_subnet" "demo_eks_privatesub2" {

  vpc_id            = aws_vpc.demo_eks_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-south-1b"
  tags = {

    Name = "demo_eks_private_subnet2"

  }

}

resource "aws_subnet" "demo_eks_publicsub3" {

  vpc_id                  = aws_vpc.demo_eks_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-south-1c"
  map_public_ip_on_launch = true
  tags = {

    Name = "demo_eks_public_subnet3"

  }

}



resource "aws_subnet" "demo_eks_privatesub3" {

  vpc_id            = aws_vpc.demo_eks_vpc.id
  cidr_block        = "10.0.13.0/24"
  availability_zone = "ap-south-1c"
  tags = {

    Name = "demo_eks_private_subnet3"

  }

}

resource "aws_internet_gateway" "demo_eks_igtw" {
  vpc_id = aws_vpc.demo_eks_vpc.id

  tags = {
    Name = "demo_eks_igtw"
  }
}

resource "aws_route_table" "demo_eks_public_rt" {
  vpc_id = aws_vpc.demo_eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_eks_igtw.id
  }

  tags = {
    Name = "demo_eks_public_rt"
  }
}

resource "aws_route_table" "demo_eks_private_rt" {
  vpc_id = aws_vpc.demo_eks_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo_eks-natgtw.id
  }
  
  tags = {
    Name = "demo_eks_private_rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.demo_eks_publicsub1.id
  route_table_id = aws_route_table.demo_eks_public_rt.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.demo_eks_publicsub2.id
  route_table_id = aws_route_table.demo_eks_public_rt.id
}
resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.demo_eks_publicsub3.id
  route_table_id = aws_route_table.demo_eks_public_rt.id
}
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.demo_eks_privatesub1.id
  route_table_id = aws_route_table.demo_eks_private_rt.id
}
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.demo_eks_privatesub2.id
  route_table_id = aws_route_table.demo_eks_private_rt.id
}
resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.demo_eks_privatesub3.id
  route_table_id = aws_route_table.demo_eks_private_rt.id
}

resource "aws_eip" "demo_nat_eip" {

  domain = "vpc"

  tags = {

    Name = "demo-nat-eip"


  }

}

resource "aws_nat_gateway" "demo_eks-natgtw" {

  allocation_id = aws_eip.demo_nat_eip.id

  subnet_id = aws_subnet.demo_eks_publicsub1.id

  tags = {


    Name = "demo-eks-nat-gtw"
  }

  depends_on = [

    aws_internet_gateway.demo_eks_igtw


  ]

}