#!/usr/bin/env bash
# Compatibility alias for the renumbered tissue-panel stage.
#SBATCH --job-name=brb_qc_panel
#SBATCH --array=1-42
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_qc_panel_%A_%a.out
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_11_make_tissue_panels.sh" "$@"
