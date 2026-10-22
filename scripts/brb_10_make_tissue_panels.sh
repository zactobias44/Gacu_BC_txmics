#!/usr/bin/env bash
# Intersect one WGS chromosome with one tissue's BRB VCF and merge shared sites.
#SBATCH --job-name=brb_qc_panel
#SBATCH --array=1-42
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_qc_panel_%A_%a.out
set -euo pipefail
if [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/../config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
elif [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR/scripts"
else
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
source "$REPO_ROOT/config/brb_pipeline_config.sh"
load_brb_modules; mkdir_brb_outputs
require_brb_command "$BCFTOOLS"; require_brb_file "$SAMPLE_SOURCE_MAP"
task=${SLURM_ARRAY_TASK_ID:?submit as a 42-task array}
if (( task <= 21 )); then tissue=gill; chr_task=$task; else tissue=liver; chr_task=$((task-21)); fi
read -r _ _ roman < <(awk -v t="$chr_task" 'NR>1 && $1==t {print}' "$CHR_CONFIG")
[[ -n "${roman:-}" ]] || { echo "No chromosome task $chr_task" >&2; exit 2; }
wgs="$WGS_SUBSET_ROOT/wgs_djr_${roman}.vcf.gz"
brb="$VARIANT_ROOT/brbseq_${tissue}_${roman}.vcf.gz"
require_brb_file "$wgs"; require_brb_file "$brb"
brb_samples="$RELATEDNESS_ROOT/${tissue}_brb_samples.txt"
brb_rename="$RELATEDNESS_ROOT/${tissue}_brb_reheader.tsv"
awk -F '\t' -v t="$tissue" 'NR>1 && $3=="BRB" && $4==t {print $2}' "$SAMPLE_SOURCE_MAP" | sort -u > "$brb_samples"
awk -F '\t' -v t="$tissue" 'NR>1 && $3=="BRB" && $4==t {print $2"\t"$1}' "$SAMPLE_SOURCE_MAP" | sort -u > "$brb_rename"
wgs_samples="$WGS_SUBSET_ROOT/wgs_djr_samples.txt"
tmp=$(mktemp -d "$RELATEDNESS_ROOT/${tissue}_${roman}.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
wgs_common="$tmp/wgs.vcf.gz"; brb_common="$tmp/brb.vcf.gz"
"$BCFTOOLS" isec -n=2 -w1 "$wgs" "$brb" -Ou | "$BCFTOOLS" view -S "$wgs_samples" -Oz -o "$wgs_common"
"$BCFTOOLS" isec -n=2 -w2 "$wgs" "$brb" -Ou | "$BCFTOOLS" view -S "$brb_samples" -Ou | "$BCFTOOLS" reheader -s "$brb_rename" | "$BCFTOOLS" view -Oz -o "$brb_common"
"$BCFTOOLS" index -f "$wgs_common"; "$BCFTOOLS" index -f "$brb_common"
out="$RELATEDNESS_ROOT/${tissue}_${roman}.vcf.gz"
"$BCFTOOLS" merge -Oz --force-samples -o "$out" "$wgs_common" "$brb_common"
"$BCFTOOLS" index -f "$out"
