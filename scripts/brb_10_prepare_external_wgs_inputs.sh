#!/usr/bin/env bash
# Extract all DJR WGS samples for one chromosome and apply stable _D IDs.
#SBATCH --job-name=brb_wgs_subset
#SBATCH --array=1-21
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --time=12:00:00
# Submit this script from the scripts directory, like the other pipeline jobs.
#SBATCH --output=../logs/brb_wgs_subset_%A_%a.out
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
require_brb_command "$BCFTOOLS"
require_brb_file "$SAMPLE_SOURCE_MAP"
require_brb_file "$WGS_CHR_MAP"
task=${SLURM_ARRAY_TASK_ID:?submit as a 21-task array}
read -r _ _ roman < <(awk -v t="$task" 'NR>1 && $1==t {print}' "$CHR_CONFIG")
[[ -n "${roman:-}" ]] || { echo "No chromosome task $task" >&2; exit 2; }
input="$GACU_WGS_VCF_DIR/$(printf "$GACU_WGS_VCF_PATTERN" "$roman")"
require_brb_file "$input"
samples="$WGS_SUBSET_ROOT/wgs_djr_samples_${roman}.txt"
rename="$WGS_SUBSET_ROOT/wgs_djr_reheader_${roman}.tsv"
awk -F '\t' 'NR>1 && $3=="WGS" {print $2}' "$SAMPLE_SOURCE_MAP" | sort -u > "$samples"
awk -F '\t' 'NR>1 && $3=="WGS" {print $2"\t"$1}' "$SAMPLE_SOURCE_MAP" | sort -u > "$rename"
rename_names="$WGS_SUBSET_ROOT/wgs_djr_reheader_${roman}.names"
selected="$WGS_SUBSET_ROOT/.wgs_djr_${roman}.${SLURM_JOB_ID:-manual}.selected.bcf"
renamed="$WGS_SUBSET_ROOT/.wgs_djr_${roman}.${SLURM_JOB_ID:-manual}.renamed.bcf"
out="$WGS_SUBSET_ROOT/wgs_djr_${roman}.vcf.gz"
out_tmp="$out.${SLURM_JOB_ID:-manual}.tmp"
trap 'rm -f "$samples" "$rename" "$rename_names" "$selected" "$renamed" "$out_tmp" "$out_tmp.csi"' EXIT

# Materialize the selected samples because the HPC bcftools reheader version
# does not accept the streamed BCF produced by `bcftools view -Ou`.
"$BCFTOOLS" view -S "$samples" -Ob -o "$selected" "$input"
"$BCFTOOLS" query -l "$selected" | \
    awk -F '\t' 'NR==FNR {new[$1]=$2; next} ($1 in new) {print new[$1]}' "$rename" - > "$rename_names"
[[ "$(wc -l < "$rename_names")" -eq "$(wc -l < "$samples")" ]] || {
    echo "WGS sample rename list does not match selected VCF samples for $roman" >&2
    exit 1
}

"$BCFTOOLS" reheader -s "$rename_names" -o "$renamed" "$selected"
"$BCFTOOLS" annotate --rename-chrs "$WGS_CHR_MAP" -Oz -o "$out_tmp" "$renamed"
"$BCFTOOLS" index -f "$out_tmp"
mv "$out_tmp" "$out"
mv "$out_tmp.csi" "$out.csi"
