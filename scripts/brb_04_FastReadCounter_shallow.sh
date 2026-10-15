#!/usr/bin/env bash
#SBATCH --job-name=brb_frc_shallow
#SBATCH --array=1-4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=12:00:00
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
load_brb_modules; mkdir_brb_outputs
task=${SLURM_ARRAY_TASK_ID:?submit as a four-task array}
read -r _ year tissue r1 r2 whitelist prefix < <(awk -v t="$task" 'NR>1 && $1==t {print}' "$SHALLOW_CONFIG")
wl="$BRB_REPO_ROOT/metadata/barcodes_${whitelist}.txt"
java -jar "$FAST_READ_COUNTER" --input-r1 "$(resolve_read_path "$r1")" \
    --input-r2 "$(resolve_read_path "$r2")" --barcodes "$wl" \
    --output "$COUNTS_ROOT/${prefix}_shallow_fastreadcounter" --umi-dedup none
