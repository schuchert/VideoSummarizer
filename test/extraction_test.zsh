#!/bin/zsh
#
# Test extraction (extract_fitness_snippets.zsh) using transcript from version_2.mp4.
# Uses foo.srt as the transcript source (same content as version_2) so we don't need whisper.
#

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"
scripts_dir="$root_dir/scripts"

# Plain text transcript from foo.srt (same as version_2.mp4 content); assets live in test/
srt_file="$script_dir/foo.srt"
extract_script="$scripts_dir/extract_fitness_snippets.zsh"

if [[ ! -f "$srt_file" ]]; then
  echo "Missing $srt_file (foo.srt should be in test/)" >&2
  exit 1
fi

if [[ ! -x "$extract_script" ]]; then
  echo "Missing or not executable: $extract_script" >&2
  exit 1
fi

# Build transcript: SRT text lines only (skip sequence numbers and timestamp lines)
transcript=$(awk '
  / --> / { next }
  /^[0-9]+$/ { next }
  NF { print }
' "$srt_file" | tr '\n' ' ')

if [[ -z "${transcript//[[:space:]]/}" ]]; then
  echo "Could not extract transcript from $srt_file" >&2
  exit 1
fi

# Run extraction (same as process_videos does)
extracted=$(printf '%s\n' "$transcript" | "$extract_script") || true

# version_2/foo content has "heart rate", "heart rate variability", "HRV", "mental boost", "cardio", "sleep"
if [[ -z "${extracted//[[:space:]]/}" ]]; then
  echo "Extraction test failed: extract produced no output" >&2
  exit 2
fi

lower="${extracted:l}"
if [[ "$lower" != *"heart rate"* && "$lower" != *"hrv"* ]]; then
  echo "Extraction test failed: expected fitness-related content (heart rate / HRV), got none" >&2
  exit 3
fi

echo "Extraction test passed (version_2/foo transcript → extract_fitness_snippets.zsh)."
