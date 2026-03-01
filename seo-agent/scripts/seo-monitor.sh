#!/usr/bin/env bash
# seo-monitor.sh — Rankings Monitor
#
# Tracks position changes week over week. Highlights strike zone movers.
# Saves snapshots for historical comparison.
#
# Usage:
#   seo-monitor.sh --site sc-domain:example.com [--days 28] [--json]
#
# Requires: Google auth (see gsc-report skill)

set -euo pipefail

GSC_AUTH_SCRIPT="$HOME/clawd/skills/gsc-report/scripts/get-token.sh"
SNAPSHOT_DIR="$HOME/clawd/workspace/seo-agent/snapshots"
CONFIG_FILE="$HOME/clawd/workspace/seo-agent/config.yaml"

SITE=""
DAYS=28
JSON_MODE=false
STRIKE_MIN=5
STRIKE_MAX=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    --site) SITE="$2"; shift 2 ;;
    --days) DAYS="$2"; shift 2 ;;
    --json) JSON_MODE=true; shift ;;
    --help|-h)
      echo "Usage: seo-monitor.sh --site sc-domain:example.com [--days 28] [--json]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -f "$CONFIG_FILE" ]]; then
  if [[ -z "$SITE" ]]; then
    SITE=$(grep '^site:' "$CONFIG_FILE" | sed 's/site: *"//' | tr -d '"' | tr -d "'")
  fi
fi

if [[ -z "$SITE" ]]; then
  echo "ERROR: --site is required" >&2
  exit 1
fi

log() { [[ "$JSON_MODE" == false ]] && echo "→ $*" >&2 || true; }

mkdir -p "$SNAPSHOT_DIR"

# Sanitize site for filename
SITE_SLUG=$(echo "$SITE" | sed 's|sc-domain:||' | sed 's|https://||' | sed 's|/|_|g' | sed 's|\.|_|g')
TODAY=$(date +%Y-%m-%d)
SNAPSHOT_FILE="$SNAPSHOT_DIR/${SITE_SLUG}-${TODAY}.json"

# Find most recent previous snapshot
PREV_SNAPSHOT=$(ls -1 "$SNAPSHOT_DIR/${SITE_SLUG}-"*.json 2>/dev/null | grep -v "$TODAY" | sort | tail -1 || echo "")

# --- Auth ---
log "Authenticating with Google..."
if [[ ! -f "$GSC_AUTH_SCRIPT" ]]; then
  echo "ERROR: GSC auth script not found. Install gsc-report skill first." >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$GSC_AUTH_SCRIPT"

# --- Pull current GSC data ---
log "Pulling current rankings from GSC..."

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
    \"dimensions\": [\"query\", \"page\"],
    \"rowLimit\": 500
  }")

if echo "$GSC_RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
  echo "ERROR: GSC API error: $(echo "$GSC_RESPONSE" | jq -r '.error.message')" >&2
  exit 1
fi

CURRENT_DATA=$(echo "$GSC_RESPONSE" | jq '.rows // [] | map({
  keyword: .keys[0],
  page: .keys[1],
  position: (.position | (. * 10 | round | . / 10)),
  clicks: .clicks,
  impressions: .impressions,
  ctr: (.ctr * 100 | (. * 10 | round | . / 10))
})')

# Save snapshot
echo "$CURRENT_DATA" | jq '{date: "'"$TODAY"'", site: "'"$SITE"'", rows: .}' > "$SNAPSHOT_FILE"
log "Saved snapshot to $SNAPSHOT_FILE"

