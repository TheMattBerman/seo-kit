#!/usr/bin/env bash
# seo-research.sh — DataForSEO SERP + PAA + volume + related keywords for a target keyword
# Usage: seo-research.sh "target keyword" [--location 2840] [--json] [--lang en]
#
# If DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD are set, uses DataForSEO API.
# Otherwise, outputs empty sections with a fallback note.
#
# DataForSEO location codes: 2840 = United States, 2826 = United Kingdom, 2036 = Australia

KEYWORD=""
LOCATION="2840"
LANG="en"
JSON_MODE=false
DFS_API="https://api.dataforseo.com/v3"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --location) LOCATION="$2"; shift 2 ;;
    --lang)     LANG="$2"; shift 2 ;;
    --json)     JSON_MODE=true; shift ;;
    *)          [[ -z "$KEYWORD" ]] && KEYWORD="$1"; shift ;;
  esac
done

if [[ -z "$KEYWORD" ]]; then
  echo "Usage: seo-research.sh \"target keyword\" [--location 2840] [--json] [--lang en]" >&2
  exit 1
fi

# Check for DataForSEO credentials
HAS_DFS=false
if [[ -n "$DATAFORSEO_LOGIN" && -n "$DATAFORSEO_PASSWORD" ]]; then
  HAS_DFS=true
fi

