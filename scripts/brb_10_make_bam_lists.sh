#!/usr/bin/env bash
# Compatibility alias for the renumbered BAM-list stage.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/brb_07_make_bam_lists.sh" "$@"
