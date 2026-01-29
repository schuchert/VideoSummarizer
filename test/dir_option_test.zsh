#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

test_video="$script_dir/TestVideo.mp4"
temp_dir="$(mktemp -d /tmp/automatevideos.XXXXXX)"
processed_dir="$temp_dir/processed"
source_file="$temp_dir/TestVideo.mp4"

if [[ ! -f "$test_video" ]]; then
  echo "Missing test video: $test_video" >&2
  exit 1
fi

cp "$test_video" "$source_file"

output="$("$root_dir/process_videos.zsh" --dir "$temp_dir")"

expected_header="#########################################################################"
expected_file="$source_file"

if [[ "$output" != *"$expected_header"* ]]; then
  echo "Dir option test failed: missing header" >&2
  rm -rf "$temp_dir"
  exit 2
fi

if [[ "$output" != *"$expected_file"* ]]; then
  echo "Dir option test failed: missing file path" >&2
  rm -rf "$temp_dir"
  exit 3
fi

processed_file=$(find "$processed_dir" -maxdepth 1 -name "TestVideo*" -type f -print -quit 2>/dev/null || true)
if [[ ! -d "$processed_dir" ]] || [[ -z "$processed_file" ]]; then
  echo "Dir option test failed: processed file missing" >&2
  rm -rf "$temp_dir"
  exit 4
fi

rm -rf "$temp_dir"

echo "Dir option test passed."
