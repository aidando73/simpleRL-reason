Assumes Ubuntu 22.04

```bash
# Verify CUDA installation
nvidia-smi

# Test EFA
fi_info -p efa
/opt/amazon/efa/test/efa_test.sh

aws configure set default.region us-east-1 

./attach-ebs.bash

# Test NCCL
# Get IP on master node
aws_metadata_token=`curl --silent -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
echo "export MASTER_NODE_IP=$(curl --silent -H "X-aws-ec2-metadata-token: $aws_metadata_token" http://169.254.169.254/latest/meta-data/local-ipv4)" >> .envrc
# Get IP on worker node
aws_metadata_token=`curl --silent -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
echo "Copy this to .envrc on master node:"
echo "export WORKER_NODE_IP=$(curl --silent -H "X-aws-ec2-metadata-token: $aws_metadata_token" http://169.254.169.254/latest/meta-data/local-ipv4)"
direnv allow

# Test ssh connections
# From master to worker
ssh $WORKER_NODE_IP
# From worker to master
ssh $MASTER_NODE_IP
# Then run actual nccl test
export NCCL_DEBUG=INFO
export FI_EFA_USE_DEVICE_RDMA=1
/opt/amazon/openmpi/bin/mpirun \
-x NCCL_DEBUG=INFO \
-x FI_EFA_USE_DEVICE_RDMA=1 \
--verbose \
-host $MASTER_NODE_IP,$WORKER_NODE_IP \
/usr/local/cuda-12.4/efa/test-cuda-12.4/all_reduce_perf \
-b 8 \
-e 256M \
-f 2 \
-g 8


# Run on master
: > .envrc
echo "export WANDB_API_KEY=$(aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:us-east-1:838892012396:secret:wandb_api_key-rg9keb --query SecretString --output text | jq -r '.WANDB_API_KEY')" >> .envrc

aws_metadata_token=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
echo "export MASTER_NODE_IP=$(curl -H "X-aws-ec2-metadata-token: $aws_metadata_token" http://169.254.169.254/latest/meta-data/local-ipv4)" >> .envrc

direnv allow
# Copy .envrc to worker node

conda activate pytorch
pip install uv
uv pip install flash-attn==2.5.0 --no-build-isolation
uv pip install --overrides overrides.txt -e .

# launch the master node of ray
tmux
conda activate pytorch
ray start --head \
--node-ip-address $MASTER_NODE_IP \
--num-gpus 8 \
--dashboard-host 0.0.0.0 \
--include-dashboard true

# Worker nodes
tmux
conda activate pytorch
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

# Testing bandwidth
sudo apt-get install -y iperf3
# Server
iperf3 -s
# Client
iperf3 -c $MASTER_NODE_IP -t 10

ping -c 10 $MASTER_NODE_IP

```

EFA - baseline
NCCL tests: 1MB: 1.17, 256MB: 6.40, 1GB: 7.46, 16GB: 9.28 (GB/s)

EFA - w/ Placement group
NCCL tests:

EFA - w/ Placement group + RDMA
NCCL tests: 