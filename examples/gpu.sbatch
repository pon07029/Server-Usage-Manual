#!/bin/bash
#SBATCH --job-name=gpu-example
#SBATCH --partition=main
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=256M
#SBATCH --gres=gpu:a10:1
#SBATCH --time=00:02:00
#SBATCH --output=gpu-%j.out

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
hostname
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:?GPU allocation missing}"
# This checks visibility only; it does not run a training workload.
srun nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
echo GPU_EXAMPLE_OK
# Activate your own environment before replacing this with training.
