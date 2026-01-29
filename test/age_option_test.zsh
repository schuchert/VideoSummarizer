#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

test_video="$script_dir/TestVideo.mp4"
downloads_dir="$HOME/Downloads"
processed_glob="$downloads_dir/processed/TestVideo*.*"
downloaded_file="$downloads_dir/TestVideo.mp4"

if [[ ! -f "$test_video" ]]; then
  echo "Missing test video: $test_video" >&2
  exit 1
fi

cp "$test_video" "$downloads_dir"

past_time=$(date -v-6H +"%Y%m%d%H%M")
touch -t "$past_time" "$downloaded_file"

output="$("$root_dir/process_videos.zsh" --age 1)"

rm -f $processed_glob || true

expected_header="#########################################################################"
expected_file="$downloads_dir/TestVideo.mp4"

if [[ "$output" == *"$expected_header"* ]] || [[ "$output" == *"$expected_file"* ]]; then
  echo "Age option test failed: file should be filtered out" >&2
  rm -f "$downloaded_file"
  exit 2
fi

if [[ ! -f "$downloaded_file" ]]; then
  echo "Age option test failed: source file was moved" >&2
  exit 3
fi

rm -f "$downloaded_file"

echo "Age option test passed."
