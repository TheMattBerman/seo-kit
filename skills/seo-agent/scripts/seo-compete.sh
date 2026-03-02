#!/usr/bin/env bash
# seo-compete.sh — Competitor Gap Analysis
#
# Finds keywords your competitor ranks for that you don't.
# Feed the output back into seo-discover.sh as seeds.
#
# Usage:
#   seo-compete.sh --site example.com --competitor competitor.com [--limit 30] [--json]
#
# Requires: DATAFORSEO_LOGIN, DATAFORSEO_PASSWORD

set -euo pipefail

DFS_BASE="https://api.dataforseo.com"
CONFIG_FILE="$HOME/clawd/workspace/seo-agent/config.yaml"

SITE=""
COMPETITOR=""
LIMIT=30
JSON_MODE=false
LOCATION_CODE=2840  # USA

while [[ $# -gt 0 ]]; do
  case "$1" in
    --site) SITE="$2"; shift 2 ;;
    --competitor) COMPETITOR="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --location) LOCATION_CODE="$2"; shift 2 ;;
    --json) JSON_MODE=true; shift ;;
    --help|-h)
      echo "Usage: seo-compete.sh --site example.com --competitor competitor.com [--limit 30] [--json]"
      echo ""
      echo "Options:"
      echo "  --site         Your domain (e.g., example.com)"
      echo "  --competitor   Competitor domain to analyze"
      echo "  --limit        Number of results (default: 30)"
      echo "  --location     DataForSEO location code (default: 2840 = USA)"
      echo "  --json         Machine-readable output"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
  if [[ -z "$SITE" ]]; then
    # Strip sc-domain: prefix for DataForSEO
    RAW_SITE=$(grep '^site:' "$CONFIG_FILE" | sed 's/site: *"//' | tr -d '"' | tr -d "'")
    SITE=$(echo "$RAW_SITE" | sed 's|sc-domain:||' | sed 's|https://||' | sed 's|/$||')
  fi
  # Load competitors from config if no --competitor flag
  if [[ -z "$COMPETITOR" ]]; then
    COMPETITOR=$(grep -A1 'competitors:' "$CONFIG_FILE" | grep '  -' | head -1 | sed 's/.*- //' | tr -d '"' | tr -d "'" | tr -d ' ')
  fi
fi

# Strip sc-domain: if present in --site
SITE=$(echo "$SITE" | sed 's|sc-domain:||' | sed 's|https://||' | sed 's|/$||')

if [[ -z "$SITE" ]]; then
  echo "ERROR: --site is required (e.g., --site example.com)" >&2
  exit 1
fi

if [[ -z "$COMPETITOR" ]]; then
  echo "ERROR: --competitor is required (e.g., --competitor competitor.com)" >&2
  exit 1
fi

if [[ -z "${DATAFORSEO_LOGIN:-}" || -z "${DATAFORSEO_PASSWORD:-}" ]]; then
  echo "⚠️  No DataForSEO credentials. seo-compete requires DataForSEO for competitor keyword data." >&2
  echo "   Set DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD to use this script." >&2
  echo "" >&2
  echo "   Without DataForSEO, try these manual approaches:" >&2
  echo "   1. Search: site:competitor.com — see what pages they have" >&2
  echo "   2. Search: "competitor.com" + "keyword" — find their ranked content" >&2
  echo "   3. Use free tools like Ubersuggest or search "competitor keyword gap free"" >&2
  exit 1
fi

DFS_AUTH="-u ${DATAFORSEO_LOGIN}:${DATAFORSEO_PASSWORD}"
log() { [[ "$JSON_MODE" == false ]] && echo "→ $*" >&2 || true; }

# --- Step 1: Domain Intersection (keyword gap) ---
log "Finding keyword gaps: $SITE vs $COMPETITOR..."

INTERSECTION=$(curl -s -X POST "$DFS_BASE/v3/dataforseo_labs/google/domain_intersection/live" \
  $DFS_AUTH \
  -H "Content-Type: application/json" \
  -d "[{
    \"target1\": \"$COMPETITOR\",
    \"target2\": \"$SITE\",
    \"language_code\": \"en\",
    \"location_code\": $LOCATION_CODE,
    \"limit\": $LIMIT,
    \"filters\": [
      [\"ranked_serp_element.serp_item.rank_absolute\", \"<\", 30],
      \"and\",
      [\"ranked_serp_element.serp_item.type\", \"=\", \"organic\"]
    ],
    \"order_by\": [\"keyword_data.keyword_info.search_volume,desc\"]
  }]")

