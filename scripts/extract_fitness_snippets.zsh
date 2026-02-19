#!/usr/bin/env zsh
set -euo pipefail

transcript=$(cat)

# Extract somatic/philosophical fitness lines (update patterns periodically)
extracted=$(echo "$transcript" | grep -iE \
  "(shak|flex|stretch|HRV|qigong|tai.*chi|bagua|liuhebafa|paradox|singularity|neural|flare|somatic|emptiness|collapse|energy|stability|practice|movement|awareness|observe|gyro|mandelbrot|hrv)" \
  | grep -v -iE "(software|code|git|java|gradle)" \
  | sed 's/^/ /g' | tr -s '\n' '\n' | head -c 8000)

if [[ -z "$extracted" ]]; then
  echo "No fitness/somatic content detected in transcript." >&2
  exit 1
fi

echo "$extracted"
