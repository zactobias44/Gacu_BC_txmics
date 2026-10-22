# BRBseq pipeline

The scripts follow the broad order of `2024_Gacu_BRBseq`, but all scripts live
directly in this directory. The four library jobs are 2024 gill, 2024 liver,
2025 gill, and 2025 liver. Deep 2024 inputs concatenate the two tissue runs;
deep 2025 inputs concatenate the independent tissue run with the final combined
run.

Shallow STAR remains `--soloUMIdedup NoDedup`. Deep STAR uses
`--soloUMIdedup NoDedup 1MM_Directional`, producing both conventional and UMI-
deduplicated STARsolo matrices. These STARsolo matrices are the expression-count
source.

Poseidon is configured as the default in `config/brb_pipeline_config.sh`,
including repository-local reads, repository-local `outputs/`, sibling genome, and
software locations. Thus the normal Poseidon invocation is simply
`bash scripts/brb_00_validate_inputs.sh` followed by `bash scripts/brb_submit.sh`.
To move to Hydra, change `GACU_SITE` in the config and edit the Hydra defaults
there. No partition is hard-coded; pass site-specific `sbatch` options when
submitting.

Run `brb_00_validate_inputs.sh`, then submit individual stages or use
`brb_submit.sh` for the STAR and BRB-seq VCF stages. The canonical stages are:

```text
brb_00_validate_inputs.sh
    -> brb_01_make_STAR_genome_index.sh
    -> brb_02_make_STAR_genome_index_one_feature.sh
    -> brb_03_run_STAR_shallow.sh       (four library tasks)
    -> brb_04_run_STAR_deep_one_feature.sh (four library tasks)
    -> brb_05_run_STAR_deep.sh           (four library tasks)
    -> brb_06_split_bams.sh              (one task per manifest sample/tissue)
    -> brb_07_make_bam_lists.sh
    -> brb_08_joint_calling_by_tissue.sh (21 gill + 21 liver tasks)

brb_09_prepare_external_wgs_inputs.sh    (21 chromosome tasks; can run in parallel)
    -> brb_10_make_tissue_panels.sh       (21 gill + 21 liver tasks)
    -> brb_11_make_plink_panels.sh        (five panel tasks)
    -> brb_12_relatedness.sh              (one gill + one liver task)
    -> brb_13_run_admixture.sh            (63 panel/K tasks)
```

The tissue-panel stage depends on the BRB chromosome-specific calls and
`brb_09_prepare_external_wgs_inputs.sh`.

The external WGS defaults point to the expanded filtered VCF directory and
retain every `2024_DJR*` and `2025_DJR*` WGS sample. The mapping table assigns
`_D` to WGS, `_G` to gill BRB, and `_L` to liver BRB. Each tissue panel is
intersected with WGS at shared variant sites, converted to PLINK, filtered,
and LD-pruned before relatedness. Admixture is run separately on the WGS-only,
gill-BRB-only, and liver-BRB-only panels, so no WGS and BRB sample types are
concatenated for the admixture input.
