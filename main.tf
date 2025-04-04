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
  ami_id = module.ami_west_2.ami_id
  depends_on = [module.ami_west_2]  # Make sure AMI is ready
#   capacity_block_id = ""
}