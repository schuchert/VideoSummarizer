#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

tmp_path=$(mktemp -d /tmp/path-test.XXXXXX)
jq_path=$(command -v jq || true)
curl_path=$(command -v curl || true)
gdate_path=$(command -v gdate || true)

if [[ -n "$jq_path" ]]; then
  ln -s "$jq_path" "$tmp_path/jq"
fi

if [[ -n "$curl_path" ]]; then
  ln -s "$curl_path" "$tmp_path/curl"
fi

if [[ -n "$gdate_path" ]]; then
  ln -s "$gdate_path" "$tmp_path/gdate"
fi

output=""
if output=$(PATH="$tmp_path" PERPLEXITY_API_KEY="dummy" /bin/bash "$root_dir/scripts/verify_dependencies.zsh" 2>&1); then
  rm -rf "$tmp_path"
  echo "Missing ffmpeg test failed: expected failure" >&2
  exit 1
fi

rm -rf "$tmp_path"

if [[ "$output" != *"Missing command: ffmpeg"* ]]; then
  echo "Missing ffmpeg test failed: missing error message" >&2
  exit 2
fi

echo "Missing ffmpeg test passed."
