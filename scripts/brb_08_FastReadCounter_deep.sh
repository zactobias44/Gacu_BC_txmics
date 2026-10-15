#!/usr/bin/env bash
#SBATCH --job-name=brb_frc_deep
#SBATCH --array=1-4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=2-00:00:00
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
load_brb_modules; mkdir_brb_outputs
task=${SLURM_ARRAY_TASK_ID:?submit as a four-task array}
read -r _ year tissue r1s r2s whitelist prefix < <(awk -v t="$task" 'NR>1 && $1==t {print}' "$DEEP_CONFIG")
wl="$BRB_REPO_ROOT/metadata/barcodes_${whitelist}.txt"; work="$STAR_WORK_ROOT/${prefix}_deep"
java -jar "$FAST_READ_COUNTER" --input-r1 "$work/R1.fastq.gz" --input-r2 "$work/R2.fastq.gz" \
    --barcodes "$wl" --output "$COUNTS_ROOT/${prefix}_deep_fastreadcounter" --umi-dedup none
