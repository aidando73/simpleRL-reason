#! /bin/bash

aws_metadata_token=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
availability_zone=`curl -H "X-aws-ec2-metadata-token: $aws_metadata_token" http://169.254.169.254/latest/meta-data/placement/availability-zone`
aws ec2 describe-volumes --filters Name=availability-zone,Values=$availability_zone Name=status,Values=available --query "Volumes[*].{ID:VolumeId,Name:Tags[?Key=='Name'].Value|[0],Size:Size,Type:VolumeType,State:State,AZ:AvailabilityZone}" --output table

# Prompt user for volume ID
echo "Enter the volume ID to attach (e.g., vol-0123456789abcdef0): "
read volume_id

instance_id=`curl -H "X-aws-ec2-metadata-token: $aws_metadata_token" http://169.254.169.254/latest/meta-data/instance-id`
aws ec2 attach-volume \
    --volume-id $volume_id \
    --instance-id $instance_id \
    --device /dev/sdf
aws ec2 wait volume-in-use --volume-ids $volume_id
aws ec2 describe-volumes --volume-ids $volume_id --query "Volumes[0].Attachments" --output table

