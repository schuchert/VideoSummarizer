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
user_prompt=$'Create a YouTube title and summary for this health/fitness video transcript.\n\n'\
$'Context: Videos are about deep flexibility (in the style of YogaBody Science of Stretching), tai chi, bagua, liuhebafa, qi gong, yoga, sometimes software, dogs, and related topics.\n\n'\
$'Use my teacher-observer style.\n\n'\
$'Format:\n'\
$'- First line: YouTube title\n'\
$'- Then a 3-sentence summary, no bullet points.\n\n'\
$'- Then Bulleted Highlights.\n\n'\
$'TRANSCRIPT:\n'"$transcript"

# Build JSON request
json_request=$(jq -n --arg content "$user_prompt" '{
  model: "sonar-pro",
  messages: [
    {role: "user", content: $content}
  ]
}')

# Call Perplexity API
curl -sS https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$json_request" \
  | jq -r '.choices[0].message.content // empty'
