#!/usr/bin/env bash
# Compatibility alias for the renumbered relatedness stage.
#SBATCH --job-name=brb_relatedness
#SBATCH --array=1-2
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_relatedness_%A_%a.out
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_13_relatedness.sh" "$@"