HTTP_STATUS=$(echo "$INTERSECTION" | jq -r '.status_code // 0')
if [[ "$HTTP_STATUS" != "20000" && "$HTTP_STATUS" != "0" ]]; then
  ERRMSG=$(echo "$INTERSECTION" | jq -r '.status_message // "unknown error"')
  echo "ERROR: DataForSEO API error ($HTTP_STATUS): $ERRMSG" >&2
  # Try to get any partial data
fi

GAPS=$(echo "$INTERSECTION" | jq --arg competitor "$COMPETITOR" --arg my_site "$SITE" '
  .tasks[0].result // [] |
  map({
    keyword: .keyword_data.keyword,
    search_volume: (.keyword_data.keyword_info.search_volume // 0),
    competition: (.keyword_data.keyword_info.competition // 0),
    cpc: (.keyword_data.keyword_info.cpc // 0),
    competitor_position: (
      .ranked_elements |
      map(select(.domain == $competitor)) |
      .[0].rank_absolute // null
    ),
    your_position: (
      .ranked_elements |
      map(select(.domain == $my_site)) |
      .[0].rank_absolute // "not ranking"
    )
  }) |
  map(select(.search_volume > 0)) |
  sort_by(-.search_volume)
')

GAP_COUNT=$(echo "$GAPS" | jq 'length')
log "Found $GAP_COUNT keyword gaps"

# --- Step 2: Find competitor's top ranking pages ---
log "Pulling competitor's top organic pages..."

COMP_PAGES=$(curl -s -X POST "$DFS_BASE/v3/dataforseo_labs/google/competitors_domain/live" \
  $DFS_AUTH \
  -H "Content-Type: application/json" \
  -d "[{
    \"target\": \"$SITE\",
    \"language_code\": \"en\",
    \"location_code\": $LOCATION_CODE,
    \"limit\": 10
  }]")

COMPETITORS_LIST=$(echo "$COMP_PAGES" | jq \
  '.tasks[0].result // [] | map({
    domain: .domain,
    intersections: .intersections,
    competitor_relevance: .competitor_relevance
  }) | sort_by(-.intersections) | .[0:10]' 2>/dev/null || echo "[]")

# --- Output ---
if [[ "$JSON_MODE" == true ]]; then
  jq -n \
    --arg site "$SITE" \
    --arg competitor "$COMPETITOR" \
    --argjson gaps "$GAPS" \
    --argjson competitors "$COMPETITORS_LIST" \
    --arg date "$(date +%Y-%m-%d)" '{
      site: $site,
      competitor: $competitor,
      date: $date,
      gap_count: ($gaps | length),
      keyword_gaps: $gaps,
      related_competitors: $competitors
    }'
else
  echo ""
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║        COMPETITOR ANALYSIS — $(date +%Y-%m-%d)                       ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo ""
  printf "  Your site: %s\n" "$SITE"
  printf "  Competitor: %s\n" "$COMPETITOR"
  printf "  Keyword gaps found: %s\n" "$GAP_COUNT"
  echo ""

  if [[ "$GAP_COUNT" -gt 0 ]]; then
    echo "  KEYWORD GAPS — They rank. You don't."
    echo "  ┌──────────────────────────────────────────────────────────────────┐"
    printf "  │ %-38s %8s %6s %6s │\n" "KEYWORD" "VOLUME" "THEIR" "YOUR"
    echo "  ├──────────────────────────────────────────────────────────────────┤"
    echo "$GAPS" | jq -r '.[0:'"$LIMIT"'] | .[] |
      [.keyword, (.search_volume|tostring), (.competitor_position // "?"|tostring), (.your_position|tostring)] | @tsv' | \
    while IFS=$'\t' read -r kw vol their_pos your_pos; do
      printf "  │ %-38s %8s %6s %6s │\n" "${kw:0:38}" "$vol" "$their_pos" "$your_pos"
    done
    echo "  └──────────────────────────────────────────────────────────────────┘"
    echo ""
  fi

  if [[ "$(echo "$COMPETITORS_LIST" | jq 'length')" -gt 0 ]]; then
    echo "  OTHER COMPETITORS (ranked by overlap with your site):"
    echo "$COMPETITORS_LIST" | jq -r '.[] | "  \(.domain) — \(.intersections) shared keywords"'
    echo ""
  fi

  echo "  Next steps:"
  echo "    1. Export gaps as seeds: ./seo-compete.sh --json | jq '[.keyword_gaps[].keyword]'"
  echo "    2. Feed into discovery: ./seo-discover.sh --seeds 'gap_kw1,gap_kw2'"
  echo "    3. Write content targeting these gaps"
  echo ""
fi
