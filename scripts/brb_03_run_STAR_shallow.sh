#!/usr/bin/env bash
#SBATCH --job-name=brb_star_shallow
#SBATCH --array=1-4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=80G
#SBATCH --time=2-00:00:00
#SBATCH --qos=unlim
#SBATCH --output=../logs/brb_star_shallow_%A_%a.out
set -euo pipefail
if [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR/scripts"
elif [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/../config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
else
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
source "$SCRIPT_DIR/../config/brb_pipeline_config.sh"
load_brb_modules; mkdir_brb_outputs
task=${SLURM_ARRAY_TASK_ID:?submit as a four-task array}
read -r _ year tissue r1 r2 whitelist prefix < <(awk -v t="$task" 'NR>1 && $1==t {print}' "$SHALLOW_CONFIG")
[[ -n "${prefix:-}" ]] || { echo "No shallow task $task" >&2; exit 2; }
out="$STAR_OUTPUT_ROOT/${prefix}_shallow_"; wl="$BRB_REPO_ROOT/metadata/barcodes_${whitelist}.txt"
mkdir -p "$STAR_OUTPUT_ROOT"
"$STAR" --runMode alignReads --runThreadN "$BRB_CPUS_SHALLOW" \
    --outSAMmapqUnique 60 --outSAMunmapped Within --soloStrand Forward --quantMode GeneCounts \
    --outBAMsortingThreadN "$BRB_CPUS_SHALLOW" --genomeDir "$STAR_INDEX_ONE_FEATURE" \
    --soloType CB_UMI_Simple --soloCBstart 1 --soloCBlen 14 --soloUMIstart 15 --soloUMIlen 14 \
    --soloUMIdedup NoDedup --soloCellFilter None --soloCBwhitelist "$wl" --soloBarcodeReadLength 1 \
    --soloFeatures Gene --outSAMattributes NH HI nM AS CR UR CB UB GX GN sS sQ sM \
    --outFilterMultimapNmax 1 --readFilesCommand zcat --outSAMtype BAM SortedByCoordinate \
    --outFileNamePrefix "$out" --limitBAMsortRAM 78000000000 \
    --readFilesIn "$(resolve_read_path "$r2")" "$(resolve_read_path "$r1")"
