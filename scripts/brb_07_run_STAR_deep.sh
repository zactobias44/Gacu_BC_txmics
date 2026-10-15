#!/usr/bin/env bash
#SBATCH --job-name=brb_star_deep
#SBATCH --array=1-4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --time=4-00:00:00
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
load_brb_modules; mkdir_brb_outputs
task=${SLURM_ARRAY_TASK_ID:?submit as a four-task array}
read -r _ year tissue r1s r2s whitelist prefix < <(awk -v t="$task" 'NR>1 && $1==t {print}' "$DEEP_CONFIG")
wl="$BRB_REPO_ROOT/metadata/barcodes_${whitelist}.txt"; work="$STAR_WORK_ROOT/${prefix}_deep"
mkdir -p "$work" "$STAR_OUTPUT_ROOT"
concat_manifest_paths "$r1s" "$work/R1.fastq.gz"; concat_manifest_paths "$r2s" "$work/R2.fastq.gz"
"$STAR" --runMode alignReads --runThreadN "$BRB_CPUS_DEEP" \
    --outSAMmapqUnique 60 --outSAMunmapped Within --soloStrand Forward --quantMode GeneCounts \
    --outBAMsortingThreadN "$BRB_CPUS_DEEP" --genomeDir "$STAR_INDEX" \
    --soloType CB_UMI_Simple --soloCBstart 1 --soloCBlen 14 --soloUMIstart 15 --soloUMIlen 14 \
    --soloUMIdedup NoDedup 1MM_Directional --soloCellFilter None --soloCBwhitelist "$wl" \
    --soloBarcodeReadLength 1 --soloFeatures Gene --outSAMattributes NH HI nM AS CR UR CB UB GX GN sS sQ sM \
    --outFilterMultimapNmax 1 --readFilesCommand zcat --outSAMtype BAM SortedByCoordinate \
    --outFileNamePrefix "$STAR_OUTPUT_ROOT/${prefix}_deep_" --limitBAMsortRAM 500000000000 \
    --readFilesIn "$work/R2.fastq.gz" "$work/R1.fastq.gz"
