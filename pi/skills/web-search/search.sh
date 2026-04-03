#!/usr/bin/env bash
# Usage: ./search.sh "query" [max_results]
# Requires: TAVILY_API_KEY environment variable (supports op:// references via 1Password CLI)
set -euo pipefail

QUERY="$1"
MAX_RESULTS="${2:-5}"

# Resolve 1Password reference if needed
if [[ "$TAVILY_API_KEY" == op://* ]]; then
  API_KEY="$(op read "$TAVILY_API_KEY")"
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
