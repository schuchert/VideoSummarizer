#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WHISPER="${WHISPER:-$HOME/projects/whisper.cpp}"
WHISPER="${WHISPER%/}"
SRC_DIR=~/Downloads
TRANSCRIPT_ONLY=false
MAX_SIZE=
AGE_HOURS=4
LAST_ERROR=""
RESULTS=()
ERROR_DETAILS=()

usage() {
  cat <<'USAGE'
Usage: process_videos.zsh [options]

Options:
  -t, --transcript-only    Only print transcript (skip summary)
  -s, --size[=SIZE]        Max size for find (e.g., 3M). If omitted, no size filter
  -a, --age HOURS          Max age in hours (default: 4)
  -d, --dir PATH           Source directory (default: ~/Downloads)
  -h, --help               Show this help
USAGE
}

as_dated_name() {
  local file_name="$1"
  local date_str
  date_str=$(date +%Y-%m-%d)

  local name="${file_name##*/}"       # basename (e.g., video.mp4)
  local dir_name="${name%.*}"         # name without extension (e.g., video)
  local ext="${name##*.}"             # extension (e.g., mp4)

  local new_name="${dir_name}_${date_str}.${ext}"
  echo "$new_name"
}

build_find_args() {
  FIND_ARGS=("$SRC_DIR" -maxdepth 1 -name "*.mp4" -mmin "-$((AGE_HOURS * 60))")
  if [[ -n "${MAX_SIZE:-}" ]]; then
    FIND_ARGS+=(-size "-$MAX_SIZE")
  fi
}

transcribe_file() {
  local file="$1"
  local tmp_wav tmp_err tmp_out

  LAST_ERROR=""
  tmp_wav=$(mktemp /tmp/whisper.XXXXXX)
  tmp_err=$(mktemp /tmp/whisper.err.XXXXXX)
  tmp_out=$(mktemp /tmp/whisper.out.XXXXXX)

  if ! ffmpeg -y -nostdin -loglevel error -i "$file" -ar 16000 -ac 1 -f wav "$tmp_wav" 2>"$tmp_err"; then
    LAST_ERROR=$(<"$tmp_err")
    rm -f "$tmp_wav" "$tmp_err" "$tmp_out"
    return 1
  fi

  if ! "$WHISPER/build/bin/whisper-cli" -m "$WHISPER/models/ggml-base.en.bin" -f "$tmp_wav" -nt -np 2>>"$tmp_err" >"$tmp_out"; then
    LAST_ERROR=$(<"$tmp_err")
    rm -f "$tmp_wav" "$tmp_err" "$tmp_out"
    return 1
  fi

  cat "$tmp_out"
  rm -f "$tmp_wav" "$tmp_err" "$tmp_out"
}

process_file() {
  local file="$1"
  local transcript summary new_name summary_err

  if ! transcript=$(transcribe_file "$file"); then
    RESULTS+=("FAILED|$file|transcription failed")
    ERROR_DETAILS+=("Transcription failed for $file\n${LAST_ERROR:-Unknown error}")
    return 0
  fi

  echo "#########################################################################"
  echo "$file"
  echo ""
  echo "$transcript"
  echo ""
  if [[ "$TRANSCRIPT_ONLY" != true ]]; then
    summary_err=$(mktemp /tmp/summary.err.XXXXXX)
    if ! summary=$(printf '%s\n' "$transcript" | "$script_dir/youtube_title_summary.sh" 2>"$summary_err"); then
      local err
      err=$(<"$summary_err")
      rm -f "$summary_err"
      RESULTS+=("FAILED|$file|summary failed")
      ERROR_DETAILS+=("Summary failed for $file\n${err:-Unknown error}")
      return 0
    fi
    rm -f "$summary_err"
    echo "$summary"
  fi

  new_name=$(as_dated_name "$file")
  mv "$file" "$DEST_DIR/$new_name"
  RESULTS+=("OK|$file|$DEST_DIR/$new_name")
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--transcript-only)
      TRANSCRIPT_ONLY=true
      shift
      ;;
    -s|--size)
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
        MAX_SIZE="$2"
        shift 2
      else
        MAX_SIZE=""
        shift
      fi
      ;;
    --size=*)
      MAX_SIZE="${1#*=}"
      shift
      ;;
    -a|--age)
      if [[ -z "${2:-}" || "$2" == -* ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 2
      fi
      AGE_HOURS="$2"
      shift 2
      ;;
    -d|--dir)
      if [[ -z "${2:-}" || "$2" == -* ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 2
      fi
      SRC_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! [[ "$AGE_HOURS" =~ ^[0-9]+$ ]]; then
  echo "Age must be an integer number of hours: $AGE_HOURS" >&2
  exit 2
fi

SRC_DIR="${SRC_DIR/#\~/$HOME}"
DEST_DIR="$SRC_DIR/processed"

export WHISPER
if [[ "$TRANSCRIPT_ONLY" == true ]]; then
  "$script_dir/verify_dependencies.zsh" --transcript-only
else
  "$script_dir/verify_dependencies.zsh"
fi

mkdir -p "$DEST_DIR"
build_find_args

while IFS= read -r -d '' file; do
  process_file "$file"
done < <(find "${FIND_ARGS[@]}" -print0 | sort -z -r)

if [[ ${#RESULTS[@]} -gt 0 ]]; then
  echo ""
  echo "Summary"
  for entry in "${RESULTS[@]}"; do
    IFS='|' read -r status file detail <<<"$entry"
    if [[ -n "$detail" ]]; then
      echo "$status: $file -> $detail"
    else
      echo "$status: $file"
    fi
  done
fi

if [[ ${#ERROR_DETAILS[@]} -gt 0 ]]; then
  echo ""
  echo "Errors"
  for err in "${ERROR_DETAILS[@]}"; do
    echo "-----"
    echo -e "$err"
  done
fi
