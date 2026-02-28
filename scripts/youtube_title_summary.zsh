#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${PERPLEXITY_API_KEY:-}" ]]; then
  echo "PERPLEXITY_API_KEY is not set" >&2
  exit 1
fi

transcript=$(cat)
filename="${1:-}"  # e.g., "HRV_Shaking_session.mp4" – pass as $1
intention=$(basename "$filename" | sed 's/\.[^.]*$//; s/_/ /g; s/^[0-9]\+-//' | head -c 80)  # Extracts "HRV Shaking session"

escaped_transcript=$(jq -Rn --arg t "$transcript" '$t')
escaped_intention=$(jq -Rn --arg i "$intention" '$i')

user_prompt=$'Create a YouTube title and summary for this video transcript in the Paradox Diaries style (somatic practice + philosophy).\n\n'\
$'Context: Blends biology/epigenetics, nervous system training, flexibility/Qigong/Tai Chi/Bagua. Teacher-observer tone. Use software metaphors ONLY if present in transcript (e.g., JVM, git rebase)—do NOT invent them.\n\n'\
$'Intention from filename: '"$escaped_intention"'\n\n'\
$'Output CLEAN: No [citations], [web:1], footnotes, or source refs. Pure YouTube copy-paste ready.\n\n'\
$'Format:\n'\
$'- First line: YouTube title\n'\
$'- Then a 3-sentence summary, no bullet points.\n'\
$'- Then Bulleted Highlights.\n\n'\
$'EXTRACT: Pose name/description → somatic benefits → philosophy if present. If no philosophy, infer: shaking/breath/vagus/epigenetics.\n\n'\
$'TRANSCRIPT:\n'"$escaped_transcript"

json_request=$(jq -n --arg content "$user_prompt" '{
  model: "sonar-pro",
  messages: [{role: "user", content: $content}]
}')

curl -sS https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$json_request" \
  | jq -r '.choices[0].message.content // empty'
