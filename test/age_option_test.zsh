#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

test_video="$script_dir/TestVideo.mp4"
temp_dir="$(mktemp -d /tmp/automatevideos.XXXXXX)"
trap 'rm -rf "$temp_dir"' EXIT
source_file="$temp_dir/TestVideo.mp4"

if [[ ! -f "$test_video" ]]; then
  echo "Missing test video: $test_video" >&2
  exit 1
fi

cp "$test_video" "$source_file"
past_time=$(gdate -d "6 hours ago" +"%Y%m%d%H%M")
touch -t "$past_time" "$source_file"

# PROCESS_VIDEOS_AGE_MTIME_ONLY=1 so only mtime is checked (copy gives recent birth/ctime).
output="$(PROCESS_VIDEOS_AGE_MTIME_ONLY=1 "$root_dir/scripts/process_videos.zsh" -d "$temp_dir" --age 1)"

expected_header="#########################################################################"
expected_file="$source_file"

if [[ "$output" == *"$expected_header"* ]] || [[ "$output" == *"$expected_file"* ]]; then
  echo "Age option test failed: file should be filtered out" >&2
  exit 2
fi

if [[ ! -f "$source_file" ]]; then
  echo "Age option test failed: source file was moved" >&2
  exit 3
fi

echo "Age option test passed."
