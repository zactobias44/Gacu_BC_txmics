#!/usr/bin/env bash

# Site-portable configuration for the BRB-seq branch.
# Set GACU_SITE, GACU_READS_ROOT, GACU_GENOME_ROOT, and GACU_SCRATCH_ROOT
# in the environment or edit the site blocks below before submitting jobs.

set -euo pipefail

BRB_REPO_ROOT="${BRB_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# Poseidon is the current default so the pipeline can be run immediately from
# the established Expanse checkout. Set GACU_SITE=hydra only when switching
# clusters; site-specific defaults below remain editable in this file.
GACU_SITE="${GACU_SITE:-poseidon}"

case "$GACU_SITE" in
    hydra)
        # Hydra paths/modules are intentionally not guessed here. Set these
        # site values in your shell or a local untracked override file.
        DEFAULT_READS_ROOT="${GACU_HYDRA_READS_ROOT:-$BRB_REPO_ROOT/reads}"
        DEFAULT_SCRATCH_ROOT="${GACU_HYDRA_SCRATCH_ROOT:-$BRB_REPO_ROOT/work}"
        DEFAULT_MODULES="${GACU_HYDRA_MODULES:-}"
        ;;
    poseidon)
        DEFAULT_READS_ROOT="${GACU_POSEIDON_READS_ROOT:-/expanse/lustre/projects/csd932/ztobias/BRBseq/reads}"
        DEFAULT_SCRATCH_ROOT="${GACU_POSEIDON_SCRATCH_ROOT:-/vortexfs1/scratch/ztobias/Gaculeatus/Gacu_BC_txmics}"
        DEFAULT_MODULES="${GACU_POSEIDON_MODULES:-bio htslib bcftools samtools jdk/16.0.1}"
        ;;
    local)
        DEFAULT_READS_ROOT="$BRB_REPO_ROOT/reads"
        DEFAULT_SCRATCH_ROOT="$BRB_REPO_ROOT/work"
        DEFAULT_MODULES=""
        ;;
    *)
        echo "Unknown GACU_SITE=$GACU_SITE (use hydra, poseidon, or local)" >&2
        exit 2
        ;;
esac

GACU_READS_ROOT="${GACU_READS_ROOT:-$DEFAULT_READS_ROOT}"
GACU_SCRATCH_ROOT="${GACU_SCRATCH_ROOT:-$DEFAULT_SCRATCH_ROOT}"
GACU_GENOME_ROOT="${GACU_GENOME_ROOT:-$BRB_REPO_ROOT/genome}"
GACU_SOFTWARE_ROOT="${GACU_SOFTWARE_ROOT:-$BRB_REPO_ROOT/software}"

if [[ "$GACU_SITE" == "poseidon" && ! -d "$GACU_GENOME_ROOT" && -d "$BRB_REPO_ROOT/../2024_Gacu_BRBseq/genome" ]]; then
    GACU_GENOME_ROOT="$BRB_REPO_ROOT/../2024_Gacu_BRBseq/genome"
fi
if [[ "$GACU_SITE" == "poseidon" && ! -d "$GACU_SOFTWARE_ROOT" && -d "$BRB_REPO_ROOT/../2024_Gacu_BRBseq/software" ]]; then
    GACU_SOFTWARE_ROOT="$BRB_REPO_ROOT/../2024_Gacu_BRBseq/software"
fi

# Local compatibility fallback while the new repo is being assembled.
if [[ ! -f "$GACU_GENOME_ROOT/GCF_016920845.1_GAculeatus_UGA_version5_genomic.fna" \
   && -f "$BRB_REPO_ROOT/../2024_Gacu_mRNAseq/genome/GCF_016920845.1_GAculeatus_UGA_version5_genomic.fna" ]]; then
    GACU_GENOME_ROOT="$BRB_REPO_ROOT/../2024_Gacu_mRNAseq/genome"
fi

GENOME_FASTA="${GACU_GENOME_ROOT}/GCF_016920845.1_GAculeatus_UGA_version5_genomic.fna"
GENOME_GTF="${GACU_GENOME_ROOT}/GCF_016920845.1_GAculeatus_UGA_version5_genomic.gtf"
ONE_FEATURE_GTF="${GACU_ONE_FEATURE_GTF:-$GACU_GENOME_ROOT/genome_one_feature.gtf}"
if [[ ! -f "$ONE_FEATURE_GTF" && -f "$BRB_REPO_ROOT/../2024_Gacu_BRBseq/genome/genome_one_feature.gtf" ]]; then
    ONE_FEATURE_GTF="$BRB_REPO_ROOT/../2024_Gacu_BRBseq/genome/genome_one_feature.gtf"
