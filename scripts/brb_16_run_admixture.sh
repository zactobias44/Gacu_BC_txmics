#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
load_brb_modules; mkdir_brb_outputs
: "${GACU_ADMIXTURE_BED_PREFIX:?Set GACU_ADMIXTURE_BED_PREFIX to the harmonized PLINK bed prefix}"
: "${GACU_ADMIXTURE_K:?Set GACU_ADMIXTURE_K, e.g. 2}"
require_brb_command "$ADMIXTURE"
cd "$(dirname "$GACU_ADMIXTURE_BED_PREFIX")"
"$ADMIXTURE" --cv "$GACU_ADMIXTURE_BED_PREFIX.bed" "$GACU_ADMIXTURE_K" | tee "$GENOTYPE_ROOT/admixture_K${GACU_ADMIXTURE_K}.log"
