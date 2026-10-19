#!/usr/bin/env python3
"""Build stable WGS/BRB sample IDs for tissue-specific relatedness QC."""

import argparse
import csv
from pathlib import Path


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--wgs-metadata",
        type=Path,
        default=root.parent / "BC_stickle_expanded_WGS" / "metadata" / "expanded_VCF_sample_info_corrected.tsv",
    )
    parser.add_argument(
        "--brb-manifest",
        type=Path,
        default=root / "metadata" / "brb_sample_barcodes.tsv",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=root / "metadata" / "derived" / "sample_source_mapping.tsv",
    )
    args = parser.parse_args()
    wgs_source_label = "BC_stickle_expanded_WGS/metadata/expanded_VCF_sample_info_corrected.tsv"
    if args.wgs_metadata != root.parent / "BC_stickle_expanded_WGS" / "metadata" / "expanded_VCF_sample_info_corrected.tsv":
        wgs_source_label = str(args.wgs_metadata)

    rows = []
    with args.wgs_metadata.open(newline="", encoding="utf-8") as handle:
        for record in csv.DictReader(handle, delimiter="\t"):
            sample = (record.get("Sequence_ID") or "").strip()
            if not sample.startswith(("2024_DJR", "2025_DJR")):
                continue
            year = sample[:4]
            rows.append(
                {
                    "analysis_id": f"{sample}_D",
                    "original_id": sample,
                    "source": "WGS",
                    "tissue": "DNA",
                    "year": year,
                    "barcode": "",
                    "source_record": wgs_source_label,
                    "mapping_note": "expanded WGS DJR reference sample",
                }
            )

    with args.brb_manifest.open(newline="", encoding="utf-8") as handle:
        for record in csv.DictReader(handle, delimiter="\t"):
            sample = record["sample_id"].strip()
            tissue = record["tissue"].strip()
            suffix = {"gill": "G", "liver": "L"}[tissue]
            rows.append(
                {
                    "analysis_id": f"{sample}_{suffix}",
                    "original_id": sample,
                    "source": "BRB",
                    "tissue": tissue,
                    "year": record["year"].strip(),
                    "barcode": record["barcode"].strip(),
                    "source_record": record["barcode_source"].strip(),
                    "mapping_note": record["mapping_note"].strip(),
                }
            )

    rows.sort(key=lambda row: (row["original_id"], row["source"], row["tissue"]))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "analysis_id",
        "original_id",
        "source",
        "tissue",
        "year",
        "barcode",
        "source_record",
        "mapping_note",
    ]
    with args.output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} rows to {args.output}")


if __name__ == "__main__":
    main()
