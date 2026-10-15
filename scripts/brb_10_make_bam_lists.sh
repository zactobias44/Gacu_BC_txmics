#!/usr/bin/env bash
# Build explicit BAM lists for variant calling and downstream relatedness.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
mkdir_brb_outputs
out="$BRB_REPO_ROOT/metadata"
find "$SPLIT_BAM_ROOT" -type f -name '*_RG.bam' | sort > "$out/brb_bamlist.txt"
awk -F/ '{n=$NF; if (n ~ /_gill_RG\.bam$/) print}' "$out/brb_bamlist.txt" > "$out/brb_gill_bamlist.txt"
awk -F/ '{n=$NF; if (n ~ /_liver_RG\.bam$/) print}' "$out/brb_bamlist.txt" > "$out/brb_liver_bamlist.txt"
[[ -s "$out/brb_bamlist.txt" ]] || { echo "No split BAMs found under $SPLIT_BAM_ROOT" >&2; exit 1; }
echo "Wrote BAM lists under $out"
