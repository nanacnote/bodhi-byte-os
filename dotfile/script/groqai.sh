#!/bin/sh

# requires jq and bat

CONTENT="$1"
GROQ_API_KEY="${GROQ_API_KEY:-}"
ENDPOINT="https://api.groq.com/openai/v1/chat/completions"

JSON_DATA='{"messages": [{"role": "user", "content": "'"$CONTENT"'"}], "model": "llama3-70b-8192"}'

RESPONSE=$(curl -s -X POST \
  "$ENDPOINT" \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_DATA")

JSON_RESPONSE=$(echo "$RESPONSE" | jq -r '.')
CHOICES=$(echo "$JSON_RESPONSE" | jq -r '.choices[0].message.content')

printf "$CHOICES\n" | bat -l md
