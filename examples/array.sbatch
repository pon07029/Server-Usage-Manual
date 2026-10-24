#!/bin/bash
#SBATCH --job-name=array-example
#SBATCH --partition=main
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=128M
#SBATCH --time=00:02:00
#SBATCH --array=1-3%2
#SBATCH --output=array-%A_%a.out

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
echo "ARRAY_JOB_ID=$SLURM_ARRAY_JOB_ID TASK_ID=$SLURM_ARRAY_TASK_ID"
# Map this index to your own sample/input table for real analyses.
srun /usr/bin/python3 -c 'import os; print("TASK_INDEX=" + os.environ["SLURM_ARRAY_TASK_ID"]); print("ARRAY_EXAMPLE_OK")'
