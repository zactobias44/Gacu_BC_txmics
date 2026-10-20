# BRB-seq pooling records

These files record the final liquid-handler pooling inputs. They are the
authoritative record of which reaction-plate positions were actually carried
into the sequencing pools; a reaction position in the molecular metadata or
barcode manifest does not by itself prove that the sample was pooled.

## 2025 gill

`2025_gill_pooling.csv` contains 255 positions. The following prepared gill
positions are intentionally absent from the final pooling configuration:

| Sample | Reaction position | Reason documented during shallow sequencing |
|---|---|---|
| `2025_DJR_246` | D10 | Missing from the RNA archive; removed manually |
| `2025_DJR_413` | F15 | Shallow mapped reads below the 450-read pooling cutoff |
| `2025_DJR_415` | F17 | Shallow mapped reads below the 450-read pooling cutoff |
| `2025_DJR_416` | F18 | Shallow mapped reads below the 450-read pooling cutoff |
| `2025_DJR_419` | F21 | Shallow mapped reads below the 450-read pooling cutoff |
| `2025_DJR_421` | F23 | Shallow mapped reads below the 450-read pooling cutoff |
| `2025_DJR_423` | H13 | Shallow mapped reads below the 450-read pooling cutoff |

These samples may still appear as barcode columns in STAR matrices because
the barcode whitelist represents the available barcode space. Their tiny
counts should be treated as background and excluded from expression analyses,
not as evidence that a usable library was sequenced.

The generated `brb_sample_barcodes.tsv` manifest uses this file as the final
gill inclusion gate, so new split-BAM arrays contain 255 2025 gill records and
do not allocate tasks for these seven samples.

## 2025 liver

The final liver pooling records are retained in:

- `2025_liver_pool_final.csv`
- `liver_final_pooling.csv`

Use the liquid-handler records together with the liver reaction-position and
barcode metadata when determining final inclusion. Do not infer inclusion
solely from `do liver BRB prep?`.