# --- Compare with previous snapshot ---
if [[ -z "$PREV_SNAPSHOT" ]]; then
  log "No previous snapshot found. This is your baseline."
  
  if [[ "$JSON_MODE" == true ]]; then
    jq -n --argjson current "$CURRENT_DATA" \
      --arg site "$SITE" \
      --arg today "$TODAY" '{
        site: $site,
        date: $today,
        baseline: true,
        total_keywords: ($current | length),
        strike_zone: ($current | map(select(.position >= 5 and .position <= 20))),
        top_10: ($current | map(select(.position <= 10)) | sort_by(.position)),
        data: $current
      }'
  else
    TOTAL=$(echo "$CURRENT_DATA" | jq 'length')
    STRIKE=$(echo "$CURRENT_DATA" | jq '[.[] | select(.position >= 5 and .position <= 20)] | length')
    TOP10=$(echo "$CURRENT_DATA" | jq '[.[] | select(.position <= 10)] | length')

    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║           SEO MONITOR — BASELINE ($TODAY)              ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    printf "  Site: %s\n" "$SITE"
    printf "  Total keywords ranking: %s\n" "$TOTAL"
    printf "  Top 10: %s  |  Strike zone (5-20): %s\n" "$TOP10" "$STRIKE"
    echo ""
    echo "  STRIKE ZONE KEYWORDS (⚡ ready to push):"
    echo "  ┌───────────────────────────────────────────────────────────────┐"
    printf "  │ %-38s %6s %6s %8s │\n" "KEYWORD" "POS" "CLICKS" "IMPRESS"
    echo "  ├───────────────────────────────────────────────────────────────┤"
    echo "$CURRENT_DATA" | jq -r '[.[] | select(.position >= 5 and .position <= 20)] |
      sort_by(.position) | .[0:20] | .[] |
      [.keyword, (.position|tostring), (.clicks|tostring), (.impressions|tostring)] | @tsv' | \
    while IFS=$'\t' read -r kw pos clicks impr; do
      printf "  │ %-38s %6s %6s %8s │\n" "${kw:0:38}" "$pos" "$clicks" "$impr"
    done
    echo "  └───────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  Run again next week to see movement."
    echo ""
  fi
  exit 0
fi

# --- Diff against previous snapshot ---
PREV_DATA=$(jq '.rows' "$PREV_SNAPSHOT")
PREV_DATE=$(jq -r '.date' "$PREV_SNAPSHOT")
log "Comparing against snapshot from $PREV_DATE..."

