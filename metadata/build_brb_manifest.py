#!/usr/bin/env python3
"""Build sample-to-BRB-barcode records for BAM splitting.

Both years use the same positional logic: the collection metadata supplies a
reaction-plate position, and the version-specific position/barcode table
supplies the sequence at that position.  The barcode sets differ by kit
version: 2024 uses V5B and 2025 uses V5D.

The 2024 RNA extraction sheet is the authoritative source for executable
sample/tissue records.  Its V5B well/barcode assignments are validated against
the local V5B position table.
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
    barcode_by_pos_2025 = read_positioned_barcodes(
        META / "barcodes_v5D_384_brb.txt"
    )
    source_2024 = META / "2024_BC_RNA_extractions.csv"
    with source_2024.open(newline="", encoding="utf-8-sig") as handle:
        for record in csv.DictReader(handle):
            if (record.get("use?") or "").strip() != "1":
                continue
            if (record.get("in final pool?") or "").strip() != "1":
                continue
            source_sample_id = (record.get("sample") or "").strip()
            sample_id = source_sample_id
            # The RNA sheet labels five replacement liver records with a
            # `_2` suffix; the established WGS/BRB identity is the
            # unsuffixed DJR ID. Preserve that canonical identity here.
            if sample_id.endswith("_2"):
                sample_id = sample_id[:-2]
            tissue = (record.get("tissue") or "").strip().lower()
            if not sample_id or tissue not in {"gill", "liver"}:
                continue
            position = norm_pos(record.get("V5B well"))
            barcode = barcode_by_pos_2024.get(position, "")
            reported_barcode = (record.get("V5B barcode") or "").strip().upper()
            if not barcode:
                raise SystemExit(
                    f"2024 RNA record for {sample_id} {tissue} has no V5B position: {position!r}"
                )
            if reported_barcode and reported_barcode != barcode:
                raise SystemExit(
                    f"2024 V5B mismatch for {sample_id} {tissue} at {position}: "
                    f"RNA sheet has {reported_barcode}, positioned table has {barcode}"
                )
            rows.append({
                "sample_id": sample_id,
                "year": "2024",
                "tissue": tissue,
                "barcode": barcode,
                "barcode_source": "2024_Gacu_BRBseq/metadata/2024_BC_RNA_extractions.csv + metadata/barcodes_v5B_384_brb.txt",
                "mapping_note": (
                    f"V5B well {position}; RNA extraction metadata; "
                    "validated against V5B position map"
                    + (f"; source ID {source_sample_id} normalized to {sample_id}"
                       if source_sample_id != sample_id else "")
                ),
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
