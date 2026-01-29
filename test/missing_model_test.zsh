#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

tmp_dir=$(mktemp -d /tmp/whisper-test.XXXXXX)
mkdir -p "$tmp_dir/build/bin"
touch "$tmp_dir/build/bin/whisper-cli"
chmod +x "$tmp_dir/build/bin/whisper-cli"

output=""
if output=$(WHISPER="$tmp_dir" PERPLEXITY_API_KEY="dummy" "$root_dir/scripts/verify_dependencies.zsh" 2>&1); then
  rm -rf "$tmp_dir"
  echo "Missing model test failed: expected failure" >&2
  exit 1
fi

rm -rf "$tmp_dir"

if [[ "$output" != *"Missing model file"* ]]; then
  echo "Missing model test failed: missing error message" >&2
  exit 2
fi

echo "Missing model test passed."
