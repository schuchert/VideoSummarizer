#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

test_files=($(find "$script_dir" -maxdepth 1 -name "*_test.zsh" -type f | sort))

if [[ ${#test_files[@]} -eq 0 ]]; then
  echo "No tests found in $script_dir"
  exit 1
fi

failures=0

for test_file in "${test_files[@]}"; do
  echo "Running: $test_file"
  if "$test_file"; then
    echo "PASS: $test_file"
  else
    echo "FAIL: $test_file"
    failures=$((failures + 1))
  fi
  echo ""
done

if [[ $failures -gt 0 ]]; then
  echo "Tests failed: $failures"
  exit 2
fi

echo "All tests passed."
