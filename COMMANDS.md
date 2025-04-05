Assumes Ubuntu 22.04

```bash
./setup-runpod.bash
cd /workspace \
&& git clone https://github.com/aidando73/simpleRL-reason \
&& cd simpleRL-reason \
&& git checkout aidand-v8 \
&& git pull \
&& echo "👉 $(realpath .)"

# Verify CUDA installation
nvidia-smi

# TODO
direnv allow
# Copy .envrc to worker node

conda activate pytorch
pip install uv
uv pip install --no-build-isolation
uv pip install -e .

# launch the master node of ray
tmux
conda activate pytorch
ray start --head \
--node-ip-address 0.0.0.0 \
--num-gpus 8 \
--dashboard-host 0.0.0.0 \
--include-dashboard true


# From master node
tmux attach
bash train_grpo_math_tune_ray.sh \
    --model_name Qwen/Qwen2.5-32B \
    --max_response_length 8192 \
    --train_batch_size 1024 \
    --rollout_n 8 \
    --kl_loss_coef 0.001 \
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

# Ngrok proxy
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
	| sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
	&& echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
	| sudo tee /etc/apt/sources.list.d/ngrok.list \
	&& sudo apt update \
	&& sudo apt install ngrok

# Set credentials
tmux
ngrok http 8265 --url=lasting-swan-large.ngrok-free.app --basic-auth "$NGROK_USERNAME:$NGROK_PASSWORD"

pip install huggingface_hub[cli] -U
huggingface-cli upload aidando73/simplerl-v8-checkpoints global_step_15 global_step_15

huggingface-cli upload aidando73/simplerl-v8-checkpoints .

# Download checkpoint
mkdir -p /workspace/simpleRL-reason/checkpoints/
huggingface-cli download aidando73/simplerl-v4-checkpoints global_step_15 path latest_checkpointed_iteration.txt
# huggingface-cli upload-large-folder --repo-type=model --num-workers=16 aidando73/simplerl-v4-checkpoints .

# If dashboard is down
ray status
ray memory
ray list
ray job list
ray job status 03000000
ray job logs 03000000
```
