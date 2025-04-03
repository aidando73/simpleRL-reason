Assumes Ubuntu 22.04

```bash
echo "export TZ=Australia/Sydney" >> ~/.bashrc
source ~/.bashrc

cd /workspace && git clone git@github.com:aidando73/simpleRL-reason.git && cd simpleRL-reason && git checkout aidand-v5 && git pull && realpath .

# Verify CUDA installation
nvidia-smi

# Run on master
cat ~/.runpod_credentials >> .envrc

direnv allow
# Copy .envrc to worker node

source ~/miniconda3/bin/activate && conda create --prefix ./env python=3.10
source ~/miniconda3/bin/activate && conda activate ./env
pip install uv
uv pip install "torch==2.4.0" --index-url https://download.pytorch.org/whl/cu124
# uv pip install flash-attn==2.5.0 --no-build-isolation
uv pip install flash-attn --no-build-isolation
uv pip install -e .

tmux
source ~/miniconda3/bin/activate && conda activate ./env
ray start --head \
--node-ip-address 127.0.0.1 \
--num-gpus 8 \
--dashboard-host 0.0.0.0 \
--include-dashboard true

bash train_grpo_math_tune_ray.sh \
    --model_name Qwen/Qwen2.5-Math-7B \
    --train_batch_size 1024 \
    --rollout_n 8 \
    --kl_loss_coef 0.0001 \
    --entropy_coeffient 0.001 \
    --rollout_gpu_memory_util 0.75 \
    --rollout_tp 2 \
    --save_freq 5

# Ngrok proxy
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
	| tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
	&& echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
	| tee /etc/apt/sources.list.d/ngrok.list \
	&& apt update \
	&& apt install ngrok

ngrok config add-authtoken __auth_token__

tmux
ngrok http 8265 --url=lasting-swan-large.ngrok-free.app --basic-auth "$NGROK_USERNAME:$NGROK_PASSWORD"

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

source ~/miniconda3/bin/activate && conda activate ./env
# sudo apt install -y python3-pip && pip install -U "huggingface_hub[cli]" && export PATH="/home/ubuntu/.local/bin:$PATH"
huggingface-cli login --token $HF_TOKEN
realpath . > path.txt && huggingface-cli upload aidando73/simplerl-v5-checkpoints path.txt
huggingface-cli upload aidando73/simplerl-v5-checkpoints latest_checkpointed_iteration.txt
tmux
source ~/miniconda3/bin/activate && conda activate ../../env
huggingface-cli upload aidando73/simplerl-v5-checkpoints global_step_35 global_step_35

cd logs && huggingface-cli upload aidando73/simplerl-v5-checkpoints .

# Download checkpoint
mkdir -p /workspace/simpleRL-reason/checkpoints/3_Qwen_Qwen2.5-Math-7B_batch1024_rollout8_klcoef0.0001_entcoef0.001_simplelr_math_35
huggingface-cli download aidando73/simplerl-v5-checkpoints global_step_15 path latest_checkpointed_iteration.txt
# huggingface-cli upload-large-folder --repo-type=model --num-workers=16 aidando73/simplerl-v4-checkpoints .

# If dashboard is down
ray status
ray memory
ray list
ray job list
ray job status 03000000
ray job logs 03000000

```

