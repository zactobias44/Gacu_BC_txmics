#!/usr/bin/env bash
# Compatibility alias retained for already-submitted split-BAM jobs.
#SBATCH --job-name=brb_split_bams
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=10G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_split_bams_%A_%a.out
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_06_split_bams.sh" "$@"
