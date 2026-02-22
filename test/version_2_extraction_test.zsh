#!/bin/zsh
#
# Test full extraction path using version_2.mp4: transcribe (whisper) then extract.
# Requires: whisper-cli, ffmpeg, version_2.mp4 in test/.
#

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"
scripts_dir="$root_dir/scripts"
video="$script_dir/version_2.mp4"

if [[ ! -f "$video" ]]; then
  echo "Skipping version_2 extraction test: $video not found (version_2.mp4 should be in test/)" >&2
  exit 0
fi

# Use a temp dir so we don't touch real Downloads
tmp_dir=$(mktemp -d /tmp/videosum.XXXXXX)
trap "rm -rf $tmp_dir" EXIT
cp "$video" "$tmp_dir/version_2.mp4"

# Run process_videos: transcript-only, extract enabled, only our temp dir
output=$("$root_dir/scripts/process_videos.zsh" -t -d "$tmp_dir" -a 24 2>&1) || true

# Should have extracted fitness-related content (heart rate, HRV, etc.)
lower="${output:l}"
if [[ "$lower" != *"heart rate"* && "$lower" != *"hrv"* ]]; then
  echo "Version_2 extraction test failed: expected fitness content in output" >&2
  echo "Output (first 500 chars): ${output:0:500}" >&2
  exit 2
fi

if [[ "$output" = *"(no transcript"* ]]; then
  echo "Version_2 extraction test failed: no transcript from video" >&2
  exit 3
fi

echo "Version_2 extraction test passed (version_2.mp4 → transcribe → extract)."
