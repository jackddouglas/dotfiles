#!/usr/bin/env bash
# Usage: ./search.sh "query" [max_results]
# Requires: TAVILY_API_KEY environment variable (supports op:// references via 1Password CLI)
set -euo pipefail

QUERY="$1"
MAX_RESULTS="${2:-5}"

# Resolve 1Password reference if needed, caching to avoid repeated prompts
if [[ "$TAVILY_API_KEY" == op://* ]]; then
  CACHE_FILE="${TMPDIR:-/tmp}/tavily-api-key.cache"
  if [[ -f "$CACHE_FILE" && -s "$CACHE_FILE" ]]; then
    API_KEY="$(cat "$CACHE_FILE")"
  else
    API_KEY="$(op read "$TAVILY_API_KEY")"
    install -m 600 /dev/null "$CACHE_FILE"
    printf '%s' "$API_KEY" > "$CACHE_FILE"
  fi
else
  API_KEY="$TAVILY_API_KEY"
fi

curl -s "https://api.tavily.com/search" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg q "$QUERY" \
    --argjson max "$MAX_RESULTS" \
    --arg key "$API_KEY" \
    '{
      api_key: $key,
      query: $q,
      max_results: $max,
      include_answer: true,
      include_raw_content: false
    }')" | jq '{
  answer: .answer,
  results: [.results[] | {title, url, content}]
}'
