#!/usr/bin/env bash
# Compatibility alias for the renumbered external-WGS stage.
#SBATCH --job-name=brb_wgs_subset
#SBATCH --array=1-21
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_wgs_subset_%A_%a.out
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_10_prepare_external_wgs_inputs.sh" "$@"
