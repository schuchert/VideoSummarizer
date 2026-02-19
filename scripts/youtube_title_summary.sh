#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${PERPLEXITY_API_KEY:-}" ]]; then
  echo "PERPLEXITY_API_KEY is not set" >&2
  exit 1
fi

# Read full transcript from stdin
transcript=$(cat)

# JSON-escape the transcript safely
escaped_transcript=$(jq -Rn --arg t "$transcript" '$t')

# Build the user prompt
user_prompt=$'Generate a YouTube title, description, and Shorts timestamps for this Paradox Diaries video transcript (raw somatic/philosophical bounce sessions).\n\n'\
$'Core Style & Framework: Spontaneous qigong/Tai Chi bouncing unlocks HRV/parasympathetic priming → paradox triads (observer/observed/observation) → systems thinking (lean/control theory, recursion, batch size) → non-dual emptiness (singularity collapse, "I don\'t know" fractal, no independent arising) → embodied homology (brain/mycelia/astrocytes, shapes/networks). Teacher-observer voice: raw n=1 logs, meta-digressions, self-laughs, practical hacks (e.g., water pitcher buffer, Persian rug imperfection).\n\n'\
$'Topics Span: Qigong shaking/bouncing, Tai Chi/Bagua/Liuhebafa forms, deep flexibility/PNF/YogaBody stretches, HRV metrics, dogs/plants/daily life hacks, software (Spring Boot/ADO/Gradle/CI-CD), lean/agile (muda/transaction costs), Virginia Satir triads, Gödel/Escher/Bach recursion, Mahayana/Dzogchen emptiness, quantum-ish awareness (implicit projections, astrocytic Ca²⁺).\n\n'\
$'Format Exactly:\n'\
$'- Title: 100-140 chars, hook metrics/paradox/practice (e.g., "HRV Surge + Time Loop Emptiness").\n'\
$'- 3-Sentence Summary: Concise, no bullets; weave somatic → theory → utility.\n'\
$'- Bulleted Highlights: 5-7 key insights/phrases, each 1 line.\n'\
$'- Shorts Timestamps: 8-10 entries as "Title | MM:SS | Xs | Hook quote" (15-60s hooks, visual/movement first).\n\n'\
$'Thumbnail Idea: 1-line suggestion (e.g., "HRV graph + ∞ pitcher").\n\n'\
$'TRANSCRIPT:\n'"$transcript"

# Build JSON request
json_request=$(jq -n --arg content "$user_prompt" '{
  model: "sonar-pro",
  messages: [
    {role: "system", content: "You are a YouTube optimizer for Paradox Diaries: raw, embodied philosophy via movement. Output ONLY the exact format—no extras, no markdown."},
    {role: "user", content: $content}
  ]
}')

# Call Perplexity API
curl -sS https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$json_request" \
  | jq -r '.choices[0].message.content // empty'
