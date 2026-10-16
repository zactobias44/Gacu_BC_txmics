#!/usr/bin/env bash
#SBATCH --job-name=brb_frc_shallow
#SBATCH --array=1-4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_frc_shallow_%A_%a.out
set -euo pipefail
if [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR/scripts"
elif [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/../config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
else
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
load_brb_modules; mkdir_brb_outputs
task=${SLURM_ARRAY_TASK_ID:?submit as a four-task array}
read -r _ year tissue r1 r2 whitelist prefix < <(awk -v t="$task" 'NR>1 && $1==t {print}' "$SHALLOW_CONFIG")
wl="$BRB_REPO_ROOT/metadata/barcodes_${whitelist}.txt"
bam="$STAR_OUTPUT_ROOT/${prefix}_shallow_Aligned.sortedByCoord.out.bam"
java -jar "$FAST_READ_COUNTER" --bam "$bam" --gtf "$ONE_FEATURE_GTF" \
    --umi-dedup none --barcodeFile "$wl" -o "$COUNTS_ROOT/${prefix}_shallow_fastreadcounter"
