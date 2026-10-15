#!/usr/bin/env python3
"""Build sample-to-BRB-barcode records for BAM splitting.

2024 uses the explicit historical sample/barcode table.  The 2025 sheet gives
the reaction-plate positions, so the 2025 barcode list is assigned in row-major
16 x 24 plate order.  That positional assumption is written to the output and
must be checked against the final demultiplexing records before production use.
"""

import csv
import argparse
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
META = ROOT / "metadata"
BRB = ROOT.parent / "2024_Gacu_BRBseq" / "metadata"


def norm_pos(value):
    value = (value or "").strip().upper()
    if not value:
        return ""
    row = value[0]
    try:
        col = int(value[1:])
    except ValueError:
        return value
    return f"{row}{col:02d}"


def plate_positions():
    return [f"{row}{col:02d}" for row in "ABCDEFGHIJKLMNOP" for col in range(1, 25)]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()
    rows = []

    with (BRB / "sample_barcodes_cat_nl.tsv").open(encoding="utf-8") as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            if len(fields) == 4:
                fields = fields[1:]
            if len(fields) == 3:
                rows.append({
                    "sample_id": fields[0],
                    "year": "2024",
                    "tissue": fields[1],
                    "barcode": fields[2],
                    "barcode_source": "2024_Gacu_BRBseq/metadata/sample_barcodes_cat_nl.tsv",
                    "mapping_note": "explicit historical sample-to-barcode map",
                })

    barcodes25 = [x.strip() for x in (META / "barcodes_2025.txt").read_text().splitlines() if x.strip()]
    barcode_by_pos = dict(zip(plate_positions(), barcodes25))
    source = META / "BC Spring 2025 Collections and Molecular Metadata Sheet 1.csv"
    with source.open(newline="", encoding="utf-8-sig") as handle:
        for record in csv.DictReader(handle):
            sample_id = (record.get("   ") or "").strip()
            if not sample_id:
                continue
            for tissue, flag, position_key in (
                ("gill", "do gill BRB prep?", "gill rxn plate pos"),
                ("liver", "do liver BRB prep?", "liver rxn plate pos"),
            ):
                if (record.get(flag) or "").strip() != "1":
                    continue
                position = norm_pos(record.get(position_key))
                barcode = barcode_by_pos.get(position, "")
                if not barcode:
                    # Keep the sample in the broader tracking metadata, but do
                    # not create an executable BRB row without a reaction
                    # position/barcode.
                    continue
                rows.append({
                    "sample_id": sample_id,
                    "year": "2025",
                    "tissue": tissue,
                    "barcode": barcode,
                    "barcode_source": "metadata/barcodes_2025.txt",
                    "mapping_note": f"reaction position {position}; positional map requires final-run verification",
                })

    rows.sort(key=lambda x: (x["year"], x["tissue"], x["sample_id"]))
    out = META / "brb_sample_barcodes.tsv"
    if args.check_only:
        if not out.exists():
            raise SystemExit(f"Missing manifest: {out}")
        return
    with out.open("w", newline="", encoding="utf-8") as handle:
        fields = ["sample_id", "year", "tissue", "barcode", "barcode_source", "mapping_note"]
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
