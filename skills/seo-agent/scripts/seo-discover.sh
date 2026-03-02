#!/usr/bin/env bash
# seo-discover.sh — Keyword Discovery Engine
# 
# Pulls GSC rankings + DataForSEO data to surface the best keyword opportunities.
# Focuses on the strike zone (positions 5-20) where effort = outsized gains.
#
# Usage:
#   seo-discover.sh --site sc-domain:example.com [--seeds "kw1,kw2"] [--limit 20] [--json]
#
# Requires:
#   DATAFORSEO_LOGIN, DATAFORSEO_PASSWORD env vars
#   Google auth (see gsc-report skill)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GSC_AUTH_SCRIPT="$HOME/clawd/skills/gsc-report/scripts/get-token.sh"
DFS_BASE="https://api.dataforseo.com"
CONFIG_FILE="$HOME/clawd/workspace/seo-agent/config.yaml"

# --- Defaults ---
SITE=""
SEEDS=""
LIMIT=20
JSON_MODE=false
DAYS=28
STRIKE_MIN=5
STRIKE_MAX=20
MIN_VOLUME=100

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --site) SITE="$2"; shift 2 ;;
    --seeds) SEEDS="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --days) DAYS="$2"; shift 2 ;;
    --json) JSON_MODE=true; shift ;;
    --help|-h)
      echo "Usage: seo-discover.sh --site sc-domain:example.com [--seeds 'kw1,kw2'] [--limit 20] [--json]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Load config if exists ---
if [[ -f "$CONFIG_FILE" ]]; then
  if [[ -z "$SITE" ]]; then
    SITE=$(grep '^site:' "$CONFIG_FILE" | sed 's/site: *"//' | tr -d '"' | tr -d "'")
  fi
  MIN_VOLUME=$(grep 'min_search_volume:' "$CONFIG_FILE" | awk '{print $2}' || echo "$MIN_VOLUME")
fi

# --- Validate ---
if [[ -z "$SITE" ]]; then
  echo "ERROR: --site is required (e.g., --site sc-domain:example.com)" >&2
  echo "       Or set 'site' in $CONFIG_FILE" >&2
  exit 1
fi

HAS_DFS=false
if [[ -n "${DATAFORSEO_LOGIN:-}" && -n "${DATAFORSEO_PASSWORD:-}" ]]; then
  HAS_DFS=true
  DFS_AUTH="-u ${DATAFORSEO_LOGIN}:${DATAFORSEO_PASSWORD}"
else
  echo "⚠️  No DataForSEO credentials. Running in GSC-only mode (no search volumes or keyword expansion)." >&2
  echo "   Set DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD for full features." >&2
  echo "" >&2
  DFS_AUTH=""
fi

log() { [[ "$JSON_MODE" == false ]] && echo "→ $*" >&2 || true; }
err() { echo "ERROR: $*" >&2; }

# --- Step 1: GSC Auth ---
log "Authenticating with Google..."
if [[ ! -f "$GSC_AUTH_SCRIPT" ]]; then
  err "GSC auth script not found at $GSC_AUTH_SCRIPT"
  err "Install the gsc-report skill first."
  exit 1
fi
# shellcheck source=/dev/null
source "$GSC_AUTH_SCRIPT"

if [[ -z "${ACCESS_TOKEN:-}" ]]; then
  err "Failed to get Google access token"
  exit 1
fi

# --- Step 2: Pull GSC top queries ---
log "Pulling GSC data for $SITE (last ${DAYS} days)..."

END_DATE=$(date +%Y-%m-%d)
START_DATE=$(date -d "-${DAYS} days" +%Y-%m-%d 2>/dev/null || date -v-${DAYS}d +%Y-%m-%d)

ENCODED_SITE=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$SITE', safe=''))" 2>/dev/null || \
  echo "$SITE" | sed 's|:|%3A|g' | sed 's|/|%2F|g')

GSC_RESPONSE=$(curl -s -X POST \
  "https://searchconsole.googleapis.com/webmasters/v3/sites/${ENCODED_SITE}/searchAnalytics/query" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"startDate\": \"$START_DATE\",
    \"endDate\": \"$END_DATE\",
    \"dimensions\": [\"query\"],
    \"rowLimit\": 100,
    \"dimensionFilterGroups\": [{
      \"filters\": [{
        \"dimension\": \"country\",
        \"operator\": \"equals\",
        \"expression\": \"usa\"
      }]
    }]
  }")

if echo "$GSC_RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
  err "GSC API error: $(echo "$GSC_RESPONSE" | jq -r '.error.message')"
  exit 1
fi

# Extract all queries with positions
ALL_QUERIES=$(echo "$GSC_RESPONSE" | jq -r '.rows // [] | map({
  keyword: .keys[0],
  position: (.position | floor),
  clicks: .clicks,
  impressions: .impressions,
  ctr: .ctr
})')

