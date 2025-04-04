terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

variable "capacity_block" {
    type = object({
        num_instances = number
        instance_type = string
        availability_zone = string
    })
}

locals {
    iam_role_arn = "arn:aws:iam::838892012396:role/TrainingGPUEFA"
}

data "aws_ami" "gpu_ami" {
    most_recent = true
    owners = ["self"]
    name_regex = "Custom Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.4.1 (Ubuntu 22.04) 20250401"
}

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

# resource "aws_instance" "app_server" {
#   ami           = "ami-830c94e3"
#   instance_type = "t2.micro"

#   tags = {
#     Name = "ExampleAppServerInstance"
#   }
# }
