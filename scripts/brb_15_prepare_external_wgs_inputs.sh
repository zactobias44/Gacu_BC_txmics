#!/usr/bin/env bash
# Extract all DJR WGS samples for one chromosome and apply stable _D IDs.
#SBATCH --job-name=brb_wgs_subset
#SBATCH --array=1-21
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --time=12:00:00
# Submit this script from the repository root so logs land in ./logs.
#SBATCH --output=logs/brb_wgs_subset_%A_%a.out
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
require_brb_command "$BCFTOOLS"; require_brb_file "$SAMPLE_SOURCE_MAP"
task=${SLURM_ARRAY_TASK_ID:?submit as a 21-task array}
read -r _ _ roman < <(awk -v t="$task" 'NR>1 && $1==t {print}' "$CHR_CONFIG")
[[ -n "${roman:-}" ]] || { echo "No chromosome task $task" >&2; exit 2; }
input="$GACU_WGS_VCF_DIR/$(printf "$GACU_WGS_VCF_PATTERN" "$roman")"
require_brb_file "$input"
samples="$WGS_SUBSET_ROOT/wgs_djr_samples.txt"
rename="$WGS_SUBSET_ROOT/wgs_djr_reheader.tsv"
awk -F '\t' 'NR>1 && $3=="WGS" {print $2}' "$SAMPLE_SOURCE_MAP" | sort -u > "$samples"
awk -F '\t' 'NR>1 && $3=="WGS" {print $2"\t"$1}' "$SAMPLE_SOURCE_MAP" | sort -u > "$rename"
chr_map="$WGS_SUBSET_ROOT/wgs_chr_rename.tsv"
printf 'chr%s\t%s\n' "$roman" "$roman" > "$chr_map"
out="$WGS_SUBSET_ROOT/wgs_djr_${roman}.vcf.gz"
"$BCFTOOLS" view -S "$samples" -Ou "$input" | \
    "$BCFTOOLS" reheader -s "$rename" | \
    "$BCFTOOLS" annotate --rename-chrs "$chr_map" -Oz -o "$out"
"$BCFTOOLS" index -f "$out"
