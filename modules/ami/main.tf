terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
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

output "ami_id" {
  value = aws_ami_copy.gpu_ami.id
}