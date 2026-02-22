#!/usr/bin/env zsh
#
# Read SRT from stdin (or file args), merge short cues into larger chunks,
# and output full text with sparse timestamps suitable for sending to Perplexity.
#
# Usage: reduce_srt_for_summary.zsh [-s SECONDS] [file.srt ...]
#        cat file.srt | reduce_srt_for_summary.zsh
#
# Options:
#   -s SECONDS   Min seconds per timestamp (default: 20). Larger = fewer timestamps.
#
# Env: SRT_CHUNK_SECONDS  Same as -s (default: 20).
#

set -euo pipefail

CHUNK_SECONDS="${SRT_CHUNK_SECONDS:-20}"

while [[ $# -gt 0 && "$1" == -s ]]; do
  [[ -z "${2:-}" || "$2" == -* ]] && { echo "Missing value for -s" >&2; exit 2; }
  CHUNK_SECONDS="$2"
  shift 2
done

# Parse HH:MM:SS,mmm to seconds
to_seconds() {
  local t="$1"
  local h m s ms
  t="${t/,/.}"
  h="${t%%:*}"
  t="${t#*:}"
  m="${t%%:*}"
  t="${t#*:}"
  s="${t%%.*}"
  ms="${t#*.}"
  while [[ ${#ms} -lt 3 ]]; do ms="${ms}0"; done
  echo $((${h#0} * 3600 + ${m#0} * 60 + ${s#0} + ${ms#0} * 1 / 1000))
}

fmt_ts() {
  local sec="$1"
  local h=$((sec / 3600))
  local m=$(((sec % 3600) / 60))
  local s=$((sec % 60))
  printf '[%02d:%02d:%02d]' "$h" "$m" "$s"
}

parse_srt_v2() {
  local line block_start text start_sec
  local -a starts texts
  local n=0 in_block=0 buf=""

  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      if [[ $in_block -eq 1 && -n "$buf" ]]; then
        start_sec=$(to_seconds "$block_start")
        starts+=($start_sec)
        texts+=("$buf")
        n=$((n + 1))
      fi
      in_block=0
      buf=""
      continue
    fi
    if [[ "$line" =~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}[,.][0-9]{3}[[:space:]]*-->' ]]; then
      block_start="${line%% --> *}"
      in_block=1
      continue
    fi
    if [[ "$line" =~ '^[0-9]+$' ]]; then
      continue
    fi
    if [[ $in_block -eq 1 ]]; then
      [[ -n "$buf" ]] && buf="$buf $line" || buf="$line"
    fi
  done
  if [[ $in_block -eq 1 && -n "$buf" ]]; then
    start_sec=$(to_seconds "$block_start")
    starts+=($start_sec)
    texts+=("$buf")
    n=$((n + 1))
  fi

  local chunk_start="" chunk_text=""
  for (( i=1; i<=n; i++ )); do
    local s=${starts[$i]}
    local t="${texts[$i]}"
    if [[ -z "$chunk_start" ]]; then
      chunk_start=$s
      chunk_text="$t"
    else
      chunk_text="$chunk_text $t"
    fi
    local next_start=${starts[$((i+1))]:-$s}
    local duration=$((next_start - chunk_start))
    if [[ $duration -ge $CHUNK_SECONDS || $i -eq $n ]]; then
      printf '%s %s\n\n' "$(fmt_ts "$chunk_start")" "$chunk_text"
      chunk_start=""
      chunk_text=""
    fi
  done
}

if [[ $# -gt 0 ]]; then
  for f in "$@"; do
    [[ -f "$f" ]] && parse_srt_v2 < "$f"
  done
else
  parse_srt_v2
fi
