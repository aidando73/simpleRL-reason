terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# variable "capacity_block_id" {
#     type = string
#     description = "The ID of the capacity block to use"
# }

locals {
  # iam_role_arn = "arn:aws:iam::838892012396:role/TrainingGPUEFA"
  iam_role_name = "TrainingGPUEFA"
}

variable "ami_id" {
  type = string
  description = "The ID of the AMI to use"
}

# data "aws_ec2_capacity_reservation" "capacity_block" {
#     id = var.capacity_block_id
# }

# Use the default VPC
data "aws_vpc" "default" {
  default = true
}

# Generate a new key pair
resource "aws_key_pair" "key_pair" {
  key_name   = "aws"
  public_key = file("~/.ssh/personal_id_ed25519.pub")
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

resource "aws_instance" "gpu_instance_master" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  key_name = aws_key_pair.key_pair.key_name

  vpc_security_group_ids = [aws_security_group.efa_cluster_sg.id]

  iam_instance_profile = local.iam_role_name

  tags = {
    Name = "TrainingGPUMaster"
  }
}


resource "aws_instance" "gpu_instance_worker" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  key_name = aws_key_pair.key_pair.key_name

  vpc_security_group_ids = [aws_security_group.efa_cluster_sg.id]

  iam_instance_profile = local.iam_role_name

  tags = {
    Name = "TrainingGPUWorker"
  }
}