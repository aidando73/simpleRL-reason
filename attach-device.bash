lsblk -d | grep disk
echo "Please enter in the device name e.g., nvme9n1: "
read device_name
sudo mkdir -p /workspace
sudo mount /dev/$device_name /workspace
echo "/dev/$device_name  /workspace  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
sudo chown ubuntu:ubuntu /workspace

echo "EBS volume mounted at /workspace"

ls -l /workspace