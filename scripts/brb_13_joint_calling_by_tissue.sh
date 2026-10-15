#!/usr/bin/env bash
# Same call as brb_11, split by tissue. Use array task 1-42: tasks 1-21 gill,
# tasks 22-42 liver.
#SBATCH --job-name=brb_joint_tissue
#SBATCH --array=1-42
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=180G
#SBATCH --time=2-00:00:00
#SBATCH --qos=unlim
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
require_brb_command "$BCFTOOLS"; require_brb_file "$GENOME_FASTA"
task=${SLURM_ARRAY_TASK_ID:?submit as a 42-task array}
if (( task <= 21 )); then tissue=gill; chr_task=$task; else tissue=liver; chr_task=$((task-21)); fi
read -r _ ncbi roman < <(awk -v t="$chr_task" 'NR>1 && $1==t {print}' "$CHR_CONFIG")
bams="$BRB_REPO_ROOT/metadata/brb_${tissue}_bamlist.txt"
bed="${GACU_CHR_BED_DIR:-$GACU_GENOME_ROOT/chr_beds}/${ncbi}.bed"; map="$VARIANT_ROOT/chr_rename.tsv"
require_brb_file "$bams"; require_brb_file "$bed"
awk 'NR>1 {print $2"\t"$3}' "$CHR_CONFIG" > "$map"
out="$VARIANT_ROOT/brbseq_${tissue}_${roman}.vcf.gz"
"$BCFTOOLS" mpileup -f "$GENOME_FASTA" -b "$bams" -O u -a DP,AD -q 20 -Q 20 -B -d 500 -C 50 -R "$bed" | \
"$BCFTOOLS" call -O u -m -v | "$BCFTOOLS" view -O u --min-ac 1 --max-alleles 2 --exclude-types indels | \
"$BCFTOOLS" filter -O u -S . -e 'FMT/DP<10 | ALT="<NON_REF>"' | "$BCFTOOLS" view -O z -i 'F_MISSING<0.7' | \
"$BCFTOOLS" annotate --rename-chrs "$map" --threads 8 -O z -o "$out"
"$BCFTOOLS" index -f "$out"
