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
    tracking = {}
    tracking_path = root / "metadata" / "derived" / "sample_tracking.tsv"
    if tracking_path.exists():
        with tracking_path.open(newline="", encoding="utf-8") as handle:
            for record in csv.DictReader(handle, delimiter="\t"):
                tracking[(record.get("sample_id", "").strip(), record.get("year", "").strip())] = record

    def classification(sample, year):
        record = tracking.get((sample, year), {})
        return {
            "population": record.get("population", ""),
            "site_type": record.get("site_type", ""),
            "site_type_source": record.get("site_type_source", ""),
            "site_name": record.get("site_name", ""),
            "ecotype": record.get("ecotype", ""),
            "field_population": record.get("field_population", ""),
            "field_ecotype": record.get("field_ecotype", ""),
            "dna_population": record.get("dna_population", ""),
            "dna_ecotype": record.get("dna_ecotype", ""),
            "rna_population": record.get("rna_population", ""),
            "rna_ecotype": record.get("rna_ecotype", ""),
            "source_system": record.get("source_system", ""),
        }

    with args.wgs_metadata.open(newline="", encoding="utf-8") as handle:
        for record in csv.DictReader(handle, delimiter="\t"):
            sample = (record.get("Sequence_ID") or "").strip()
            if not sample.startswith(("2024_DJR", "2025_DJR")):
                continue
            year = sample[:4]
            row = {
                    "analysis_id": f"{sample}_D",
                    "original_id": sample,
                    "source": "WGS",
                    "tissue": "DNA",
                    "year": year,
                    "barcode": "",
                    "source_record": wgs_source_label,
                    "mapping_note": "expanded WGS DJR reference sample",
                }
            row.update(classification(sample, year))
            rows.append(row)

    with args.brb_manifest.open(newline="", encoding="utf-8") as handle:
        for record in csv.DictReader(handle, delimiter="\t"):
            sample = record["sample_id"].strip()
            tissue = record["tissue"].strip()
            suffix = {"gill": "G", "liver": "L"}[tissue]
            row = {
                    "analysis_id": f"{sample}_{suffix}",
                    "original_id": sample,
                    "source": "BRB",
                    "tissue": tissue,
                    "year": record["year"].strip(),
                    "barcode": record["barcode"].strip(),
                    "source_record": record["barcode_source"].strip(),
                    "mapping_note": record["mapping_note"].strip(),
                }
            row.update(classification(sample, record["year"].strip()))
            rows.append(row)

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
        "population",
        "site_type",
        "site_type_source",
        "site_name",
        "ecotype",
        "field_population",
        "field_ecotype",
        "dna_population",
        "dna_ecotype",
        "rna_population",
        "rna_ecotype",
        "source_system",
    ]
    with args.output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} rows to {args.output}")


if __name__ == "__main__":
    main()
