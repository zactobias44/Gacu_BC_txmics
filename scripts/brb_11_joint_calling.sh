#!/usr/bin/env bash
# Per-chromosome BRBseq variant calling. The BAM list is deliberately local;
# no WGS data are assumed at this stage.
#SBATCH --job-name=brb_joint_call
#SBATCH --array=1-21
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=180G
#SBATCH --time=2-00:00:00
#SBATCH --qos=unlim
#SBATCH --output=../logs/brb_joint_calling_%A_%a.out
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
task=${SLURM_ARRAY_TASK_ID:?submit as a 21-task array}
read -r _ ncbi roman < <(awk -v t="$task" 'NR>1 && $1==t {print}' "$CHR_CONFIG")
[[ -n "${roman:-}" ]] || { echo "No chromosome task $task" >&2; exit 2; }
bams="${GACU_BAM_LIST:-$BRB_REPO_ROOT/metadata/brb_bamlist.txt}"
bed="${GACU_CHR_BED_DIR:-$GACU_GENOME_ROOT/chr_beds}/${ncbi}.bed"
map="$VARIANT_ROOT/chr_rename.tsv"
require_brb_file "$bams"; require_brb_file "$bed"
awk 'NR>1 {print $2"\t"$3}' "$CHR_CONFIG" > "$map"
out="$VARIANT_ROOT/brbseq_${roman}.vcf.gz"
"$BCFTOOLS" mpileup -f "$GENOME_FASTA" -b "$bams" -O u -a DP,AD -q 20 -Q 20 -B -d 500 -C 50 -R "$bed" | \
"$BCFTOOLS" call -O u -m -v | \
"$BCFTOOLS" view -O u --min-ac 1 --max-alleles 2 --exclude-types indels | \
"$BCFTOOLS" filter -O u -S . -e 'FMT/DP<10 | ALT="<NON_REF>"' | \
"$BCFTOOLS" view -O z -i 'F_MISSING<0.7' | \
"$BCFTOOLS" annotate --rename-chrs "$map" --threads 8 -O z -o "$out"
"$BCFTOOLS" index -f "$out"
