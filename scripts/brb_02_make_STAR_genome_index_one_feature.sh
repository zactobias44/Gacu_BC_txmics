#!/usr/bin/env bash
#SBATCH --job-name=brb_star_index_1f
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=23:59:00
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
load_brb_modules
require_brb_file "$GENOME_FASTA"; require_brb_file "$ONE_FEATURE_GTF"
mkdir -p "$STAR_INDEX_ONE_FEATURE"
"$STAR" --runThreadN "$BRB_CPUS_INDEX" --runMode genomeGenerate \
    --genomeDir "$STAR_INDEX_ONE_FEATURE" --genomeFastaFiles "$GENOME_FASTA" \
    --sjdbGTFfile "$ONE_FEATURE_GTF"
