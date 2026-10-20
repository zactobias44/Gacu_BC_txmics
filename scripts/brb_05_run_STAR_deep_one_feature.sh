#!/usr/bin/env bash
# Compatibility alias for the renumbered deep one-feature STAR stage.
#SBATCH --job-name=brb_star_deep_1f
#SBATCH --array=1-4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=180G
#SBATCH --time=3-00:00:00
#SBATCH --qos=unlim
#SBATCH --output=../logs/brb_star_deep_1f_%A_%a.out
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_04_run_STAR_deep_one_feature.sh" "$@"
