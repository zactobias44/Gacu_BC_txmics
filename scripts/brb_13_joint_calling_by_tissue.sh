#!/usr/bin/env bash
# Compatibility alias for the renumbered tissue joint-calling stage.
#SBATCH --job-name=brb_joint_tissue
#SBATCH --array=1-42
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=120G
#SBATCH --time=2-00:00:00
#SBATCH --qos=unlim
#SBATCH --output=../logs/brb_joint_tissue_%A_%a.out
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_08_joint_calling_by_tissue.sh" "$@"
