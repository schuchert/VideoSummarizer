#!/bin/zsh

set -euo pipefail

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

ensure_brew_deps() {
  brew install ffmpeg jq git cmake coreutils
}

ensure_whisper() {
  local base_dir="$HOME/projects"
  local whisper_dir="$base_dir/whisper.cpp"

  mkdir -p "$base_dir"

  if [[ ! -d "$whisper_dir" ]]; then
    git clone https://github.com/ggerganov/whisper.cpp.git "$whisper_dir"
  fi

  mkdir -p "$whisper_dir/build"
  (cd "$whisper_dir/build" && cmake .. && make -j)

  if [[ ! -f "$whisper_dir/models/ggml-base.en.bin" ]]; then
    (cd "$whisper_dir" && ./models/download-ggml-model.sh base.en)
  fi
}

ensure_api_key() {
  if [[ -n "${PERPLEXITY_API_KEY:-}" ]]; then
    echo "PERPLEXITY_API_KEY is already set in the environment."
    return 0
  fi
  echo "PERPLEXITY_API_KEY is not set."
}

ensure_downloads_dir() {
  mkdir -p "$HOME/Downloads/processed"
}

display_manual_step() {
  echo ""
  echo "Add the following lines to ~/.zshrc:"
  echo "export PATH=\"$HOME/projects/whisper.cpp/build/bin:\$PATH\""
  echo "export PERPLEXITY_API_KEY=\"pplx-your_actual_key_here\""
  echo ""
  echo "Setup complete."
}

main() {
  ensure_brew
  ensure_brew_deps
  ensure_whisper
  ensure_api_key
  ensure_downloads_dir
  display_manual_step
}

main "$@"
