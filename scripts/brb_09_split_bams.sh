#!/usr/bin/env bash
# Split the full deep STAR BAM into one indexed BAM per barcode/sample.
# Submit with: sbatch --array=1-$(($(wc -l < metadata/brb_sample_barcodes.tsv)-1)) ...
#SBATCH --job-name=brb_split_bams
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=40G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_split_bams_%A_%a.out
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
require_brb_command "$SAMTOOLS"
task=${SLURM_ARRAY_TASK_ID:?submit this script as a sample array}
read -r sample year tissue barcode _ _ < <(awk -v t="$task" 'NR>1 && NR-1==t {print}' "$SAMPLE_BARCODE_CONFIG")
[[ -n "${sample:-}" ]] || { echo "No sample task $task" >&2; exit 2; }
prefix="${tissue}_${year}"
input="$STAR_OUTPUT_ROOT/${prefix}_deep_Aligned.sortedByCoord.out.bam"
require_brb_file "$input"
outdir="$SPLIT_BAM_ROOT/$sample"; mkdir -p "$outdir"
raw="$outdir/${sample}_${tissue}.bam"; rg="$outdir/${sample}_${tissue}_RG.bam"
"$SAMTOOLS" view -@ 3 -b -h -F 2308 -d "CB:${barcode}" "$input" > "$raw"
"$SAMTOOLS" addreplacerg -@ 3 -r "ID:${sample}_${tissue}" -r "LB:BRBseq" -r "PL:ILLUMINA" -r "PU:${year}" -r "SM:${sample}" -o "$rg" "$raw"
"$SAMTOOLS" index -@ 3 "$rg"
rm -f "$raw"
