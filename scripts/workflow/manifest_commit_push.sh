#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 \"commit message\"" >&2
    exit 2
fi
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
bash scripts/workflow/make_codex_manifest.sh
git add --all
git commit -m "$1"
git push
