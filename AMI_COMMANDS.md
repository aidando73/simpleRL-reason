
- AMI name: Custom Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.4.1 (Ubuntu 22.04) 20250401
- Based off of: Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.4.1 (Ubuntu 22.04) 20250302
- Docs: https://aws.amazon.com/releasenotes/aws-deep-learning-ami-gpu-pytorch-2-4-ubuntu-22-04/
```bash
./setup-ec2.bash

# One time setup
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

conda init
source ~/.bashrc
conda create --name pytorch_backup --clone pytorch
conda activate pytorch
pip install uv
uv pip install flash-attn==2.5.0 --no-build-isolation

# Testing
nvidia-smi
fi_info -p efa
/opt/amazon/efa/test/efa_test.sh
```