#!/usr/bin/env zsh

set -euo pipefail

script_dir="$(cd "$(dirname "${ZSH_SCRIPT}")" && pwd)"

WHISPER=~/projects/whisper.cpp/
SRC_DIR=~/Downloads
DEST_DIR="$SRC_DIR/processed"

as_dated_name() {
  local file_name="$1"
  local date_str
  date_str=$(date +%Y-%m-%d)

  local name="${file_name:t}"         # basename (e.g., video.mp4)
  local dir_name="${name:r}"          # name without extension (e.g., video)
  local ext="${name:e}"               # extension (e.g., mp4)

  local new_name="${dir_name}_${date_str}.${ext}"
  echo "$new_name"
}

extract_text() {
  local file="$1"
  ffmpeg -y -nostdin -loglevel error -i "$file" -ar 16000 -ac 1 -f wav - 2>/dev/null \
  | "$WHISPER/build/bin/whisper-cli" -m "$WHISPER/models/ggml-base.en.bin" -f - -otxt 2>/dev/null
}

print_header() {
  local file="$1"
  echo "#########################################################################"
  echo "$file"
  echo ""
}

print_text() {
  local text="$1"
  echo "$text"
  echo ""
}

process_transcript() {
  local file="$1"
  print_header "$file"
  local TEXT=$(extract_text "$file")
  print_text "$TEXT"
}

process_files_text_only() {
  local -a files=("$@")
  for file in "${files[@]}"; do
    if [[ ! -f "$file" ]]; then
      echo "Skipping non-existent file: $file" >&2
      continue
    fi
    process_transcript "$file"
  done
}

handle_text_only_mode() {
  shift  # Remove the flag
  if [[ $# -eq 0 ]]; then
    echo "Error: --text-only requires one or more file paths." >&2
    exit 1
  fi
  process_files_text_only "$@"
}

process_batch_files() {
  find "$SRC_DIR" -maxdepth 1 -name "*.mp4" -mtime -1 -size -300M -print0 | sort -z -r -z | \
  while IFS= read -r -d '' file; do
    process_transcript "$file"

    printf '%s\n' "$TEXT" | "$script_dir/youtube_title_summary.sh"
    echo ""

    new_name=$(as_dated_name "$file")
    mv "$file" "$DEST_DIR/$new_name"
  done
}

mkdir -p "$DEST_DIR"

# Check for --text-only flag and positional arguments
if [[ "${1:-}" == "--text-only" ]]; then
  handle_text_only_mode "$@"
else
  process_batch_files
fi
