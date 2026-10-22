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
"$ADMIXTURE" --cv -j"${SLURM_CPUS_PER_TASK:-4}" "$prefix.bed" "$k" \
    | tee "$GENOTYPE_ROOT/${panel}_admixture_K${k}.log"
