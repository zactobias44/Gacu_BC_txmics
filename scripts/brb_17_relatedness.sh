#!/usr/bin/env bash
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
: "${GACU_RELATEDNESS_BED_PREFIX:?Set GACU_RELATEDNESS_BED_PREFIX to the harmonized PLINK bed prefix}"
require_brb_command "$PLINK"
"$PLINK" --bfile "$GACU_RELATEDNESS_BED_PREFIX" --genome full --out "$GENOTYPE_ROOT/brb_wgs_relatedness"