# Strike zone: positions 5-20
STRIKE_ZONE=$(echo "$ALL_QUERIES" | jq --argjson min "$STRIKE_MIN" --argjson max "$STRIKE_MAX" \
  '[.[] | select(.position >= $min and .position <= $max)] | sort_by(.position)')

STRIKE_COUNT=$(echo "$STRIKE_ZONE" | jq 'length')
log "Found $STRIKE_COUNT strike zone keywords (positions $STRIKE_MIN-$STRIKE_MAX)"

# Top queries for seed expansion
TOP_QUERIES=$(echo "$ALL_QUERIES" | jq -r '[.[] | select(.clicks > 0)] | sort_by(-.clicks) | .[0:10] | .[].keyword')

# Combine seeds
SEED_LIST=()
if [[ -n "$SEEDS" ]]; then
  IFS=',' read -ra CUSTOM_SEEDS <<< "$SEEDS"
  SEED_LIST+=("${CUSTOM_SEEDS[@]}")
fi
while IFS= read -r q; do
  SEED_LIST+=("$q")
done <<< "$TOP_QUERIES"

# Build seeds JSON array (dedupe, limit to 10)
SEEDS_JSON=$(printf '%s\n' "${SEED_LIST[@]}" | head -10 | jq -Rn '[inputs]')

