#!/usr/bin/env bash
# Run admixture separately on WGS, gill BRB, and liver BRB.
# Each panel/K combination is a separate task: 3 panels x 21 K values = 63.
#SBATCH --job-name=brb_admixture
#SBATCH --array=1-63
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_admixture_%A_%a.out
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
require_brb_command "$PLINK"
require_brb_command "$ADMIXTURE"
task=${SLURM_ARRAY_TASK_ID:?submit as a 63-task array}
read -ra ks <<< "$GACU_ADMIXTURE_KS"
(( ${#ks[@]} == 21 )) || { echo "Expected 21 K values for the 63-task array" >&2; exit 2; }
panel_index=$(( (task - 1) / ${#ks[@]} + 1 ))
k_index=$(( (task - 1) % ${#ks[@]} ))
k=${ks[$k_index]}
case "$panel_index" in
    1) panel=wgs ;;
    2) panel=gill_brb ;;
    3) panel=liver_brb ;;
    *) echo "Unsupported task: $task" >&2; exit 2 ;;
esac
prefix="$PLINK_ROOT/${panel}_ldpruned"
require_brb_file "$prefix.bed"
cd "$PLINK_ROOT"
temp_prefix="${prefix}.admixture_${SLURM_JOB_ID:-manual}_${task}"
cleanup() {
    rm -f "${temp_prefix}.ped" "${temp_prefix}.map" \
        "${temp_prefix}.${k}.Q" "${temp_prefix}.${k}.P"
}
trap cleanup EXIT

# ADMIXTURE rejects the Roman chromosome names in the BIM file.  The
# historical BRBseq workflow handled this by converting the BED panel to a
# temporary PLINK PED/MAP pair with --recode12 before running ADMIXTURE.
"$PLINK" \
    --bfile "$prefix" \
    --allow-extra-chr \
    --recode12 \
    --out "$temp_prefix"

"$ADMIXTURE" --cv -j"${SLURM_CPUS_PER_TASK:-4}" "${temp_prefix}.ped" "$k" \
    | tee "$GENOTYPE_ROOT/${panel}_admixture_K${k}.log"

mv "${temp_prefix}.${k}.Q" "${prefix}.${k}.Q"
mv "${temp_prefix}.${k}.P" "${prefix}.${k}.P"
