# Sample tracking tables

`sample_tracking.tsv` is the canonical individual-level manifest assembled from
the 2024 and 2025 collection/molecular metadata and the existing 2024
BRBseq/mRNAseq metadata. It is deliberately a tracking table, not a final
analysis filter.

`sample_tracking_notes.tsv` records known identity problems, historical
exclusions, admixture flags, library redo/re-extraction flags, and sample-level
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