DIFF=$(jq -n \
  --argjson current "$CURRENT_DATA" \
  --argjson prev "$PREV_DATA" \
  --argjson strike_min "$STRIKE_MIN" \
  --argjson strike_max "$STRIKE_MAX" '
  ($current | map({(.keyword): .}) | add) as $curr_map |
  ($prev | map({(.keyword): .}) | add) as $prev_map |
  
  {
    climbing: [
      $current[] |
      select($prev_map[.keyword] != null) |
      select(.position < $prev_map[.keyword].position) |
      {
        keyword: .keyword,
        page: .page,
        old_position: $prev_map[.keyword].position,
        new_position: .position,
        change: ($prev_map[.keyword].position - .position | (. * 10 | round | . / 10)),
        clicks: .clicks,
        in_strike_zone: (.position >= $strike_min and .position <= $strike_max)
      }
    ] | sort_by(.change) | reverse,
    
    dropping: [
      $current[] |
      select($prev_map[.keyword] != null) |
      select(.position > $prev_map[.keyword].position) |
      {
        keyword: .keyword,
        page: .page,
        old_position: $prev_map[.keyword].position,
        new_position: .position,
        change: (.position - $prev_map[.keyword].position | (. * 10 | round | . / 10)),
        clicks: .clicks,
        in_strike_zone: (.position >= $strike_min and .position <= $strike_max)
      }
    ] | sort_by(-.change),
    
    new_entries: [
      $current[] |
      select($prev_map[.keyword] == null) |
      {
        keyword: .keyword,
        page: .page,
        position: .position,
        clicks: .clicks,
        in_strike_zone: (.position >= $strike_min and .position <= $strike_max)
      }
    ] | sort_by(.position),
    
    strike_zone_ready: [
      $current[] |
      select(.position >= $strike_min and .position <= $strike_max) |
      {
        keyword: .keyword,
        page: .page,
        position: .position,
        prev_position: ($prev_map[.keyword].position // null),
        clicks: .clicks,
        impressions: .impressions
      }
    ] | sort_by(.position),
    
    losing_ground: [
      $current[] |
      select($prev_map[.keyword] != null) |
      select(.position > $prev_map[.keyword].position) |
      select(.clicks > 5) |
      {
        keyword: .keyword,
        page: .page,
        old_position: $prev_map[.keyword].position,
        new_position: .position,
        drop: (.position - $prev_map[.keyword].position),
        clicks: .clicks
      }
    ] | sort_by(-.drop)
  }
')

if [[ "$JSON_MODE" == true ]]; then
  echo "$DIFF" | jq --arg site "$SITE" --arg date "$TODAY" --arg prev_date "$PREV_DATE" \
    '. + {site: $site, date: $date, compared_to: $prev_date}'
else
  CLIMBING=$(echo "$DIFF" | jq '.climbing | length')
  DROPPING=$(echo "$DIFF" | jq '.dropping | length')
  NEW=$(echo "$DIFF" | jq '.new_entries | length')
  STRIKE=$(echo "$DIFF" | jq '.strike_zone_ready | length')
  LOSING=$(echo "$DIFF" | jq '.losing_ground | length')

  echo ""
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║        SEO MONITOR — $TODAY (vs $PREV_DATE)      ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo ""
  printf "  Site: %s\n" "$SITE"
  printf "  📈 Climbing: %s  |  📉 Dropping: %s  |  🆕 New: %s\n" "$CLIMBING" "$DROPPING" "$NEW"
  printf "  ⚡ Strike zone: %s  |  🚨 Losing ground: %s\n" "$STRIKE" "$LOSING"
  echo ""

  if [[ "$CLIMBING" -gt 0 ]]; then
    echo "  📈 CLIMBING (biggest movers):"
    echo "$DIFF" | jq -r '.climbing[0:10][] |
      "  \(.keyword[0:40]) \(.old_position) → \(.new_position) (+\(.change))\(if .in_strike_zone then " ⚡" else "" end)"'
    echo ""
  fi

  if [[ "$STRIKE" -gt 0 ]]; then
    echo "  ⚡ STRIKE ZONE — Push these now:"
    echo "  ┌────────────────────────────────────────────────────────────────┐"
    printf "  │ %-40s %6s %6s │\n" "KEYWORD" "POS" "CLICKS"
    echo "  ├────────────────────────────────────────────────────────────────┤"
    echo "$DIFF" | jq -r '.strike_zone_ready[] |
      [.keyword, (.position|tostring), (.clicks|tostring)] | @tsv' | \
    while IFS=$'\t' read -r kw pos clicks; do
      printf "  │ %-40s %6s %6s │\n" "${kw:0:40}" "$pos" "$clicks"
    done
    echo "  └────────────────────────────────────────────────────────────────┘"
    echo ""
  fi

  if [[ "$LOSING" -gt 0 ]]; then
    echo "  🚨 LOSING GROUND — Act before these slip further:"
    echo "$DIFF" | jq -r '.losing_ground[0:5][] |
      "  \(.keyword[0:45]) pos \(.old_position) → \(.new_position) (was getting \(.clicks) clicks)"'
    echo ""
  fi

  if [[ "$DROPPING" -gt 0 ]]; then
    echo "  📉 OTHER DROPS (top 5):"
    echo "$DIFF" | jq -r '.dropping[0:5][] |
      "  \(.keyword[0:45]) \(.old_position) → \(.new_position)"'
    echo ""
  fi

  echo "  Next: Run seo-discover.sh to find supporting content opportunities"
  echo "        Feed strike zone keywords back as --seeds"
  echo ""
fi
