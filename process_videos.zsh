#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WHISPER=~/projects/whisper.cpp/
SRC_DIR=~/Downloads
TRANSCRIPT_ONLY=false
MAX_SIZE=
AGE_HOURS=4

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
  local tmp_wav

  tmp_wav=$(mktemp /tmp/whisper.XXXXXX)
  ffmpeg -y -nostdin -loglevel error -i "$file" -ar 16000 -ac 1 -f wav "$tmp_wav" 2>/dev/null
  "$WHISPER/build/bin/whisper-cli" -m "$WHISPER/models/ggml-base.en.bin" -f "$tmp_wav" -nt -np 2>/dev/null
  rm -f "$tmp_wav"
}

process_file() {
  local file="$1"
  local transcript summary new_name

  transcript=$(transcribe_file "$file")

  echo "#########################################################################"
  echo "$file"
  echo ""
  echo "$transcript"
  echo ""
  if [[ "$TRANSCRIPT_ONLY" != true ]]; then
    summary=$(printf '%s\n' "$transcript" | "$script_dir/youtube_title_summary.sh")
    echo "$summary"
  fi

  new_name=$(as_dated_name "$file")
  mv "$file" "$DEST_DIR/$new_name"
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

mkdir -p "$DEST_DIR"
build_find_args

find "${FIND_ARGS[@]}" -print0 | sort -z -r | \
while IFS= read -r -d '' file; do
  process_file "$file"
done
