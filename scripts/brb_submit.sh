#!/usr/bin/env bash
set -euo pipefail
if [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR/scripts"
elif [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "$SLURM_SUBMIT_DIR/../config/brb_pipeline_config.sh" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
else
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
samples=$(awk 'NR>1 {n++} END {print n+0}' "$ROOT/metadata/brb_sample_barcodes.tsv")
jid_index=$(sbatch --parsable "$SCRIPT_DIR/brb_01_make_STAR_genome_index.sh")
jid_1f=$(sbatch --parsable --dependency="afterok:$jid_index" "$SCRIPT_DIR/brb_02_make_STAR_genome_index_one_feature.sh")
jid_shallow=$(sbatch --parsable --dependency="afterok:$jid_1f" "$SCRIPT_DIR/brb_03_run_STAR_shallow.sh")
sbatch --dependency="afterok:$jid_shallow" "$SCRIPT_DIR/brb_04_FastReadCounter_shallow.sh"
jid_deep1=$(sbatch --parsable --dependency="afterok:$jid_1f" "$SCRIPT_DIR/brb_05_run_STAR_deep_one_feature.sh")
sbatch --dependency="afterok:$jid_deep1" "$SCRIPT_DIR/brb_06_FastReadCounter_deep_one_feature.sh"
jid_deep=$(sbatch --parsable --dependency="afterok:$jid_index" "$SCRIPT_DIR/brb_07_run_STAR_deep.sh")
sbatch --dependency="afterok:$jid_deep" "$SCRIPT_DIR/brb_08_FastReadCounter_deep.sh"
jid_split=$(sbatch --parsable --dependency="afterok:$jid_deep" --array="1-${samples}" "$SCRIPT_DIR/brb_09_split_bams.sh")
jid_lists=$(sbatch --parsable --dependency="afterok:$jid_split" "$SCRIPT_DIR/brb_10_make_bam_lists.sh")
sbatch --dependency="afterok:$jid_lists" "$SCRIPT_DIR/brb_11_joint_calling.sh"
sbatch --dependency="afterok:$jid_lists" "$SCRIPT_DIR/brb_13_joint_calling_by_tissue.sh"
echo "Submitted BRBseq chain; final BAM-list job is $jid_lists" >&2
