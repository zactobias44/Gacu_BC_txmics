# Sample tracking tables

`sample_tracking.tsv` is the canonical individual-level manifest assembled from
the 2024 and 2025 collection/molecular metadata and the existing 2024
BRBseq/mRNAseq metadata. It is deliberately a tracking table, not a final
analysis filter.

`sample_tracking_notes.tsv` records known identity problems, historical
exclusions, ancestry flags, library redo/re-extraction flags, and sample-level
notes that should be checked before final manifests are generated.

Important conventions:

- `usable`/`prepared` means the source metadata indicates material/library
  exists; it does not mean the reads passed alignment or count QC.
- 2024 RNA/tissue labels and DNA/WGS labels are kept conceptually separate.
  In particular, 041/042 and the 101-104 liver records require explicit
  cross-modality identity checking.
- Historical exclusions are recorded as notes and are not removed from the
  tracking table.
- 2025 `population` is the collection `Pair Name`; `site_type` and `site_name`
  preserve the collection context. Ecotype assignments should be added only
  after the population/habitat mapping is finalized.

Regenerate the derived tables with:

```bash
python3 metadata/build_sample_tracking.py
```

Run `jupyter_notebooks/BRB_WGS_sample_ID_QC.ipynb` first to create
`sample_source_mapping_QC_BRB.tsv` and its QC decision log. Then run
`jupyter_notebooks/BRBseq_DiffEx.ipynb`; it applies the gill-PCA sex calls for
`2025_DJR_196` (female) and `2024_DJR_196` (male) and writes the authoritative
`*_FINAL_BRB.tsv` files. Manual overrides are marked in `final_sex_source` and
documented in `final_sex_override_note`.
