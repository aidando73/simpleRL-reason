Assumes Ubuntu 22.04

```bash
token=$(curl --silent -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
region=$(curl -H "X-aws-ec2-metadata-token: $token" -s http://169.254.169.254/latest/meta-data/placement/region)
aws configure set default.region $region

./attach-device.bash
# Or
./setup-ebs.bash

git checkout aidand-v6 && git pull

# Verify CUDA installation
nvidia-smi

# Test EFA
fi_info -p efa
/opt/amazon/efa/test/efa_test.sh

# Test NCCL
# Fetch ips
# On master
sed -i '/export MASTER_NODE_IP=/d' .envrc
sed -i '/export WORKER_NODE_IP=/d' .envrc
echo "export MASTER_NODE_IP=$(./fetch-ip.bash)" >> .envrc
# On worker
echo "Copy this to .envrc on worker node:"
echo "export WORKER_NODE_IP=$(./fetch-ip.bash)"
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
-e 1M \
-f 2 \
-g 8


# Run on master
echo "export WANDB_API_KEY=$(aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:$region:838892012396:secret:wandb_api_key-rg9keb --query SecretString --output text | jq -r '.WANDB_API_KEY')" >> .envrc

echo "export MASTER_NODE_IP=$(./fetch-ip.bash)" >> .envrc

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

conda activate pytorch
# sudo apt install -y python3-pip && pip install -U "huggingface_hub[cli]" && export PATH="/home/ubuntu/.local/bin:$PATH"
huggingface-cli login --token $(aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:us-east-1:838892012396:secret:hf_token-zZPDUq --query SecretString --output text | jq -r '.HF_TOKEN')
huggingface-cli upload aidando73/simplerl-v4-checkpoints global_step_15 global_step_15

# Download checkpoint
mkdir -p /workspace/simpleRL-reason/checkpoints/3_Qwen_Qwen2.5-Math-7B_batch1024_rollout8_klcoef0.0001_entcoef0.001_simplelr_math_35
huggingface-cli download aidando73/simplerl-v4-checkpoints global_step_15 path latest_checkpointed_iteration.txt
# huggingface-cli upload-large-folder --repo-type=model --num-workers=16 aidando73/simplerl-v4-checkpoints .

# If dashboard is down
ray status
ray memory
ray list
ray job list
ray job status 03000000
ray job logs 03000000

# New EBS volume
./setup-ebs.bash


# Testing bandwidth
sudo apt-get install -y iperf3
# Server
iperf3 -s
# Client
iperf3 -c $MASTER_NODE_IP -t 10

ping -c 10 $MASTER_NODE_IP

```


```bash
# Infra:
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

terraform init
terraform plan
terraform apply
```

EFA tests (GB/s):
- 1MB: 0.38
- 256MB: 4.48
- 1GB: 5.6
