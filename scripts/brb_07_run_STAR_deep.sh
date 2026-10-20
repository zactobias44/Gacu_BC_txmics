#!/usr/bin/env bash
# Compatibility alias for the renumbered deep STAR stage.
#SBATCH --job-name=brb_star_deep
#SBATCH --array=1-4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=180G
#SBATCH --time=4-00:00:00
#SBATCH --qos=unlim
#SBATCH --output=../logs/brb_star_deep_%A_%a.out
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_05_run_STAR_deep.sh" "$@"
