#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

test_video="$script_dir/TestVideo.mp4"
downloads_dir="$HOME/Downloads"
processed_glob="$downloads_dir/processed/TestVideo*.*"

if [[ ! -f "$test_video" ]]; then
  echo "Missing test video: $test_video" >&2
  exit 1
fi

cp "$test_video" "$downloads_dir"

output="$("$root_dir/process_videos.zsh")"

rm -f $processed_glob || true

expected_header="#########################################################################"
expected_file="$downloads_dir/TestVideo.mp4"

if [[ "$output" != *"$expected_header"* ]]; then
  echo "Smoke test failed: missing header" >&2
  exit 2
fi

if [[ "$output" != *"$expected_file"* ]]; then
  echo "Smoke test failed: missing file path" >&2
  exit 3
fi

lower_output="${output:l}"
if [[ "$lower_output" != *"this is going to stimulate"* ]]; then
  echo "Smoke test failed: missing transcript snippet" >&2
  exit 4
fi

if ! [[ "$output" =~ $'\n\n[^\n]+\n\n[^\n]+' ]]; then
  echo "Smoke test failed: missing summary structure" >&2
  exit 5
fi

echo "Smoke test passed."
