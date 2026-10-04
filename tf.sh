#!/usr/bin/env bash
# Run terraform with TMPDIR on persistent disk. The libvirt provider stages
# libvirt_cloudinit_disk ISOs under os.TempDir(), and /tmp is emptied at every boot.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TMPDIR="$here/.tmp"
mkdir -p "$TMPDIR"
chmod 700 "$TMPDIR"
exec terraform "$@"
