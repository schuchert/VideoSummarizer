#!/usr/bin/env bash

set -euo pipefail

WHISPER="${WHISPER:-$HOME/projects/whisper.cpp}"
WHISPER="${WHISPER%/}"
TRANSCRIPT_ONLY=false

if [[ "${1:-}" == "--transcript-only" ]]; then
  TRANSCRIPT_ONLY=true
fi

missing=()
warnings=()

check_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing+=("Missing command: $cmd")
  fi
}

check_cmd ffmpeg
check_cmd jq
check_cmd curl
check_cmd gdate

if [[ ! -x "$WHISPER/build/bin/whisper-cli" ]]; then
  missing+=("Missing whisper-cli at $WHISPER/build/bin/whisper-cli")
fi

if [[ ! -f "$WHISPER/models/ggml-base.en.bin" ]]; then
  missing+=("Missing model file at $WHISPER/models/ggml-base.en.bin")
fi

if [[ "$TRANSCRIPT_ONLY" != true && -z "${PERPLEXITY_API_KEY:-}" ]]; then
  missing+=("PERPLEXITY_API_KEY is not set")
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  printf '%s\n' "${missing[@]}" >&2
  exit 1
fi
