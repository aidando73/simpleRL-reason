variable "availability_zone" {
  type        = string
  description = "The AZ where the volumes should be created"
}

resource "aws_ebs_volume" "master_volume" {
  availability_zone = var.availability_zone
  size             = 2500
  type             = "gp3"

  tags = {
    Name = "TrainingGPUMasterVolume"
  }
}

resource "aws_ebs_volume" "worker_volume" {
  availability_zone = var.availability_zone
  size             = 2500
  type             = "gp3"

  tags = {
    Name = "TrainingGPUWorkerVolume"
  }
}

# Outputs
output "master_volume_id" {
  value = aws_ebs_volume.master_volume.id
}

output "worker_volume_id" {
  value = aws_ebs_volume.worker_volume.id
}
