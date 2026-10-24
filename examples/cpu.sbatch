#!/bin/bash
#SBATCH --job-name=cpu-example
#SBATCH --partition=main
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=256M
#SBATCH --time=00:02:00
#SBATCH --output=cpu-%j.out

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export OPENBLAS_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export MKL_NUM_THREADS="$SLURM_CPUS_PER_TASK"

hostname
echo "JOB_ID=$SLURM_JOB_ID CPUS=$SLURM_CPUS_PER_TASK"
# Replace this small check with your analysis command/environment.
srun /usr/bin/python3 -c 'import os; print("OMP_NUM_THREADS=" + os.environ["OMP_NUM_THREADS"]); print("CPU_EXAMPLE_OK")'
