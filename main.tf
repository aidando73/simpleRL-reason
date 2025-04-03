terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

locals {
    iam_role_arn = "arn:aws:iam::838892012396:role/TrainingGPUEFA"

    # Create key pair
    key_name = "aws-us-east-2"
    # Copy AMI from us-east-1
    ami = "ami-0fc78879ffe7bb9c9"

    # Buy a capacity block
    capacity_block = {
        num_instances = 2
        instance_type = "p4d.24xlarge"
        availability_zone = "us-east-2a"
    }
}

provider "aws" {
  region  = "us-east-2"
}

# Use the default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group for an EFA cluster
resource "aws_security_group" "efa_cluster_sg" {
  name = "efa-cluster-sg"
  description = "Security group for an EFA cluster"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  # ssh
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # efa
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self = true
  }

  tags = {
    Name = "efa-cluster-sg"
  }
}

# Copy AMI from us-east-1 to us-east-2
resource "aws_ami_copy" "gpu_ami" {
  name                = "Custom Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.4.1 (Ubuntu 22.04) 20250401"
  description         = "Copy from us-east-1"
  source_ami_id       = "ami-06a8b9bbfc400713f"  # Original AMI ID in us-east-1
  source_ami_region   = "us-east-1"

  tags = {
    Name = "copied-gpu-ami"
  }
}

# resource "aws_instance" "app_server" {
#   ami           = "ami-830c94e3"
#   instance_type = "t2.micro"

#   tags = {
#     Name = "ExampleAppServerInstance"
#   }
# }
