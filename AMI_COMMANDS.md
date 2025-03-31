
```bash
# AMI is based off of:
# https://aws.amazon.com/releasenotes/aws-deep-learning-ami-gpu-pytorch-2-4-ubuntu-22-04/
# Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.4.1 (Ubuntu 22.04) 20250302

./setup-ec2.bash

# One time setup
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc
sudo apt install -y jq awscli
sudo apt -y install iputils-ping iperf3 iftop
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

conda init
source ~/.bashrc
conda create --name pytorch_backup --clone pytorch
conda activate pytorch
uv pip install flash-attn==2.5.0 --no-build-isolation


# Testing
nvidia-smi
fi_info -p efa
/opt/amazon/efa/test/efa_test.sh
```