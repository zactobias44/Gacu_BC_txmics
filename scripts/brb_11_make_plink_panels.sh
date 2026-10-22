#!/usr/bin/env bash
# Build filtered/LD-pruned PLINK panels for relatedness and separate admixture.
# Array tasks: 1=gill combined, 2=liver combined, 3=WGS-only,
# 4=gill BRB-only, 5=liver BRB-only.
#SBATCH --job-name=brb_plink_panel
#SBATCH --array=1-5
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=../logs/brb_plink_panel_%A_%a.out
set -euo pipefail
if [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/../config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
elif [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR/scripts"
else
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
source "$REPO_ROOT/config/brb_pipeline_config.sh"
load_brb_modules; mkdir_brb_outputs
require_brb_command "$BCFTOOLS"; require_brb_command "$PLINK"
task=${SLURM_ARRAY_TASK_ID:?submit as a five-task array}

case "$task" in
    1) panel=gill_wgs_brb; mode=combined; tissue=gill ;;
    2) panel=liver_wgs_brb; mode=combined; tissue=liver ;;
    3) panel=wgs; mode=wgs ;;
    4) panel=gill_brb; mode=brb; tissue=gill ;;
    5) panel=liver_brb; mode=brb; tissue=liver ;;
    *) echo "Unsupported task: $task" >&2; exit 2 ;;
esac

tmp=$(mktemp -d "$PLINK_ROOT/${panel}.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
mapfile -t chromosomes < <(awk 'NR>1 {print $3}' "$CHR_CONFIG")
mapfile -t inputs < <(
    for c in "${chromosomes[@]}"; do
        if [[ "$mode" == combined ]]; then
            printf '%s\n' "$RELATEDNESS_ROOT/${tissue}_${c}.vcf.gz"
        elif [[ "$mode" == wgs ]]; then
            printf '%s\n' "$WGS_SUBSET_ROOT/wgs_djr_${c}.vcf.gz"
        else
            printf '%s\n' "$tmp/${tissue}_${c}.vcf.gz"
        fi
    done
)

if [[ "$mode" == brb ]]; then
    brb_rename="$tmp/${tissue}_brb_reheader.tsv"
    awk -F '\t' -v t="$tissue" 'NR>1 && $3=="BRB" && $4==t {print $2"\t"$1}' \
        "$SAMPLE_SOURCE_MAP" | sort -u > "$brb_rename"
    for i in "${!chromosomes[@]}"; do
        input="$VARIANT_ROOT/brbseq_${tissue}_${chromosomes[$i]}.vcf.gz"
        require_brb_file "$input"; require_brb_file "$input.csi"
        "$BCFTOOLS" reheader -s "$brb_rename" "$input" -Oz -o "${inputs[$i]}"
        "$BCFTOOLS" index -f "${inputs[$i]}"
    done
fi

for v in "${inputs[@]}"; do require_brb_file "$v"; require_brb_file "$v.csi"; done
combined="$tmp/${panel}_all_chromosomes.vcf.gz"
"$BCFTOOLS" concat -Oz -o "$combined" "${inputs[@]}"
"$BCFTOOLS" index -f "$combined"
prefix="$PLINK_ROOT/${panel}"
"$PLINK" --vcf "$combined" --double-id --keep-allele-order --allow-extra-chr \
    --snps-only just-acgt --biallelic-only strict --geno 0.20 --maf 0.01 \
    --set-missing-var-ids '@:#' --make-bed --out "$prefix"
"$PLINK" --bfile "$prefix" --allow-extra-chr --indep-pairwise 50 5 0.2 --out "$prefix"
"$PLINK" --bfile "$prefix" --allow-extra-chr --extract "$prefix.prune.in" --make-bed --out "${prefix}_ldpruned"
