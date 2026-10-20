#!/usr/bin/env python3
"""Build sample-to-BRB-barcode records for BAM splitting.

Both years use the same positional logic: the collection metadata supplies a
reaction-plate position, and the version-specific position/barcode table
supplies the sequence at that position.  The barcode sets differ by kit
version: 2024 uses V5B and 2025 uses V5D.

The historical 2024 sample table is retained as the authoritative source for
which sample/tissue records were executable, including its historical sample
IDs.  Its barcode assignments are validated against the V5B position table.
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


def read_positioned_barcodes(path):
    """Read a two-column plate-position/barcode table and validate it."""
    mapping = {}
    with path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if reader.fieldnames != ["Name", "B1"]:
            raise SystemExit(
                f"Unexpected barcode-table header in {path}: {reader.fieldnames}"
            )
        for record in reader:
            position = norm_pos(record.get("Name"))
            barcode = (record.get("B1") or "").strip().upper()
            if not position or not barcode:
                continue
            if position in mapping:
                raise SystemExit(f"Duplicate barcode position {position} in {path}")
            mapping[position] = barcode

    if len(mapping) != 384 or len(set(mapping.values())) != 384:
        raise SystemExit(
            f"Expected 384 unique positioned barcodes in {path}; "
            f"found {len(mapping)} positions and {len(set(mapping.values()))} sequences"
        )
    return mapping


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()
    out = META / "brb_sample_barcodes.tsv"
    if args.check_only:
        if not out.exists():
            raise SystemExit(f"Missing manifest: {out}")
        return
    rows = []

    barcode_by_pos_2024 = read_positioned_barcodes(
        META / "barcodes_v5B_384_brb.txt"
    )
    pos_by_barcode_2024 = {
        barcode: position for position, barcode in barcode_by_pos_2024.items()
    }
    barcode_by_pos_2025 = read_positioned_barcodes(
        META / "barcodes_v5D_384_brb.txt"
    )
    with (BRB / "sample_barcodes_cat_nl.tsv").open(encoding="utf-8") as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            if len(fields) == 4:
                fields = fields[1:]
            if len(fields) == 3:
                historical_barcode = fields[2].strip().upper()
                position = pos_by_barcode_2024.get(historical_barcode)
                if not position:
                    raise SystemExit(
                        f"2024 barcode {historical_barcode} for {fields[0]} is absent from the V5B table"
                    )
                barcode = barcode_by_pos_2024[position]
                if barcode != historical_barcode:
                    raise SystemExit(
                        f"2024 V5B mismatch at {position}: historical map has "
                        f"{historical_barcode}, positioned table has {barcode}"
                    )
                rows.append({
                    "sample_id": fields[0],
                    "year": "2024",
                    "tissue": fields[1],
                    "barcode": barcode,
                    "barcode_source": "metadata/barcodes_v5B_384_brb.txt",
                    "mapping_note": f"reaction position {position}; validated against historical sample map",
                })

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
                barcode = barcode_by_pos_2025.get(position, "")
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
                    "barcode_source": "metadata/barcodes_v5D_384_brb.txt",
                    "mapping_note": f"reaction position {position}; direct V5D position-to-barcode map",
                })

    rows.sort(key=lambda x: (x["year"], x["tissue"], x["sample_id"]))
    with out.open("w", newline="", encoding="utf-8") as handle:
        fields = ["sample_id", "year", "tissue", "barcode", "barcode_source", "mapping_note"]
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
