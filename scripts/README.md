# BRBseq pipeline

The scripts follow the broad order of `2024_Gacu_BRBseq`, but all scripts live
directly in this directory. The four library jobs are 2024 gill, 2024 liver,
2025 gill, and 2025 liver. Deep 2024 inputs concatenate the two tissue runs;
deep 2025 inputs concatenate the independent tissue run with the final combined
run.

Shallow STAR remains `--soloUMIdedup NoDedup`. Deep STAR uses
`--soloUMIdedup NoDedup 1MM_Directional`, producing both conventional and UMI-
deduplicated STARsolo matrices. FastReadCounter remains the legacy
non-UMI-deduplicated cross-check.

Hydra is the default. Set `GACU_HYDRA_READS_ROOT`, `GACU_HYDRA_SCRATCH_ROOT`,
`GACU_GENOME_ROOT`, `GACU_SOFTWARE_ROOT`, and optionally
`GACU_HYDRA_MODULES`. For Poseidon, use `GACU_SITE=poseidon` and the matching
`GACU_POSEIDON_*` variables. No partition is hard-coded; pass site-specific
`sbatch` options when submitting.

Run `brb_00_validate_inputs.sh`, then submit individual stages or use
`brb_submit.sh`. The WGS/admixture/relatedness scripts intentionally accept
external inputs rather than assuming a repository. Set `GACU_WGS_VCF` first;
after the sample naming scheme is finalized, provide sample maps and use the
harmonized PLINK prefixes through `GACU_ADMIXTURE_BED_PREFIX` and
`GACU_RELATEDNESS_BED_PREFIX`.
