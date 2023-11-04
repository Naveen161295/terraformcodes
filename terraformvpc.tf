terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
#VPC entire structure
#1. VPC-ID
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "yono-vpc"
  }
}
#2. Subnets [Pub/Pvt]
resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "pub-subnet"
  }
}
resource "aws_subnet" "pvtsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "pvt-subnet"
  }
}
#3. IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "my-IGW"
  }
}
#4. NAT
resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "gw-NAT"
  }
  depends_on = [aws_eip.eip]
}
#5. RT [Pub/Pvt]
#public-RT
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}
#Private-RT
resource "aws_route_table" "pvtrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "private-rt"
  }
}
#6. RT Associates
#public
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}

#private
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.pvtsub.id
  route_table_id = aws_route_table.pvtrt.id
}
#7. Security Groups [Pub/Pvt]
#Public-SG
resource "aws_security_group" "publicsg" {
  name        = "public-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Public-sg"
  }
}
#privatesg
resource "aws_security_group" "privatesg" {
  name        = "pvt-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "ssh one"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups = [aws_security_group.publicsg.id]
  }
   ingress {
    description      = "HTTPS one"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups = [aws_security_group.publicsg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "privatesg"
  }
}
#8. Web Browser [Pub/Pvt]
resource "aws_instance" "web1" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  key_name = "nvkp" 
  subnet_id = aws_subnet.pubsub.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.publicsg.id]
  root_block_device {
      volume_size = "300"
      volume_type = "gp2"
    }
  tags = {
    Name = "WebServer1"
  }
}
resource "aws_instance" "web2" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  key_name = "nvkp" 
  subnet_id = aws_subnet.pubsub.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.publicsg.id]
  root_block_device {
      volume_size = "300"
      volume_type = "gp2"
    }
  tags = {
    Name = "WebServer2"
  }
}
resource "aws_instance" "app1" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  key_name = "nvkp" 
  subnet_id = aws_subnet.pvtsub.id
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.privatesg.id]
  root_block_device {
      volume_size = "300"
      volume_type = "gp2"
    }
  tags = {
    Name = "AppServer1"
  }
}

