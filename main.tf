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

module "ebs_volume_west_2" {
  source = "./modules/ebs-volume"
  providers = {
    aws = aws.west2
  }
  availability_zone = "us-west-2b"
}

module "cluster_west_2" {
  source = "./modules/cluster"
  providers = {
    aws = aws.west2
  }
  ami_id = module.ami_west_2.ami_id
  depends_on = [module.ami_west_2]  # Make sure AMI is ready
  master_volume_id = module.ebs_volume_west_2.master_volume_id
  worker_volume_id = module.ebs_volume_west_2.worker_volume_id
  availability_zone = "us-west-2b"
  instance_type = "gr6.8xlarge"
#   capacity_block_id = ""
}