#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${PERPLEXITY_API_KEY:-}" ]]; then
  echo "PERPLEXITY_API_KEY is not set" >&2
  exit 1
fi

transcript=$(cat)
escaped_transcript=$(jq -Rn --arg t "$transcript" '$t')

user_prompt=$'Create a YouTube title and summary for this video transcript in the Paradox Diaries style (somatic practice + philosophy + software metaphors).\\n\\n'\
$'Context: Blends biology/epigenetics, nervous system training, flexibility/Qigong/Tai Chi, with code analogies (Java/JVM). Teacher-observer tone.\\n\\n'\
$'Format:\\n'\
$'- First line: YouTube title\\n'\
$'- Then a 3-sentence summary, no bullet points.\\n'\
$'- Then Bulleted Highlights.\\n\\n'\
$'TRANSCRIPT:\\n'"$transcript"

json_request=$(jq -n --arg content "$user_prompt" '{
  model: "sonar-pro",
  messages: [{role: "user", content: $content}]
}')

curl -sS https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$json_request" \
  | jq -r '.choices[0].message.content // empty'
