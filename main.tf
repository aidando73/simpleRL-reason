provider "aws" {
  alias  = "east2"
  region = "us-east-2"
}

provider "aws" {
  alias  = "west2"
  region = "us-west-2"
}

module "ami_west_2" {
  source = "./modules/ami"
  providers = {
    aws = aws.west2
  }
}

module "cluster_west_2" {
  source = "./modules/cluster"
  providers = {
    aws = aws.west2
  }
  depends_on = [module.ami_west_2]  # Make sure AMI is ready
  capacity_block = {
    num_instances = 2
    instance_type = "p4d.24xlarge"
    availability_zone = "us-west-2a"
  }
}