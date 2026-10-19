#!/usr/bin/env python3
"""Build the canonical individual-level sample tracking table.

This intentionally keeps source facts separate from analysis decisions.  The
generated table is a starting point for pipeline manifests; final sequencing
QC can add or change analysis flags without rewriting the source spreadsheets.
"""

from collections import defaultdict
import csv
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
META = ROOT / "metadata"
OUT = META / "derived"
BRB = ROOT.parent / "2024_Gacu_BRBseq"
MRNA = ROOT.parent / "2024_Gacu_mRNAseq"


def read_csv(path):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def clean(value):
    return (value or "").strip()


def add_unique(values, value):
    value = clean(value)
    if value and value not in values:
        values.append(value)


def write_tsv(path, rows, fields):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t", extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def main():
    records = {}
    notes = []

    def record(sample_id, year):
        key = (sample_id, year)
        if key not in records:
            records[key] = {
                "sample_id": sample_id,
                "year": str(year),
                "population": "",
                "site_type": "",
                "site_type_source": "",
                "site_name": "",
                "ecotype": "",
                "field_population": "",
                "field_ecotype": "",
                "dna_population": "",
                "dna_ecotype": "",
                "rna_population": "",
                "rna_ecotype": "",
                "source_system": "",
                "field_sex": "",
                "dna_sex": "",
                "true_sex": "",
                "brb_gill_status": "not_recorded",
                "brb_liver_status": "not_recorded",
                "mrna_gill_status": "not_recorded",
                "mrna_liver_status": "not_recorded",
                "wgs_status": "not_recorded",
                "brb_gill_runs": "",
                "brb_liver_runs": "",
                "dna_pool_ids": "",
                "library_or_well_ids": "",
                "issue_ids": "",
                "recommended_action": "",
                "source_records": "",
            }
        return records[key]

    def note(sample_id, year, tissue, issue_type, severity, text, action, evidence):
        notes.append({
            "sample_id": sample_id,
            "year": str(year),
            "tissue": tissue,
            "issue_type": issue_type,
            "severity": severity,
            "note": text,
            "recommended_action": action,
            "evidence": evidence,
        })
        if sample_id:
            rec = record(sample_id, year)
            ids = [x for x in rec["issue_ids"].split(";") if x]
            issue_id = f"{issue_type}:{tissue}" if tissue else issue_type
            add_unique(ids, issue_id)
            rec["issue_ids"] = ";".join(ids)

    # 2024 field/DNA/RNA metadata.
    dna24 = read_csv(META / "2024_BC_DNA_extractions.csv")
    for row in dna24:
        sid = clean(row.get("sample"))
        if not re.fullmatch(r"2024_DJR_\d{3}", sid):
            continue
        rec = record(sid, 2024)
        rec["population"] = clean(row.get("population"))
        rec["dna_population"] = clean(row.get("population"))
        rec["ecotype"] = clean(row.get("ecotype"))
        rec["dna_ecotype"] = clean(row.get("ecotype"))
        rec["source_system"] = clean(row.get("system"))
        rec["dna_sex"] = clean(row.get("sex"))
        rec["wgs_status"] = "sequenced" if clean(row.get("sequenced?")) == "1" else "not_sequenced"
        add_unique([rec["source_records"]], "2024_BC_DNA_extractions.csv")
        rec["source_records"] = ";".join(dict.fromkeys([x for x in [rec["source_records"], "2024_BC_DNA_extractions.csv"] if x]))
        if clean(row.get("extr notes")):
            note(sid, 2024, "DNA", "dna_note", "review", clean(row["extr notes"]), "Review before WGS linkage.", "2024_BC_DNA_extractions.csv")

    field24 = read_csv(BRB / "metadata" / "sample_list_2024.csv")
    for row in field24:
        sid = clean(row.get("id"))
        if not sid:
            continue
        rec = record(sid, 2024)
        rec["field_population"] = clean(row.get("lake"))
        rec["field_ecotype"] = clean(row.get("ecotype"))
        rec["population"] = rec["population"] or clean(row.get("lake"))
        rec["site_name"] = rec["site_name"] or clean(row.get("lake"))
        if not rec["site_type"]:
            ecotype = rec["ecotype"] or clean(row.get("ecotype"))
            if ecotype in {"benthic", "limnetic", "lake"}:
                rec["site_type"] = "lake"
                rec["site_type_source"] = "inferred from 2024 ecotype"
            elif ecotype == "marine":
                rec["site_type"] = "marine"
                rec["site_type_source"] = "inferred from 2024 ecotype"
        rec["ecotype"] = rec["ecotype"] or clean(row.get("ecotype"))
        rec["field_sex"] = clean(row.get("sex"))
        add_unique([rec["source_records"]], "sample_list_2024.csv")
        rec["source_records"] = ";".join(dict.fromkeys([x for x in [rec["source_records"], "sample_list_2024.csv"] if x]))

    rna24 = read_csv(BRB / "metadata" / "2024_BC_RNA_extractions.csv")
    for row in rna24:
        sid = clean(row.get("sample"))
        if not sid:
            continue
        tissue = clean(row.get("tissue")).lower()
        rec = record(sid, 2024)
        rec["population"] = rec["population"] or clean(row.get("population"))
        rec["ecotype"] = rec["ecotype"] or clean(row.get("ecotype"))
        rec["rna_population"] = clean(row.get("population"))
        rec["rna_ecotype"] = clean(row.get("ecotype"))
        rec["source_system"] = rec["source_system"] or clean(row.get("system"))
        rec["site_name"] = rec["site_name"] or clean(row.get("population"))
        rec["field_sex"] = rec["field_sex"] or clean(row.get("sex"))
        rec["source_records"] = ";".join(dict.fromkeys([x for x in [rec["source_records"], "2024_BC_RNA_extractions.csv"] if x]))
        if tissue == "gill":
            rec["brb_gill_status"] = "usable" if clean(row.get("use?")) == "1" else "excluded_source"
        elif tissue == "liver":
            rec["brb_liver_status"] = "usable" if clean(row.get("use?")) == "1" else "excluded_source"
        add_unique([rec["library_or_well_ids"]], f"{tissue}:{clean(row.get('V5B well'))}")
        rec["library_or_well_ids"] = ";".join(dict.fromkeys([x for x in [rec["library_or_well_ids"], f"{tissue}:{clean(row.get('V5B well'))}"] if x and not x.endswith(":")]))
        run = "AVT0249" if tissue == "gill" else "AVT0349"
        run_field = "brb_gill_runs" if tissue == "gill" else "brb_liver_runs"
        rec[run_field] = ";".join(dict.fromkeys([x for x in [rec[run_field], run] if x]))
        if clean(row.get("use?")) == "0":
            note(sid, 2024, tissue, "brb_source_exclusion", "high", "RNA extraction record is marked unusable.", "Exclude from BRBseq unless an explicit replacement exists.", "2024_BC_RNA_extractions.csv")

    mrna_ids = {line.strip() for line in (MRNA / "metadata" / "samps").read_text().splitlines() if line.strip()}
    for sid in mrna_ids:
        rec = record(sid, 2024)
        rec["mrna_gill_status"] = "available"
        rec["mrna_liver_status"] = "available"
        add_unique([rec["source_records"]], "2024_Gacu_mRNAseq/metadata/samps")
        rec["source_records"] = ";".join(dict.fromkeys([x for x in [rec["source_records"], "2024_Gacu_mRNAseq/metadata/samps"] if x]))

    # Parse the tab-separated sex table directly.
    with (BRB / "metadata" / "genetic_sexes.tsv").open(encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            sid = clean(row.get("ID"))
            if sid:
                rec = record(sid, 2024)
                rec["true_sex"] = clean(row.get("true sex"))

    # 2025 collection, DNA, RNA, and BRB preparation sheet.
    rows25 = read_csv(META / "BC Spring 2025 Collections and Molecular Metadata Sheet 1.csv")
    for row in rows25:
        sid = clean(row.get("   "))
        if not sid:
            continue
        rec = record(sid, 2025)
        rec["population"] = clean(row.get("Pair Name"))
        rec["site_type"] = clean(row.get("Site Type"))
        rec["site_type_source"] = "2025 Site Type column"
        rec["site_name"] = clean(row.get("Site Name"))
        rec["source_system"] = "2025_collection_metadata"
        rec["field_sex"] = clean(row.get("Sex"))
        rec["source_records"] = "BC Spring 2025 Collections and Molecular Metadata Sheet 1.csv"
        if clean(row.get("do liver BRB prep?")) == "1":
            rec["brb_liver_status"] = "prepared"
        if clean(row.get("do gill BRB prep?")) == "1":
            rec["brb_gill_status"] = "prepared"
        if clean(row.get("Use")) == "X":
            rec["wgs_status"] = "used"
        elif clean(row.get("Drop")) == "X":
            rec["wgs_status"] = "dropped"
        elif clean(row.get("Prep Plate #")):
            rec["wgs_status"] = "library_prepped"
        gill_runs = []
        liver_runs = []
        if clean(row.get("do gill BRB prep?")) == "1":
            gill_runs.extend(["AVT0483", "AVT0512"])
        if clean(row.get("do liver BRB prep?")) == "1":
            liver_runs.extend(["AVT0502", "AVT0512"])
        rec["brb_gill_runs"] = ";".join(dict.fromkeys([x for x in [rec["brb_gill_runs"], *gill_runs] if x]))
        rec["brb_liver_runs"] = ";".join(dict.fromkeys([x for x in [rec["brb_liver_runs"], *liver_runs] if x]))
        positions = []
        if clean(row.get("gill rxn plate pos")):
            positions.append(f"gill:{clean(row.get('gill rxn plate pos'))}")
        if clean(row.get("liver rxn plate pos")):
            positions.append(f"liver:{clean(row.get('liver rxn plate pos'))}")
        rec["library_or_well_ids"] = ";".join(dict.fromkeys([x for x in [rec["library_or_well_ids"], *positions] if x]))
        for key in ("pool ID",):
            add_unique([rec["dna_pool_ids"]], clean(row.get(key)))
        rec["dna_pool_ids"] = ";".join(dict.fromkeys([x for x in [rec["dna_pool_ids"], clean(row.get("pool ID"))] if x]))
        for tissue, flag, notes_key in (("liver", "do liver BRB prep?", "liver BRB notes"), ("gill", "do gill BRB prep?", "RNA notes")):
            text = clean(row.get(notes_key))
            if text and text not in {"ZT", "KB", "MF,ZT", "ZT, MF"}:
                note(sid, 2025, tissue, "molecular_note", "review", text, "Review before final inclusion and sample-level QC.", "BC Spring 2025 Collections and Molecular Metadata Sheet 1.csv")
        if clean(row.get("Drop")) == "X":
            note(sid, 2025, "DNA", "wgs_drop", "high", "2025 metadata marks this sample Drop = X.", "Exclude from WGS-derived QC unless manually overridden.", "BC Spring 2025 Collections and Molecular Metadata Sheet 1.csv")
        if clean(row.get("Redo-library")) == "X":
            note(sid, 2025, "DNA", "library_redo", "review", "2025 metadata marks this sample for a redo library.", "Use the final library/run after confirming which record is current.", "BC Spring 2025 Collections and Molecular Metadata Sheet 1.csv")
        if clean(row.get("Re-extract")) == "X":
            note(sid, 2025, "DNA", "dna_reextract", "review", "2025 metadata marks this sample for DNA re-extraction.", "Link the final extraction to the sequencing record.", "BC Spring 2025 Collections and Molecular Metadata Sheet 1.csv")

    # Known 2024 cross-modality identity and analysis issues from notebooks.
    manual = [
        ("2024_DJR_041", "both", "identity_swap", "high", "041 and 042 were identified as swapped between DNA/body metadata and RNA/tissue labels; sex assignments disagree.", "Keep RNA labels for tissue expression, but use an explicit DNA-vs-RNA identity mapping for genotype checks.", "BRBseq check_BRB_WGS_match.ipynb; DESeq_BvL.ipynb"),
        ("2024_DJR_042", "both", "identity_swap", "high", "041 and 042 were identified as swapped between DNA/body metadata and RNA/tissue labels; sex assignments disagree.", "Keep RNA labels for tissue expression, but use an explicit DNA-vs-RNA identity mapping for genotype checks.", "BRBseq check_BRB_WGS_match.ipynb; DESeq_BvL.ipynb"),
        ("2024_DJR_103", "liver", "identity_chain", "high", "RNA/DNA matching was abnormal; notebook discussion indicates a more complex 101-104 liver mismatch rather than a simple confirmed pair swap.", "Do not silently relabel. Re-run identity matching with final liver RNA and WGS genotypes.", "BRBseq check_BRB_WGS_match.ipynb"),
        ("2024_DJR_104", "liver", "identity_chain", "high", "RNA/DNA matching was abnormal; notebook discussion indicates a more complex 101-104 liver mismatch rather than a simple confirmed pair swap.", "Do not silently relabel. Re-run identity matching with final liver RNA and WGS genotypes.", "BRBseq check_BRB_WGS_match.ipynb"),
        ("2024_DJR_101", "liver", "barcode_reassignment", "high", "Historical analysis manually reassigned liver barcodes through the 101-104 chain and removed 101 from that analysis.", "Verify raw V5B barcode mapping before using this sample.", "BRBseq DESeq_across_eco_quick.ipynb"),
        ("2024_DJR_102", "liver", "barcode_reassignment", "high", "Historical analysis manually reassigned liver barcodes through the 101-104 chain.", "Verify raw V5B barcode mapping before using this sample.", "BRBseq DESeq_across_eco_quick.ipynb"),
        ("2024_DJR_103", "liver", "barcode_reassignment", "high", "Historical analysis manually reassigned liver barcodes through the 101-104 chain.", "Verify raw V5B barcode mapping before using this sample.", "BRBseq DESeq_across_eco_quick.ipynb"),
        ("2024_DJR_104", "liver", "barcode_reassignment", "high", "Historical analysis manually reassigned liver barcodes through the 101-104 chain.", "Verify raw V5B barcode mapping before using this sample.", "BRBseq DESeq_across_eco_quick.ipynb"),
        ("2024_DJR_001", "liver", "expression_outlier", "review", "2024 liver expression was repeatedly identified as an outlier.", "Exclude from primary liver expression analysis unless re-evaluated with the new pipeline.", "BRBseq DESeq_BvL.ipynb; DESeq_across_eco_quick.ipynb"),
        ("2024_DJR_196", "both", "missing_or_unusable", "high", "The sample was assigned a barcode but missing from the RNA archive; DNA metadata also marks it not included.", "Exclude unless raw RNA data are located and identity is confirmed.", "BRBseq seq_stats.ipynb; 2024_BC_DNA_extractions.csv"),
    ]
    for item in manual:
        note(item[0], 2024, *item[1:])

    gill_admixed = ["2024_DJR_406", "2024_DJR_395", "2024_DJR_393", "2024_DJR_394", "2024_DJR_402", "2024_DJR_427"]
    for sid in gill_admixed:
        note(sid, 2024, "gill", "admixed_ancestry", "review", "Prior BRBseq analysis flagged this sample as admixed/high ancestry outlier.", "Exclude from population/ecotype contrasts unless ancestry handling is explicitly modeled; retain for QC.", "BRBseq DESeq_across_eco_quick.ipynb")

    liver_excluded = ["2024_DJR_203", "2024_DJR_094", "2024_DJR_105", "2024_DJR_045", "2024_DJR_084", "2024_DJR_109", "2024_DJR_122", "2024_DJR_039"]
    for sid in liver_excluded:
        note(sid, 2024, "liver", "historical_analysis_exclusion", "review", "Sample was excluded in a prior BRBseq differential-expression analysis.", "Keep available for pipeline QC, but exclude from the primary comparison until the exclusion is re-evaluated.", "BRBseq DESeq_across_eco_quick.ipynb")

    mrna_excluded = {
        "2024_DJR_105_L", "2024_DJR_107_L", "2024_DJR_037_L", "2024_DJR_097_L", "2024_DJR_117_G", "2024_DJR_401_L"
    }
    for library_id in sorted(mrna_excluded):
        sid, tissue_code = library_id.rsplit("_", 1)
        note(sid, 2024, "gill" if tissue_code == "G" else "liver", "mrna_splicing_exclusion", "review", "Listed in the conventional mRNAseq rMATS exclusion file.", "Exclude from primary mRNA splicing analysis unless the exclusion is re-evaluated.", "2024_Gacu_mRNAseq/metadata/rmats_exclude.txt")

    # Finalize action summaries after all notes have been added.
    by_sample = defaultdict(list)
    for item in notes:
        if item["sample_id"]:
            by_sample[(item["sample_id"], item["year"])].append(item)
    for key, rec in records.items():
        sample_notes = by_sample.get((key[0], str(key[1])), [])
        actions = []
        for item in sample_notes:
            add_unique(actions, item["recommended_action"])
        rec["recommended_action"] = " | ".join(actions)

    fields = list(next(iter(records.values())).keys())
    rows = [records[key] for key in sorted(records, key=lambda x: (x[1], x[0]))]
    write_tsv(OUT / "sample_tracking.tsv", rows, fields)
    note_fields = ["sample_id", "year", "tissue", "issue_type", "severity", "note", "recommended_action", "evidence"]
    write_tsv(OUT / "sample_tracking_notes.tsv", notes, note_fields)


if __name__ == "__main__":
    main()
