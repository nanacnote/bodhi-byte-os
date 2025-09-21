#!/bin/sh

# requires jq and bat

SESSION_FILE="/tmp/groq_session.txt"
CONTENT="${1:?Missing query!}"
GROQ_API_KEY="${GROQ_API_KEY:-}"
ENDPOINT="https://api.groq.com/openai/v1/chat/completions"
MODEL="llama-3.3-70b-versatile"

if [ ! -f "$SESSION_FILE" ]; then
  echo "[]" > "$SESSION_FILE"
fi

CONTEXT=$(cat "$SESSION_FILE")

JSON_DATA=$(jq -n \
  --arg content "$CONTENT" \
  --argjson ctx "$CONTEXT" \
  '{messages: ($ctx + [{role: "user", content: $content}]), model: "'"$MODEL"'"}')

RESPONSE=$(curl -s -X POST \
  "$ENDPOINT" \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_DATA")

ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // empty')
if [ -n "$ERROR_MSG" ]; then
  echo "Error: $ERROR_MSG" >&2
  exit 1
fi

CHOICES=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [ -z "$CHOICES" ]; then
  echo "No response content found." >&2
  exit 1
fi

echo "$CHOICES" | bat -l md

SUMMARY_JSON=$(jq -n \
  --arg text "$CHOICES" \
  '{messages: [{role: "user", content: "Summarize the following into a single compact paragraph for conversation memory:\n\n" + $text}], model: "'"$MODEL"'"}')

SUMMARY_RESPONSE=$(curl -s -X POST \
  "$ENDPOINT" \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$SUMMARY_JSON")

SUMMARY=$(echo "$SUMMARY_RESPONSE" | jq -r '.choices[0].message.content // empty')

if [ -n "$SUMMARY" ]; then
  UPDATED_CONTEXT=$(jq --arg sum "$SUMMARY" \
    '. + [{role: "assistant", content: $sum}]' "$SESSION_FILE")
  echo "$UPDATED_CONTEXT" > "$SESSION_FILE"
fi
