#!/usr/bin/env bash
#SBATCH --job-name=brb_concat_vcfs
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_concat_vcfs_%j.out
set -euo pipefail
if [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR/scripts"
elif [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/../config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
else
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
load_brb_modules; mkdir_brb_outputs; require_brb_command "$BCFTOOLS"
for tissue in gill liver; do
    mapfile -t vcfs < <(for c in $(awk 'NR>1 {print $3}' "$CHR_CONFIG"); do printf '%s\n' "$VARIANT_ROOT/brbseq_${tissue}_${c}.vcf.gz"; done)
    for f in "${vcfs[@]}"; do require_brb_file "$f"; require_brb_file "$f.csi"; done
    "$BCFTOOLS" concat -Oz -o "$VARIANT_ROOT/brbseq_${tissue}_all_chromosomes.vcf.gz" "${vcfs[@]}"
    "$BCFTOOLS" index -f "$VARIANT_ROOT/brbseq_${tissue}_all_chromosomes.vcf.gz"
done
