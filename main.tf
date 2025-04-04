terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.94"
    }
  }

  required_version = ">= 1.2.0"
}


provider "aws" {
  alias  = "east2"
  region = "us-east-2"
}

provider "aws" {
  alias  = "west2"
  region = "us-west-2"
}


# module "ami_west_2" {
#   source = "./modules/ami"
#   providers = {
#     aws = aws.west2
#   }
# }

# module "ebs_volume_west_2" {
#   source = "./modules/ebs-volume"
#   providers = {
#     aws = aws.west2
#   }
#   availability_zone = "us-west-2b"
# }

# module "cluster_west_2" {
#   source = "./modules/cluster"
#   providers = {
#     aws = aws.west2
#   }
#   ami_id = module.ami_west_2.ami_id
#   depends_on = [module.ami_west_2]  # Make sure AMI is ready
#   master_volume_id = module.ebs_volume_west_2.master_volume_id
#   worker_volume_id = module.ebs_volume_west_2.worker_volume_id
#   availability_zone = "us-west-2b"
#   instance_type = "gr6.8xlarge"
# #   capacity_block_id = ""
# }

# Define a data source to fetch the existing capacity block by ID
locals {
  # Capacity block information
  capacity_block_id = "cr-07c818ea789cc9905"
  availability_zone = "us-east-2a"
  instance_type = "p4d.24xlarge"
}

module "ami_east_2" {
  source = "./modules/ami"
  providers = {
    aws = aws.east2
  }
}

module "ebs_volume_east_2" {
  source = "./modules/ebs-volume"
  providers = {
    aws = aws.east2
  }
  availability_zone = local.availability_zone
}

# Example usage in a module:
module "cluster_east_2" {
  source = "./modules/cluster"
  providers = {
    aws = aws.east2
  }
  ami_id = module.ami_east_2.ami_id
  depends_on = [module.ami_east_2]
  master_volume_id = module.ebs_volume_east_2.master_volume_id
  worker_volume_id = module.ebs_volume_east_2.worker_volume_id
  availability_zone = local.availability_zone
  instance_type = local.instance_type
  capacity_block_id = local.capacity_block_id
}
