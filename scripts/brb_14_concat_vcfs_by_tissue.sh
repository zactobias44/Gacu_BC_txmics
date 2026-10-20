#!/usr/bin/env bash
# Compatibility alias for the renumbered VCF concatenation stage.
#SBATCH --job-name=brb_concat_vcfs
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_concat_vcfs_%j.out
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_09_concat_vcfs_by_tissue.sh" "$@"