SLUG=$(echo "$KEYWORD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if ! $HAS_DFS; then
  # Fallback output — no credentials
  if $JSON_MODE; then
    cat <<EOF
{
  "keyword": "$KEYWORD",
  "timestamp": "$TIMESTAMP",
  "data_source": "none",
  "note": "DataForSEO credentials not configured. Set DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD to enable live data. Falling back to web_search for SERP analysis.",
  "serp_results": [],
  "paa_questions": [],
  "search_volume": null,
  "competition": null,
  "related_keywords": []
}
EOF
  else
    echo "=== SEO Research: $KEYWORD ==="
    echo ""
    echo "Data source: NOT CONFIGURED"
    echo "Note: DataForSEO credentials not found."
    echo "Set DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD to enable live SERP data."
    echo ""
    echo "Fallback: Use web_search tool for SERP analysis."
    echo "  - Search: \"$KEYWORD\""
    echo "  - Look for top 5-10 organic results"
    echo "  - Capture People Also Ask questions"
    echo "  - Note Featured Snippet format and AI Overview presence"
  fi
  exit 0
fi

# --- DataForSEO API calls ---

DFS_AUTH="-u \"$DATAFORSEO_LOGIN:$DATAFORSEO_PASSWORD\""

# 1. SERP results (organic, live)
SERP_PAYLOAD=$(cat <<EOF
[{
  "keyword": "$KEYWORD",
  "location_code": $LOCATION,
  "language_code": "$LANG",
  "depth": 10
}]
EOF
)

SERP_RESPONSE=$(curl -s \
  -u "$DATAFORSEO_LOGIN:$DATAFORSEO_PASSWORD" \
  -X POST "$DFS_API/serp/google/organic/live/advanced" \
  -H "Content-Type: application/json" \
  -d "$SERP_PAYLOAD" 2>/dev/null)

# 2. Search volume
VOLUME_PAYLOAD=$(cat <<EOF
[{
  "keywords": ["$KEYWORD"],
  "location_code": $LOCATION,
  "language_code": "$LANG"
}]
EOF
)

VOLUME_RESPONSE=$(curl -s \
  -u "$DATAFORSEO_LOGIN:$DATAFORSEO_PASSWORD" \
  -X POST "$DFS_API/keywords_data/google_ads/search_volume/live" \
  -H "Content-Type: application/json" \
  -d "$VOLUME_PAYLOAD" 2>/dev/null)

# 3. Related keywords
RELATED_PAYLOAD=$(cat <<EOF
[{
  "keywords": ["$KEYWORD"],
  "location_code": $LOCATION,
  "language_code": "$LANG"
}]
EOF
)

RELATED_RESPONSE=$(curl -s \
  -u "$DATAFORSEO_LOGIN:$DATAFORSEO_PASSWORD" \
  -X POST "$DFS_API/keywords_data/google_ads/keywords_for_keywords/live" \
  -H "Content-Type: application/json" \
  -d "$RELATED_PAYLOAD" 2>/dev/null)

# Parse with jq
SERP_ITEMS=$(echo "$SERP_RESPONSE" | jq -r '
  .tasks[0].result[0].items // [] |
  map(select(.type == "organic")) |
  .[:10] |
  map({
    position: .rank_absolute,
    title: .title,
    url: .url,
    description: .description,
    domain: .domain
  })
' 2>/dev/null || echo "[]")

PAA_QUESTIONS=$(echo "$SERP_RESPONSE" | jq -r '
  .tasks[0].result[0].items // [] |
  map(select(.type == "people_also_ask")) |
  .[0].items // [] |
  map(.title // .question)
' 2>/dev/null || echo "[]")

SEARCH_VOLUME=$(echo "$VOLUME_RESPONSE" | jq -r '
  .tasks[0].result[0].search_volume // null
' 2>/dev/null || echo "null")

COMPETITION=$(echo "$VOLUME_RESPONSE" | jq -r '
  .tasks[0].result[0].competition // null
' 2>/dev/null || echo "null")

RELATED_KW=$(echo "$RELATED_RESPONSE" | jq -r '
  .tasks[0].result // [] |
  map({keyword: .keyword, search_volume: .search_volume}) |
  sort_by(-.search_volume) |
  .[:20]
' 2>/dev/null || echo "[]")

if $JSON_MODE; then
  jq -n \
    --arg keyword "$KEYWORD" \
    --arg timestamp "$TIMESTAMP" \
    --arg location "$LOCATION" \
    --argjson serp "$SERP_ITEMS" \
    --argjson paa "$PAA_QUESTIONS" \
    --argjson volume "$SEARCH_VOLUME" \
    --argjson competition "$COMPETITION" \
    --argjson related "$RELATED_KW" \
    '{
      keyword: $keyword,
      timestamp: $timestamp,
      location_code: $location,
      data_source: "dataforseo_live",
      serp_results: $serp,
      paa_questions: $paa,
      search_volume: $volume,
      competition: $competition,
      related_keywords: $related
    }'
else
  echo "=== SEO Research: $KEYWORD ==="
  echo "Data source: DataForSEO (live)"
  echo "Timestamp: $TIMESTAMP"
  echo "Location: $LOCATION"
  echo ""

  echo "--- SERP Results (Top 10) ---"
  echo "$SERP_ITEMS" | jq -r '.[] | "\(.position). \(.title)\n   \(.url)\n   \(.description // "(no description)")\n"' 2>/dev/null || echo "No organic results found."

  echo ""
  echo "--- People Also Ask ---"
  PAA_COUNT=$(echo "$PAA_QUESTIONS" | jq 'length' 2>/dev/null || echo 0)
  if [[ "$PAA_COUNT" -gt 0 ]]; then
    echo "$PAA_QUESTIONS" | jq -r '.[] | "- \(.)"' 2>/dev/null
  else
    echo "No PAA questions captured."
  fi

  echo ""
  echo "--- Search Data ---"
  echo "Monthly search volume: ${SEARCH_VOLUME:-unknown}"
  echo "Competition score:     ${COMPETITION:-unknown}"

  echo ""
  echo "--- Related Keywords (top 20 by volume) ---"
  echo "$RELATED_KW" | jq -r '.[] | "\(.keyword) (\(.search_volume // "?") searches/mo)"' 2>/dev/null || echo "No related keywords found."

  echo ""
  echo "--- Research Summary ---"
  SERP_COUNT=$(echo "$SERP_ITEMS" | jq 'length' 2>/dev/null || echo 0)
  RELATED_COUNT=$(echo "$RELATED_KW" | jq 'length' 2>/dev/null || echo 0)
  echo "SERP results: $SERP_COUNT"
  echo "PAA questions: $PAA_COUNT"
  echo "Related keywords: $RELATED_COUNT"
  echo ""
  echo "Next step: Feed this data into SEO Forge for content creation."
  echo "  /seo-forge \"$KEYWORD\""
fi