fi
STAR_INDEX="${GACU_GENOME_ROOT}/4STAR"
STAR_INDEX_ONE_FEATURE="${GACU_GENOME_ROOT}/4STAR_one_feature"

STAR="${GACU_STAR_BIN:-$GACU_SOFTWARE_ROOT/STAR-2.7.11b/source/STAR}"
FAST_READ_COUNTER="${GACU_FAST_READ_COUNTER:-$GACU_SOFTWARE_ROOT/FastReadCounter-1.1.jar}"
SAMTOOLS="${GACU_SAMTOOLS_BIN:-samtools}"
BCFTOOLS="${GACU_BCFTOOLS_BIN:-bcftools}"
PLINK="${GACU_PLINK_BIN:-plink}"
ADMIXTURE="${GACU_ADMIXTURE_BIN:-admixture}"

SCRATCH_ROOT="$GACU_SCRATCH_ROOT"
STAR_WORK_ROOT="${GACU_STAR_WORK_ROOT:-$SCRATCH_ROOT/star}"
BRB_OUTPUT_ROOT="${GACU_BRB_OUTPUT_ROOT:-$SCRATCH_ROOT/brbseq}"
STAR_OUTPUT_ROOT="$BRB_OUTPUT_ROOT/star"
COUNTS_ROOT="$BRB_OUTPUT_ROOT/matrix"
SPLIT_BAM_ROOT="$BRB_OUTPUT_ROOT/split_bams"
VARIANT_ROOT="$BRB_OUTPUT_ROOT/variants"
GENOTYPE_ROOT="$BRB_OUTPUT_ROOT/genotypes"
LOG_ROOT="${GACU_LOG_ROOT:-$BRB_REPO_ROOT/logs/brbseq}"

SHALLOW_CONFIG="$BRB_REPO_ROOT/metadata/brb_shallow_runs.tsv"
DEEP_CONFIG="$BRB_REPO_ROOT/metadata/brb_deep_runs.tsv"
SAMPLE_BARCODE_CONFIG="$BRB_REPO_ROOT/metadata/brb_sample_barcodes.tsv"
CHR_CONFIG="${GACU_CHR_CONFIG:-$BRB_REPO_ROOT/metadata/brb_chromosomes.tsv}"

# Site-specific Slurm resources. These can be overridden per invocation with
# environment variables; no partition is hard-coded into the scripts.
BRB_CPUS_INDEX="${BRB_CPUS_INDEX:-1}"
BRB_CPUS_SHALLOW="${BRB_CPUS_SHALLOW:-16}"
BRB_CPUS_DEEP_ONE_FEATURE="${BRB_CPUS_DEEP_ONE_FEATURE:-24}"
BRB_CPUS_DEEP="${BRB_CPUS_DEEP:-40}"
BRB_MEM_INDEX="${BRB_MEM_INDEX:-50G}"
BRB_MEM_SHALLOW="${BRB_MEM_SHALLOW:-80G}"
BRB_MEM_DEEP_ONE_FEATURE="${BRB_MEM_DEEP_ONE_FEATURE:-250G}"
BRB_MEM_DEEP="${BRB_MEM_DEEP:-505G}"

load_brb_modules() {
    if [[ -n "${DEFAULT_MODULES:-}" && "$(type -t module 2>/dev/null || true)" == "function" ]]; then
        # shellcheck disable=SC2086
        module load $DEFAULT_MODULES
    fi
}

mkdir_brb_outputs() {
    mkdir -p "$STAR_WORK_ROOT" "$STAR_OUTPUT_ROOT" "$COUNTS_ROOT" \
        "$SPLIT_BAM_ROOT" "$VARIANT_ROOT" "$GENOTYPE_ROOT" "$LOG_ROOT"
}

require_brb_file() {
    [[ -f "$1" ]] || { echo "Missing required file: $1" >&2; exit 1; }
}

require_brb_command() {
    command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 1; }
}

resolve_read_path() {
    local path="$1"
    if [[ "$path" = /* ]]; then
        printf '%s\n' "$path"
    else
        printf '%s/%s\n' "$GACU_READS_ROOT" "$path"
    fi
}

concat_manifest_paths() {
    local paths="$1" output="$2"
    local path
    : > "$output"
    IFS=';' read -r -a path_array <<< "$paths"
    for path in "${path_array[@]}"; do
        path="$(resolve_read_path "$path")"
        require_brb_file "$path"
        cat "$path" >> "$output"
    done
}
