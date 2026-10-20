#!/usr/bin/env bash
# Build explicit BAM lists for variant calling and downstream relatedness.
set -euo pipefail
if [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR/scripts"
elif [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/../config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
else
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
mkdir_brb_outputs
out="$BRB_REPO_ROOT/metadata"
all="$out/brb_bamlist.txt"
gill="$out/brb_gill_bamlist.txt"
liver="$out/brb_liver_bamlist.txt"
: > "$all"
: > "$gill"
: > "$liver"

# Build lists from the executable manifest rather than discovering every BAM
# under the output directory. This excludes stale BAMs for samples that were
# removed from the final pool and makes missing expected BAMs fail early.
while IFS=$'\t' read -r sample_id year tissue barcode _ _; do
    [[ -n "$sample_id" ]] || continue
    bam="$SPLIT_BAM_ROOT/$sample_id/${sample_id}_${tissue}_RG.bam"
    require_brb_file "$bam"
    printf '%s\n' "$bam" >> "$all"
    case "$tissue" in
        gill) printf '%s\n' "$bam" >> "$gill" ;;
        liver) printf '%s\n' "$bam" >> "$liver" ;;
        *) echo "Unexpected tissue in manifest: $tissue" >&2; exit 2 ;;
    esac
done < <(tail -n +2 "$SAMPLE_BARCODE_CONFIG")

sort -o "$all" "$all"
sort -o "$gill" "$gill"
sort -o "$liver" "$liver"
[[ -s "$all" ]] || { echo "No manifest BAMs found under $SPLIT_BAM_ROOT" >&2; exit 1; }
echo "Wrote BAM lists under $out"
