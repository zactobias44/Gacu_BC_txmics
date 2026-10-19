#!/usr/bin/env bash
# Run admixture separately on WGS, gill BRB, and liver BRB.
#SBATCH --job-name=brb_admixture
#SBATCH --array=1-3
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=23:59:00
#SBATCH --output=../logs/brb_admixture_%A_%a.out
set -euo pipefail
if [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/config/brb_pipeline_config.sh" ]]; then SCRIPT_DIR="$SLURM_SUBMIT_DIR/scripts"; else SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); fi
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
load_brb_modules; mkdir_brb_outputs
require_brb_command "$ADMIXTURE"
task=${SLURM_ARRAY_TASK_ID:?submit as a three-task array}
case "$task" in
    1) panel=wgs ;;
    2) panel=gill_brb ;;
    3) panel=liver_brb ;;
    *) echo "Unsupported task: $task" >&2; exit 2 ;;
esac
prefix="$PLINK_ROOT/${panel}_ldpruned"
require_brb_file "$prefix.bed"
cd "$PLINK_ROOT"
for k in $GACU_ADMIXTURE_KS; do
    "$ADMIXTURE" --cv "$prefix.bed" "$k" | tee "$GENOTYPE_ROOT/${panel}_admixture_K${k}.log"
done
