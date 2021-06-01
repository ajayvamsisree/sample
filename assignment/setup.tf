terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.42.0"
    }
  }
}
provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIATFMFECWFJ3NZUOKT"
  secret_key = "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"
}
resource "aws_vpc" "main" {
  cidr_block                       = "172.16.0.0/16"
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  enable_classiclink               = false
  enable_classiclink_dns_support   = false
  assign_generated_ipv6_cidr_block = false
  tags = {
    Name = "main"
  }
}
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.16.0.0/18"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-ap-south-1a"
  }
}
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.16.64.0/18"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "private-ap-south-1a"
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public"
  }
}
resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.main]
}
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
  tags = {
    Name = "NAT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name = "private"
  }
}
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_instance" "jenkins_server" {
  ami           = "ami-010aff33ed5991201"
  instance_type = "t2.micro"
  key_name      = "shellkey"
  subnet_id     = aws_subnet.public_1.id
  user_data     = file("install_jenkins.sh")
  tags = {
    Name = "jenkins_server"
  }
}
resource "aws_instance" "kubernetes" {
  ami           = "ami-010aff33ed5991201"
  instance_type = "t3.small"
  key_name      = "shellkey"
  subnet_id     = aws_subnet.private_1.id
  user_data     = file("install_minikube.sh")
  tags = {
    Name = "kubernetes"
  }
}
