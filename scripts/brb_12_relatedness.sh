#!/usr/bin/env bash
# Run pairwise PLINK relatedness on the LD-pruned tissue-specific panel.
#SBATCH --job-name=brb_relatedness
#SBATCH --array=1-2
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_relatedness_%A_%a.out
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
task=${SLURM_ARRAY_TASK_ID:?submit as a two-task array}; tissue=$([[ "$task" == 1 ]] && echo gill || echo liver)
prefix="$PLINK_ROOT/${tissue}_wgs_brb_ldpruned"
for ext in bed bim fam; do require_brb_file "$prefix.$ext"; done
"$PLINK" --bfile "$prefix" --genome full --allow-extra-chr --out "$RELATEDNESS_ROOT/${tissue}_wgs_brb_relatedness"
