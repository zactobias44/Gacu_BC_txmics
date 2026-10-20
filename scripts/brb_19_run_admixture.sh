#!/usr/bin/env bash
# Compatibility alias for the renumbered admixture stage.
#SBATCH --job-name=brb_admixture
#SBATCH --array=1-63
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_admixture_%A_%a.out
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_14_run_admixture.sh" "$@"
