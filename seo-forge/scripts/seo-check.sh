#!/usr/bin/env bash
# seo-check.sh — Quick status check for SEO Forge brand context
# Usage: seo-check.sh [--json]
# Returns: Brand context status, file inventory, days since refinement

WORKSPACE="${CLAWD_WORKSPACE:-$HOME/clawd/workspace}"
BRAND_DIR="$WORKSPACE/brand"
JSON_MODE=false

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_MODE=true
done

# Check for brand directory
if [[ ! -d "$BRAND_DIR" ]]; then
  if $JSON_MODE; then
    echo '{"has_brand_context": false, "mode": "interview", "reason": "No workspace/brand/ directory found"}'
  else
    echo "Brand context: NOT FOUND"
    echo "Mode: Interview (Mode A)"
    echo ""
    echo "No workspace/brand/ directory exists. SEO Forge will run the brand"
    echo "interview before creating content."
    echo ""
    echo "To start: /seo-forge interview"
    echo "To skip:  /seo-forge [keyword] (fast mode, no brand context)"
  fi
  exit 0
fi

# Inventory brand files
declare -A FILE_STATUS
BRAND_FILES=("voice-profile.md" "audience.md" "positioning.md" "competitors.md" "learnings.md" "keyword-plan.md")

for f in "${BRAND_FILES[@]}"; do
  if [[ -f "$BRAND_DIR/$f" ]]; then
    SIZE=$(wc -c < "$BRAND_DIR/$f" 2>/dev/null || echo 0)
    if [[ "$SIZE" -gt 50 ]]; then
      FILE_STATUS[$f]="present"
    else
      FILE_STATUS[$f]="empty"
    fi
  else
    FILE_STATUS[$f]="missing"
  fi
done

# Check if we actually have brand context (voice-profile is the key file)
HAS_CONTEXT=false
if [[ "${FILE_STATUS[voice-profile.md]}" == "present" ]]; then
  HAS_CONTEXT=true
fi

# Get days since last refinement
LAST_REFINEMENT=""
DAYS_SINCE=999
if [[ -f "$BRAND_DIR/learnings.md" ]]; then
  # Look for refinement date markers in learnings.md
  LAST_DATE=$(grep -oP '\d{4}-\d{2}-\d{2}' "$BRAND_DIR/learnings.md" 2>/dev/null | tail -1)
  if [[ -n "$LAST_DATE" ]]; then
    LAST_REFINEMENT="$LAST_DATE"
    TODAY=$(date +%Y-%m-%d)
    TODAY_EPOCH=$(date -d "$TODAY" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$TODAY" +%s 2>/dev/null || echo 0)
    LAST_EPOCH=$(date -d "$LAST_DATE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$LAST_DATE" +%s 2>/dev/null || echo 0)
    if [[ "$TODAY_EPOCH" -gt 0 && "$LAST_EPOCH" -gt 0 ]]; then
      DAYS_SINCE=$(( (TODAY_EPOCH - LAST_EPOCH) / 86400 ))
    fi
  fi
fi

# Determine mode
MODE="default"
MODE_REASON=""
if ! $HAS_CONTEXT; then
  MODE="interview"
  MODE_REASON="voice-profile.md is missing or empty"
elif [[ "$DAYS_SINCE" -ge 7 ]]; then
  MODE="refinement"
  MODE_REASON="${DAYS_SINCE} days since last refinement"
fi

if $JSON_MODE; then
  # Build file status JSON
  FILE_JSON="{"
  FIRST=true
  for f in "${!FILE_STATUS[@]}"; do
    $FIRST || FILE_JSON+=","
    FILE_JSON+="\"$f\": \"${FILE_STATUS[$f]}\""
    FIRST=false
  done
  FILE_JSON+="}"

  cat <<EOF
{
  "has_brand_context": $HAS_CONTEXT,
  "mode": "$MODE",
  "mode_reason": "$MODE_REASON",
  "last_refinement": "$LAST_REFINEMENT",
  "days_since_refinement": $DAYS_SINCE,
  "brand_dir": "$BRAND_DIR",
  "files": $FILE_JSON
}
EOF
else
  echo "=== SEO Forge Brand Context Check ==="
  echo ""
  echo "Brand directory: $BRAND_DIR"
  echo "Has brand context: $([ "$HAS_CONTEXT" == "true" ] && echo "YES" || echo "NO")"
  echo "Operating mode: $MODE"
  [[ -n "$MODE_REASON" ]] && echo "Reason: $MODE_REASON"
  echo ""
  echo "File inventory:"
  for f in "${BRAND_FILES[@]}"; do
    STATUS="${FILE_STATUS[$f]}"
    case "$STATUS" in
      present) ICON="✓" ;;
      empty)   ICON="○" ;;
      missing) ICON="✗" ;;
    esac
    printf "  %s  %s  (%s)\n" "$ICON" "$f" "$STATUS"
  done
  echo ""
  if [[ -n "$LAST_REFINEMENT" ]]; then
    echo "Last refinement: $LAST_REFINEMENT ($DAYS_SINCE days ago)"
  else
    echo "Last refinement: Never logged"
  fi
  echo ""
  case "$MODE" in
    interview)
      echo "Next: Run the brand interview before writing content."
      echo "      /seo-forge interview"
      ;;
    refinement)
      echo "Next: Quick brand check-in recommended (7+ days since last)."
      echo "      /seo-forge [keyword] — will prompt check-in"
      echo "      /seo-forge [keyword] skip — bypass check-in"
      ;;
    default)
      echo "Next: Brand context is current. Ready to create content."
      echo "      /seo-forge [keyword]"
      ;;
  esac
fi
