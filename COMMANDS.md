Assumes Ubuntu 22.04


```bash
# Test EFA
fi_info

# One time setup
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc
sudo apt install -y jq awscli
sudo apt -y install iputils-ping iperf3 iftop

sudo reboot

# Verify CUDA installation
nvidia-smi
nvcc --version

aws configure set default.region us-east-1 

# Existing EBS volume
aws_metadata_token=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
availability_zone=`curl -H "X-aws-ec2-metadata-token: $aws_metadata_token" http://169.254.169.254/latest/meta-data/placement/availability-zone`
aws ec2 describe-volumes --filters Name=availability-zone,Values=$availability_zone Name=status,Values=available --query "Volumes[*].{ID:VolumeId,Name:Tags[?Key=='Name'].Value|[0],Size:Size,Type:VolumeType,State:State,AZ:AvailabilityZone}" --output table

# Fill in volume_id
volume_id=vol-0fabd6fcbb723fde3
instance_id=`curl -H "X-aws-ec2-metadata-token: $aws_metadata_token" http://169.254.169.254/latest/meta-data/instance-id`
aws ec2 attach-volume \
    --volume-id $volume_id \
    --instance-id $instance_id \
    --device /dev/sdf
aws ec2 wait volume-in-use --volume-ids $volume_id
aws ec2 describe-volumes --volume-ids $volume_id --query "Volumes[0].Attachments" --output table

# Existing EBS volume
lsblk
DEVICE_ID=nvme9n1
sudo mkdir -p /workspace
sudo mount /dev/$DEVICE_ID /workspace
echo "/dev/$DEVICE_ID  /workspace  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
sudo chown ubuntu:ubuntu /workspace

# New EBS volume
lsblk
DEVICE_ID=nvme9n1
sudo mkdir -p /workspace
sudo mkfs -t xfs /dev/$DEVICE_ID #!!! Will destroy existing data on volume
sudo mount /dev/$DEVICE_ID /workspace
echo "/dev/$DEVICE_ID  /workspace  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
sudo chown ubuntu:ubuntu /workspace
cd /workspace \
&& git clone https://github.com/aidando73/simpleRL-reason \
&& cd simpleRL-reason \
&& git checkout aidand-v2 \
&& echo "👉 $(realpath .)"

# Run on master
: > .envrc
echo "export WANDB_API_KEY=$(aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:us-east-1:838892012396:secret:wandb_api_key-rg9keb --query SecretString --output text | jq -r '.WANDB_API_KEY')" >> .envrc

aws_metadata_token=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
echo "export MASTER_NODE_IP=$(curl -H "X-aws-ec2-metadata-token: $aws_metadata_token" http://169.254.169.254/latest/meta-data/local-ipv4)" >> .envrc

direnv allow
# Copy .envrc to worker node


source ~/miniconda3/bin/activate && conda create -y --prefix ./env python=3.10
source ~/miniconda3/bin/activate && conda activate ./env
pip install uv
TORCH_CUDA_DSA=1 uv pip install "torch==2.4.0" --force-reinstall --index-url https://download.pytorch.org/whl/cu124
uv pip install flash-attn --no-build-isolation
uv pip install -e .

# launch the master node of ray
tmux
source ~/miniconda3/bin/activate && conda activate ./env
ray start --head \
--node-ip-address $MASTER_NODE_IP \
--num-gpus 8 \
--dashboard-host 0.0.0.0 \
--include-dashboard true

# Worker nodes
tmux
source ~/miniconda3/bin/activate && conda activate ./env
ray start --address $MASTER_NODE_IP:6379  --num-gpus 8

# From master node
tmux attach
bash train_grpo_math_tune_ray.sh \
    --model_name Qwen/Qwen2.5-Math-7B \
    --train_batch_size 1024 \
    --rollout_n 8 \
    --kl_loss_coef 0.0001 \
    --entropy_coeffient 0.001 \
    --rollout_gpu_memory_util 0.75 \
    --rollout_tp 2 \
    --save_freq 5


# Diagnostics
source ~/miniconda3/bin/activate && conda activate ./env
source .envrc

 python -m "torch.utils.collect_env"
# Check PyTorch version
python3 -c "import torch; print(f'PyTorch version: {torch.__version__}')"

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