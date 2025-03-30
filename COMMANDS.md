Assumes Ubuntu 22.04


```bash
# One time setup
cp sample.envrc .envrc
# Go to https://wandb.ai/authorize and fill in the WANDB_API_KEY
source .envrc
direnv allow

# Install CUDA


source ~/miniconda3/bin/activate && conda create -y --prefix ./env python=3.10
source ~/miniconda3/bin/activate && conda activate ./env
pip install uv
uv pip install "torch==2.4.0" --index-url https://download.pytorch.org/whl/cu124
uv pip install flash-attn --no-build-isolation
uv pip install -e .
# uv pip install "torch==2.4.0+cu118" --upgrade --index-url https://download.pytorch.org/whl/cu118
# uv pip install --upgrade "nvidia-nccl-cu12==2.19.3"
# uv pip install --upgrade "nvidia-nccl-cu12==2.26.2"
# uv pip install --upgrade "nvidia-nccl-cu12==2.18.3"
# uv pip install --upgrade --force-reinstall "ray[default]==2.10.0"

# python3 -c "import torch; print(torch.version.cuda)"

# launch the master node of ray
source .envrc
source ~/miniconda3/bin/activate && conda activate ./env
ray start --head \
--node-ip-address $MASTER_NODE_IP \
--num-gpus 8 \
--dashboard-host 0.0.0.0 \
--include-dashboard true

# Worker nodes
source .envrc
source ~/miniconda3/bin/activate && conda activate ./env
ray start --address $MASTER_NODE_IP:6379  --num-gpus 8

# From master node
tmux
source ~/miniconda3/bin/activate && conda activate ./env
source .envrc
bash train_grpo_math_tune_ray.sh \
    --model_name Qwen/Qwen2.5-Math-7B \
    --train_batch_size 1024 \
    --rollout_n 8 \
    --kl_loss_coef 0.0001 \
    --entropy_coeffient 0.001 \
    --rollout_gpu_memory_util 0.5 \
    --rollout_tp 2 \
    --save_freq 5


# Diagnostics
source ~/miniconda3/bin/activate && conda activate ./env
source .envrc
python3 -c "import torch; print(torch.version.cuda)"
python3 -c "import torch; print(torch.cuda.is_available())"
# Check CUDA devices
python3 -c "import torch; print(f'CUDA device count: {torch.cuda.device_count()}')"
python3 -c "import torch; [print(f'CUDA Device {i}: {torch.cuda.get_device_name(i)}') for i in range(torch.cuda.device_count())]"
python3 -c "import torch; print(f'Current CUDA device: {torch.cuda.current_device()}')"

# Check NCCL version
python3 -c "import torch; print(f'NCCL Version: {torch.cuda.nccl.version()}')" 

```


```bash
# EFA setup: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa-start-nccl.html
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get update && sudo apt-get install build-essential -y
sudo apt-get install -y gcc make linux-headers-$(uname -r)
cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF
sudo sed -i 's/GRUB_CMDLINE_LINUX=".*"/GRUB_CMDLINE_LINUX="rdblacklist=nouveau"/' /etc/default/grub
sudo update-grub
sudo reboot

sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu2004/x86_64/7fa2af80.pub \
&& wget -O /tmp/deeplearning.deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu2004/x86_64/nvidia-machine-learning-repo-ubuntu2004_1.0.0-1_amd64.deb \
&& sudo dpkg -i /tmp/deeplearning.deb \
&& wget -O /tmp/cuda.pin https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin \
&& sudo mv /tmp/cuda.pin /etc/apt/preferences.d/cuda-repository-pin-600 \
&& sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub \
&& sudo add-apt-repository 'deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /' \
&& sudo apt update \
&& sudo apt install nvidia-kernel-open-535 \
&& sudo apt install -o Dpkg::Options::='--force-overwrite' cuda-drivers-535 cuda-toolkit-12-3 libcudnn8 libcudnn8-dev -y

sudo reboot

sudo apt install -o Dpkg::Options::='--force-overwrite' nvidia-fabricmanager-535
sudo systemctl start nvidia-fabricmanager && sudo systemctl enable nvidia-fabricmanager

# Add to ~/.bashrc
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

sudo apt -y install build-essential devscripts debhelper check libsubunit-dev fakeroot pkg-config dkms

wget https://github.com/NVIDIA/gdrcopy/archive/refs/tags/v2.4.tar.gz \
&& tar xf v2.4.tar.gz \
&& cd gdrcopy-2.4/packages

CUDA=/usr/local/cuda ./build-deb-packages.sh

sudo dpkg -i gdrdrv-dkms_2.4-1_amd64.*.deb \
&& sudo dpkg -i libgdrapi_2.4-1_amd64.*.deb \
&& sudo dpkg -i gdrcopy-tests_2.4-1_amd64.*.deb \
&& sudo dpkg -i gdrcopy_2.4-1_amd64.*.deb

curl -O https://efa-installer.amazonaws.com/aws-efa-installer-1.38.1.tar.gz

tar -xf aws-efa-installer-1.38.1.tar.gz && cd aws-efa-installer

sudo ./efa_installer.sh -y --mpi=openmpi4

sudo systemctl status nvidia-fabricmanager

fi_info -p efa -t FI_EP_RDM

# Ec2 setup
sudo mkdir /workspace

# Only if EBS volume is new
sudo mkfs -t xfs /dev/nvme1n1
sudo mount /dev/nvme1n1 /workspace
echo '/dev/nvme1n1  /workspace  xfs  defaults,nofail  0  2' | sudo tee -a /etc/fstab
sudo chown ubuntu:ubuntu /workspace

cd /workspace && git clone https://github.com/aidando73/simpleRL-reason && realpath simpleRL-reason

git checkout aidand-v2
```

```bash
# To view ray logs
tail -f /tmp/ray/session_*/logs/*


# Testing bandwidth
sudo apt-get install -y iperf3
# Server
iperf3 -s
# Client
iperf3 -c $MASTER_NODE_IP -t 10

sudo apt install iputils-ping
ping -c 10 $MASTER_NODE_IP

sudo apt install iftop
sudo iftop

cd /workspace && git clone git@github.com:aidando73/nccl-tests.git && cd nccl-tests && git checkout aidand-ec2-tests && realpath .
```

### Notes - 2 A100 nodes on AWS
- p4d.24xlarge - 40GB RAM, SXM
- IP latency: 0.255ms
- Transfer: 1.11 Gbps
- Launch time on both A100 nodes: Sun Mar 30 2025 10:25:12 GMT+1100