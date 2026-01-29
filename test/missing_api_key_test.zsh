#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

output=""
if output=$(PERPLEXITY_API_KEY= "$root_dir/verify_dependencies.zsh" 2>&1); then
  echo "Missing API key test failed: expected failure" >&2
  exit 1
fi

if [[ "$output" != *"PERPLEXITY_API_KEY is not set"* ]]; then
  echo "Missing API key test failed: missing error message" >&2
  exit 2
fi

echo "Missing API key test passed."
