#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
mkdir_brb_outputs
: "${GACU_WGS_VCF:?Set GACU_WGS_VCF to the WGS VCF before running this step}"
require_brb_file "$GACU_WGS_VCF"
if [[ -n "${GACU_WGS_SAMPLE_MAP:-}" ]]; then require_brb_file "$GACU_WGS_SAMPLE_MAP"; fi
if [[ -n "${GACU_BRB_SAMPLE_MAP:-}" ]]; then require_brb_file "$GACU_BRB_SAMPLE_MAP"; fi
echo "WGS input located; sample harmonization is intentionally deferred until the external naming scheme is supplied." >&2
cp -f "$GACU_WGS_VCF" "$GENOTYPE_ROOT/$(basename "$GACU_WGS_VCF")"