# --- Steps 3-6: DataForSEO keyword expansion + volumes ---
if [[ "$HAS_DFS" == true ]]; then
  log "Expanding keywords via DataForSEO..."

  DFS_SUGGESTIONS=$(curl -s -X POST "$DFS_BASE/v3/dataforseo_labs/google/keyword_suggestions/live" \
    $DFS_AUTH \
    -H "Content-Type: application/json" \
    -d "[{
      \"keyword\": $(echo "$SEEDS_JSON" | jq '.[0]'),
      \"language_code\": \"en\",
      \"location_code\": 2840,
      \"limit\": 50,
      \"include_serp_info\": false,
      \"include_seed_keyword\": true
    }]")

  SUGGESTED_KEYWORDS=$(echo "$DFS_SUGGESTIONS" | jq -r \
    '.tasks[0].result[0].items // [] | map(.keyword) | .[]' 2>/dev/null | head -50 || echo "")

  log "Finding related keywords..."
  RELATED_PAYLOAD=$(echo "$SEEDS_JSON" | jq '{
    "keywords": .,
    "language_code": "en",
    "location_code": 2840
  }')

  DFS_RELATED=$(curl -s -X POST "$DFS_BASE/v3/keywords_data/google_ads/keywords_for_keywords/live" \
    $DFS_AUTH \
    -H "Content-Type: application/json" \
    -d "[$(echo "$RELATED_PAYLOAD")]")

  RELATED_KEYWORDS=$(echo "$DFS_RELATED" | jq -r \
    '.tasks[0].result // [] | map(.keyword) | .[]' 2>/dev/null | head -50 || echo "")

  ALL_CANDIDATES=$(printf '%s\n' "$SUGGESTED_KEYWORDS" "$RELATED_KEYWORDS" | \
    sort -u | grep -v '^$' | head -100)

  CANDIDATES_JSON=$(echo "$ALL_CANDIDATES" | jq -Rn '[inputs]')
  CANDIDATE_COUNT=$(echo "$CANDIDATES_JSON" | jq 'length')
  log "Got $CANDIDATE_COUNT candidate keywords for volume check..."

  if [[ "$CANDIDATE_COUNT" -gt 0 ]]; then
    log "Fetching search volumes..."
    VOLUME_PAYLOAD=$(echo "$CANDIDATES_JSON" | jq '{
      "keywords": .,
      "language_code": "en",
      "location_code": 2840
    }')

    DFS_VOLUME=$(curl -s -X POST "$DFS_BASE/v3/keywords_data/google_ads/search_volume/live" \
      $DFS_AUTH \
      -H "Content-Type: application/json" \
      -d "[$(echo "$VOLUME_PAYLOAD")]")

    VOLUME_DATA=$(echo "$DFS_VOLUME" | jq \
      '.tasks[0].result // [] | map({
        keyword: .keyword,
        search_volume: (.search_volume // 0),
        competition: (.competition // 0),
        competition_index: (.competition_index // 0),
        cpc: (.cpc // 0)
      })' 2>/dev/null || echo "[]")
  else
    VOLUME_DATA="[]"
  fi

else
  # GSC-only mode: no keyword expansion, score by impressions
  log "Running in GSC-only mode (no DataForSEO)..."
  log "Strike zone keywords scored by GSC impressions instead of search volume."
  VOLUME_DATA="[]"
fi

# --- Step 7: Build opportunity scores ---
log "Scoring opportunities..."

# Get existing positions as a lookup
EXISTING_POSITIONS=$(echo "$ALL_QUERIES" | jq 'map({(.keyword): .position}) | add // {}')

# Score formula:
#   opportunity_score = (search_volume / 100) * (1 - competition) * position_bonus
#   position_bonus: strike zone = 2x, unranked but high vol = 1x, rank 1-4 = 0.3x

SCORED=$(echo "$VOLUME_DATA" | jq --argjson existing "$EXISTING_POSITIONS" \
  --argjson min_vol "$MIN_VOLUME" \
  --argjson strike_min "$STRIKE_MIN" \
  --argjson strike_max "$STRIKE_MAX" '
  map(
    # Normalize competition (DataForSEO returns strings like "LOW","MEDIUM","HIGH")
    .competition as $raw_comp |
    (if ($raw_comp | type) == "string" then
      (if $raw_comp == "LOW" then 0.2 elif $raw_comp == "MEDIUM" then 0.5 elif $raw_comp == "HIGH" then 0.8 else 0.5 end)
    elif ($raw_comp | type) == "number" then $raw_comp
    else 0.5 end) as $norm_comp |
    . + {competition: $norm_comp} |
    select(.search_volume >= $min_vol) |
    . + {
      current_position: ($existing[.keyword] // null),
      position_bonus: (
        if ($existing[.keyword] // 999) >= $strike_min and ($existing[.keyword] // 999) <= $strike_max then 2.0
        elif ($existing[.keyword] // 999) < $strike_min then 0.3
        else 1.0
        end
      )
    } |
    . + {
      opportunity_score: (
        (.search_volume / 100) * (1 - .competition) * .position_bonus |
        . * 10 | round | . / 10
      )
    }
  ) |
  sort_by(-.opportunity_score)
')

# Merge with strike zone keywords (they might not be in DataForSEO results)
STRIKE_WITH_SCORES=$(echo "$STRIKE_ZONE" | jq --argjson vol "$VOLUME_DATA" '
  map(. as $gsc |
    ($vol | map(select(.keyword == $gsc.keyword)) | .[0]) as $v |
    {
      keyword: $gsc.keyword,
      current_position: $gsc.position,
      search_volume: ($v.search_volume // "n/a"),
      competition: ($v.competition // "n/a"),
      opportunity_score: (
        if $v then
          (($v.search_volume // 0) / 100) * (1 - (if (($v.competition // 0.5) | type) == "string" then 0.5 elif ($v.competition // 0.5) | type == "number" then ($v.competition // 0.5) else 0.5 end)) * 2.0 |
          . * 10 | round | . / 10
        else
          ($gsc.impressions / 10) | round
        end
      ),
      source: "gsc_strike_zone"
    }
  )
')

# Combine: strike zone first, then new opportunities
FINAL_OPPORTUNITIES=$(jq -n \
  --argjson strike "$STRIKE_WITH_SCORES" \
  --argjson new_opps "$SCORED" \
  --argjson limit "$LIMIT" '
  ($strike + ($new_opps | map(. + {source: "dataforseo"}))) |
  unique_by(.keyword) |
  sort_by(-.opportunity_score) |
  .[0:$limit]
')

# --- Output ---
if [[ "$JSON_MODE" == true ]]; then
  echo "$FINAL_OPPORTUNITIES"
else
  echo ""
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║              SEO DISCOVERY — $(date +%Y-%m-%d)                       ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo ""
  printf "  Site: %s\n" "$SITE"
  printf "  Period: Last %s days\n" "$DAYS"
  printf "  Strike zone: positions %s–%s\n" "$STRIKE_MIN" "$STRIKE_MAX"
  echo ""
  echo "  ┌─────────────────────────────────────────────────────────────┐"
  printf "  │ %-35s %6s %8s %6s %6s │\n" "KEYWORD" "POS" "VOLUME" "COMP" "SCORE"
  echo "  ├─────────────────────────────────────────────────────────────┤"

  echo "$FINAL_OPPORTUNITIES" | jq -r '.[] | [
    .keyword,
    (.current_position // "new" | tostring),
    (.search_volume // "?" | tostring),
    (.competition // "?" | tostring),
    (.opportunity_score | tostring)
  ] | @tsv' | while IFS=$'\t' read -r kw pos vol comp score; do
    # Add strike zone indicator
    INDICATOR=" "
    if [[ "$pos" =~ ^[0-9]+$ ]] && [[ "$pos" -ge 5 ]] && [[ "$pos" -le 20 ]]; then
      INDICATOR="⚡"
    fi
    printf "  │ %s %-34s %6s %8s %6s %6s │\n" "$INDICATOR" "${kw:0:34}" "$pos" "$vol" "$comp" "$score"
  done

  echo "  └─────────────────────────────────────────────────────────────┘"
  echo ""
  echo "  ⚡ = Strike zone (positions 5-20)"
  echo ""
  echo "  Next: Pick top opportunities → generate content briefs with Claude"
  echo "        Re-run with --json to pipe into other scripts"
  echo ""
fi
