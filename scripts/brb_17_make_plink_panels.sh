#!/usr/bin/env bash
# Compatibility alias for the renumbered PLINK-panel stage.
#SBATCH --job-name=brb_plink_panel
#SBATCH --array=1-5
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_plink_panel_%A_%a.out
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_12_make_plink_panels.sh" "$@"
