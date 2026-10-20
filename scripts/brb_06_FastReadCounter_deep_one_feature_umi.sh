#!/usr/bin/env bash
# FastReadCounter UMI-deduplicated counts for the deep one-feature BAMs.
# Submit as a four-task array after brb_05_run_STAR_deep_one_feature.sh.
# Output: outputs/matrix/<prefix>_deep_1f_umi_fastreadcounter/
#
#SBATCH --job-name=brb_frc_deep_1f_umi
#SBATCH --array=1-4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=2-00:00:00
#SBATCH --qos=unlim
#SBATCH --output=../logs/brb_frc_deep_1f_umi_%A_%a.out
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
read -r _ year tissue r1s r2s barcode_map prefix < <(awk -v t="$task" 'NR>1 && $1==t {print}' "$DEEP_CONFIG")
wl="$(barcode_whitelist_from_map "$barcode_map")"
bam="$STAR_OUTPUT_ROOT/${prefix}_deep_1f_Aligned.sortedByCoord.out.bam"
java -jar "$FAST_READ_COUNTER" --bam "$bam" --gtf "$ONE_FEATURE_GTF" \
    --umi-dedup 1MM_Directional --barcodeFile "$wl" \
    -o "$COUNTS_ROOT/${prefix}_deep_1f_umi_fastreadcounter"
