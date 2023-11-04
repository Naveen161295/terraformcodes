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
  region = "ap-south-1"
}
resource "aws_instance" "web" {
  ami           = "ami-0287a05f0ef0e9d9a"
  instance_type = "t2.micro"
  key_name = "mumbaiKP" 
  root_block_device {
      volume_size = "300"
      volume_type = "gp2"
    }
  tags = {
    Name = "WebServer"
  }
}
