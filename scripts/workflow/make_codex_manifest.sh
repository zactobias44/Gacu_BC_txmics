#!/usr/bin/env bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
out_dir="$repo_root/.codex_manifest"
out_file="$out_dir/repo_manifest.tsv"
scratch_root="/vortexfs1/scratch/ztobias/Gaculeatus/Gacu_BC_txmics"
mkdir -p "$out_dir"

if find "$repo_root" -maxdepth 0 -printf '' >/dev/null 2>&1; then
    find "$repo_root" \( -path "$repo_root/.git" -o -path "$out_dir" -o \
        -path "$repo_root/reads" -o -path "$repo_root/logs" -o -path "$repo_root/software" -o \
        -path "$repo_root/work" -o -path "$repo_root/.ipynb_checkpoints" \) -prune -o \
        -printf '%y\t%s\t%TY-%Tm-%Td %TH:%TM:%TS\t%p\n' | \
        sed "s#${repo_root}/#./#g; s#\\\\t#\t#g" > "$out_file.tmp"
else
    find "$repo_root" -not -path "$repo_root/.git*" -not -path "$out_dir*" \
        -exec stat -f '%HT\t%z\t%Sm\t%N' -t '%Y-%m-%d %H:%M:%S' {} \; > "$out_file.tmp"
fi

{
    printf 'kind\tsize_bytes\tmodified\tpath\n'
    cat "$out_file.tmp"
    if [[ -d "$scratch_root" && "$scratch_root" != "$repo_root" ]]; then
        find "$scratch_root" \( -path "$scratch_root/reads" -o -path "$scratch_root/logs" -o \
            -path "$scratch_root/split_bams" -o -path "$scratch_root/variants" -o \
            -path "$scratch_root/star" \) -prune -o \
            -printf '%y\t%s\t%TY-%Tm-%Td %TH:%TM:%TS\t%p\n' 2>/dev/null || true
    fi
} > "$out_file"
rm -f "$out_file.tmp"

{
    printf 'Generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf 'Repo root: %s\n' "$repo_root"
    printf 'Scratch root: %s\n' "$scratch_root"
    printf 'Git branch: %s\n' "$(git -C "$repo_root" branch --show-current 2>/dev/null || true)"
    printf 'Git HEAD: %s\n\n' "$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || true)"
    printf 'Lightweight path manifest only; file contents are not copied.\n'
} > "$out_dir/README.txt"
git -C "$repo_root" status --short --ignored=matching > "$out_dir/git_status.txt" 2>/dev/null || true
echo "Wrote $out_file"
