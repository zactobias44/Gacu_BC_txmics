#!/usr/bin/env bash
# Validate configuration and metadata before submitting the expensive jobs.
set -euo pipefail
if [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR/scripts"
elif [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/../config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
else
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
load_brb_modules
mkdir_brb_outputs

for f in "$GENOME_FASTA" "$GENOME_GTF" "$ONE_FEATURE_GTF" "$SHALLOW_CONFIG" "$DEEP_CONFIG" "$SAMPLE_BARCODE_CONFIG" "$CHR_CONFIG"; do
    require_brb_file "$f"
done
require_brb_command python3
python3 "$BRB_REPO_ROOT/metadata/build_brb_manifest.py" --check-only

echo "BRBseq configuration is valid for site=$GACU_SITE"
echo "reads:   $GACU_READS_ROOT"
echo "scratch: $GACU_SCRATCH_ROOT"
echo "genome:  $GACU_GENOME_ROOT"
echo "samples: $(awk 'NR>1 {n++} END {print n+0}' "$SAMPLE_BARCODE_CONFIG")"
