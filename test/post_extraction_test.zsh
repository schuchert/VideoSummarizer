#!/bin/zsh
#
# Test everything past extraction using foo.srt:
#   1. reduce_srt_for_summary.zsh produces timestamped text
#   2. If PERPLEXITY_API_KEY is set, youtube_title_summary.zsh gets that text and returns a title/summary
#

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"
scripts_dir="$root_dir/scripts"

srt_file="$script_dir/foo.srt"
reduce_script="$scripts_dir/reduce_srt_for_summary.zsh"
summary_script="$scripts_dir/youtube_title_summary.zsh"

if [[ ! -f "$srt_file" ]]; then
  echo "Missing $srt_file (foo.srt should be in test/)" >&2
  exit 1
fi

if [[ ! -x "$reduce_script" ]]; then
  echo "Missing or not executable: $reduce_script" >&2
  exit 1
fi

# --- 1. Reduce SRT: should output [HH:MM:SS] and transcript text ---
reduced=$("$reduce_script" "$srt_file")

if [[ -z "${reduced//[[:space:]]/}" ]]; then
  echo "Post-extraction test failed: reduce_srt produced no output" >&2
  exit 2
fi

if [[ "$reduced" != *"[00:00:"* ]]; then
  echo "Post-extraction test failed: expected [HH:MM:SS] timestamps in output" >&2
  exit 3
fi

# Content from foo.srt should appear
lower="${reduced:l}"
if [[ "$lower" != *"heart rate"* ]]; then
  echo "Post-extraction test failed: expected transcript text in reduced output" >&2
  exit 4
fi

# --- 2. Summary (only if API key set): feed reduced text, expect title/summary, not "paste the transcript" ---
if [[ -n "${PERPLEXITY_API_KEY:-}" && -x "$summary_script" ]]; then
  summary=$(printf '%s\n' "$reduced" | "$summary_script" 2>/dev/null) || summary=""
  if [[ -n "${summary//[[:space:]]/}" ]]; then
    if [[ "$summary" = *"haven't provided"* || "$summary" = *"paste the transcript"* ]]; then
      echo "Post-extraction test failed: summary script asked for transcript (input may be wrong)" >&2
      exit 5
    fi
    # Looks good: we got a real summary
  fi
else
  # No API key or no script: skip summary step
  :
fi

echo "Post-extraction test passed (foo.srt → reduce_srt → optional summary)."
