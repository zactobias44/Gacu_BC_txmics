# Gacu_BC_txmics Agent Notes

## Purpose

This repository contains the BRBseq workflow for British Columbia stickleback
collections and will later contain the conventional mRNA-seq workflow. The
active pipeline covers STAR indexing/mapping, FastReadCounter counts,
barcode-level BAM splitting, BRBseq variant calling, and later integration with
externally supplied WGS genotypes for admixture and relatedness.

## Environment and paths

- Poseidon is the configured default site.
- Poseidon/Hydra reads: repository-local `reads/`.
- Pipeline scratch and generated outputs: repository-local `outputs/`; per-sample BAMs are in `outputs/bams/`.
- Hydra is supported through the site defaults in `config/brb_pipeline_config.sh`.
- Reference inputs belong in `genome/`; STAR indices are generated there and are not tracked.

## Repository layout

- `config/`: site paths, software paths, Slurm resources, and output roots.
- `metadata/`: sample, barcode, run, and molecular metadata manifests.
- `genome/`: reference FASTA, GTFs, chromosome BEDs, and generated STAR indices.
- `scripts/`: numbered BRBseq stages, without a `subscripts/` directory.
- `.codex_manifest/`: lightweight path manifest for remote/HPC context.

## Pipeline conventions

- Shallow STAR remains gene-level and uses `NoDedup`.
- Deep STAR emits both conventional and UMI-deduplicated STARsolo matrices using `NoDedup 1MM_Directional`.
- FastReadCounter remains the non-UMI-deduplicated cross-check.
- 2024/2025 run structure is defined in `metadata/brb_*_runs.tsv`.
- 2025 positional barcode mappings require final Davis Core verification where noted.
- WGS/admixture/relatedness inputs remain configurable; do not assume the old WGS repository or sample naming scheme.

## Manifest workflow

```bash
bash scripts/workflow/make_codex_manifest.sh
```

The manifest records paths, types, sizes, and modification times without copying
FASTQs, BAMs, VCFs, matrices, software, or scratch outputs. Use
`scripts/workflow/manifest_commit_push.sh "message"` for HPC-side updates.

## Safe operating rules

- Run `scripts/brb_00_validate_inputs.sh` before expensive jobs.
- Do not launch heavy Slurm, STAR, variant-calling, PLINK, or admixture jobs without explicit user direction.
- Preserve metadata notes about questionable samples and barcode assignments.
- Prefer small, reviewable edits and retain the numbered pipeline structure.
