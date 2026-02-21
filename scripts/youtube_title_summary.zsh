#!/usr/bin/env zsh
# extract_paradox_snippets.zsh - Full-spectrum Paradox Diaries extractor
# Replaces extract_fitness_snippets.zsh

set -euo pipefail

transcript=$(cat)

# Somatic/movement
extracted_somatic=$(echo "$transcript" | grep -iE \
  "(shak|bounce|qigong|tai.*chi|bagua|circle walk|wu chi|isometric|pancake|split|hip flexor|stretch|flex|pose|dantian|sacrum|fontanel|qi|chi)" \
  | sed 's/^/ /g')

# HRV/physiology
extracted_hrv=$(echo "$transcript" | grep -iE \
  "(HRV|rmssd|heart rate|vagus|parasympathetic|sympathetic|polar|elite)" \
  | sed 's/^/ /g')

# Dev/AI/process
extracted_dev=$(echo "$transcript" | grep -iE \
  "(cursor|perplex|llm|tdd|test|pipe|cli|python|repo|github|logging|websocket|bluetooth|twitchy|noise std|interpolat)" \
  | sed 's/^/ /g')

# Philosophy/systems
extracted_philo=$(echo "$transcript" | grep -iE \
  "(paradox|emptiness|triad|observer|mirror|flywheel|system|model|feedback|attractor|collapse|awareness)" \
  | sed 's/^/ /g')

# Combine + dedupe + trim
combined=$(printf '%s\n%s\n%s\n%s\n' \
  "$extracted_somatic" "$extracted_hrv" "$extracted_dev" "$extracted_philo" \
  | awk '!seen[$0]++' \
  | sed '/^[[:space:]]*$/d' \
  | head -c 12000)

# Fallback: full transcript if no matches
if [[ -z "$combined" ]]; then
  combined=$(echo "$transcript" | sed '/^[[:space:]]*$/d' | head -c 12000)
fi

echo "$combined"
