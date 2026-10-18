#!/usr/bin/env bash
# Convert a user-supplied, already-harmonized VCF into the PLINK prefix used
# for downstream relatedness. Sample renaming is intentionally
# outside this generic step.
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
: "${GACU_WGS_VCF:?Set GACU_WGS_VCF to the VCF used for WGS/BRB integration}"
require_brb_file "$GACU_WGS_VCF"; require_brb_command "$PLINK"
prefix="${GACU_EXTERNAL_PLINK_PREFIX:-$GENOTYPE_ROOT/brb_wgs_harmonized}"
mkdir -p "$(dirname "$prefix")"
"$PLINK" --vcf "$GACU_WGS_VCF" --double-id --allow-extra-chr --make-bed --out "$prefix"
echo "Created PLINK files with prefix $prefix"
