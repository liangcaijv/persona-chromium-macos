#!/usr/bin/env bash
# Import the fingerprint patch set from pocchian/fingerprint-chromium-macos-x86_64
# at a pinned commit, byte-for-byte, and record provenance in SOURCE.md.
set -euo pipefail
SRC_REPO="pocchian/fingerprint-chromium-macos-x86_64"
SRC_SHA="${1:?usage: $0 <source-commit-sha>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/patches/extra/fingerprint"
FILES=(
  000-add-fingerprint-switches.patch
  001-disable-runtime.enable.patch
  002-user-agent-fingerprint.patch
  003-audio-fingerprint.patch
  005-hardware-concurrency-fingerprint.patch
  006-font-fingerprint.patch
  007-shadow-root.patch
  009-webdriver.patch
  010-headless.patch
  011-gpu-info.patch
  012-canvas-get-image-data.patch
  013-canvas-toDataURL.patch
  014-client-rects.patch
  015-canvas-measure-text.patch
  016-webgl-readPixels.patch
  018-timezone.patch
)
mkdir -p "$DEST"
{
  echo "# Fingerprint patch provenance"
  echo
  echo "- Source repository: https://github.com/$SRC_REPO"
  echo "- Source commit: $SRC_SHA"
  echo "- License: BSD-3-Clause (see the source repository's LICENSE); patches copied byte-for-byte."
  echo "- Origin of the patch ideas: https://github.com/adryfish/fingerprint-chromium (BSD-3-Clause)."
  echo "- The three *.delta.patch files in the source repository are review artifacts already folded into the numbered patches and are intentionally not imported."
  echo
  echo "| file | sha256 |"
  echo "|---|---|"
} > "$DEST/SOURCE.md"
for f in "${FILES[@]}"; do
  gh api "repos/$SRC_REPO/contents/patches/extra/fingerprint/$f?ref=$SRC_SHA" --jq '.content' | base64 -d > "$DEST/$f"
  [[ -s "$DEST/$f" ]] || { echo "empty download: $f" >&2; exit 1; }
  echo "| $f | $(shasum -a 256 "$DEST/$f" | cut -d' ' -f1) |" >> "$DEST/SOURCE.md"
done
echo "imported ${#FILES[@]} patches at $SRC_SHA"
