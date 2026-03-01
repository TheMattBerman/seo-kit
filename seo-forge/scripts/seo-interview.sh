#!/usr/bin/env bash
# seo-interview.sh — Brand context check and question generator for SEO Forge
# Usage: seo-interview.sh [--json] [--mode interview|refinement|check]
# Returns: JSON with current mode and questions to ask the user

WORKSPACE="${CLAWD_WORKSPACE:-$HOME/clawd/workspace}"
BRAND_DIR="$WORKSPACE/brand"
JSON_MODE=false
FORCE_MODE=""

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_MODE=true
  [[ "$arg" == "--mode" ]] && shift && FORCE_MODE="$1"
done

# Determine current state
HAS_BRAND_CONTEXT=false
LAST_REFINEMENT=""
DAYS_SINCE=999
MODE=""

if [[ -d "$BRAND_DIR" && -f "$BRAND_DIR/voice-profile.md" ]]; then
  SIZE=$(wc -c < "$BRAND_DIR/voice-profile.md" 2>/dev/null || echo 0)
  [[ "$SIZE" -gt 50 ]] && HAS_BRAND_CONTEXT=true
fi

if [[ -f "$BRAND_DIR/learnings.md" ]]; then
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

# Determine mode (respect --mode override)
if [[ -n "$FORCE_MODE" ]]; then
  MODE="$FORCE_MODE"
elif ! $HAS_BRAND_CONTEXT; then
  MODE="interview"
elif [[ "$DAYS_SINCE" -ge 7 ]]; then
  MODE="refinement"
else
  MODE="ready"
fi

# Interview questions (Mode A: first run)
INTERVIEW_QUESTIONS=(
  "What do you sell? What's the product or service, specifically? (Not what it does — what it IS.)"
  "Who buys it? Describe your best customer in one paragraph. Age, situation, what they do for work, what they're trying to solve."
  "What do they struggle with before they find you? What's the actual pain — not the surface problem, the one underneath it."
  "What makes you different from competitors? Be specific, not 'we're better.' What's the actual difference that a customer would notice on day one?"
  "What's your voice like? Pick one: Direct & blunt / Warm & approachable / Technical & precise / Playful & irreverent / Academic & authoritative"
  "Share a sentence or two you've actually written — an email, a social post, a text. Something that sounds like you, not something polished."
  "What 3 topics could you write about better than anyone because of real experience you've had? Not theory — things you've actually done or been through."
  "Name 2-3 competitors you respect (or can't stand). Just names is fine. We'll research them."
)

# Refinement questions (Mode B: weekly check-in)
REFINEMENT_QUESTIONS=(
  "What content performed well recently? Even one post, one email, anything that got more engagement or conversions than usual."
  "Any new products, features, offers, or changes to what you sell?"
  "What questions are customers asking you lately? The ones that keep coming up."
  "Anything that changed about your audience or how you'd describe your ideal customer?"
)

if $JSON_MODE; then
  case "$MODE" in
    interview)
      # Build JSON array of questions
      Q_JSON="["
      FIRST=true
      for q in "${INTERVIEW_QUESTIONS[@]}"; do
        $FIRST || Q_JSON+=","
        Q_JSON+="$(echo "$q" | jq -Rs .)"
        FIRST=false
      done
      Q_JSON+="]"

      cat <<EOF
{
  "has_brand_context": false,
  "mode": "interview",
  "message": "No brand context found. Run the brand interview to unlock personalized content creation.",
  "questions": $Q_JSON,
  "output_files": [
    "workspace/brand/voice-profile.md",
    "workspace/brand/audience.md",
    "workspace/brand/positioning.md",
    "workspace/brand/competitors.md"
  ]
}
EOF
      ;;

    refinement)
      # Build JSON array of refinement questions
      Q_JSON="["
      FIRST=true
      for q in "${REFINEMENT_QUESTIONS[@]}"; do
        $FIRST || Q_JSON+=","
        Q_JSON+="$(echo "$q" | jq -Rs .)"
        FIRST=false
      done
      Q_JSON+="]"

      cat <<EOF
{
  "has_brand_context": true,
  "mode": "refinement",
  "last_refinement": "$LAST_REFINEMENT",
  "days_since_refinement": $DAYS_SINCE,
  "message": "Brand context found, but ${DAYS_SINCE} days since last refinement. Quick check-in recommended.",
  "questions": $Q_JSON,
  "skip_message": "User can say 'skip' to proceed with existing brand context."
}
EOF
      ;;

    ready)
      cat <<EOF
{
  "has_brand_context": true,
  "mode": "ready",
  "last_refinement": "$LAST_REFINEMENT",
  "days_since_refinement": $DAYS_SINCE,
  "message": "Brand context is current. Ready to create content.",
  "questions": []
}
EOF
      ;;
  esac
else
  # Human-readable output
  case "$MODE" in
    interview)
      echo "=== SEO Forge: Brand Interview ==="
      echo ""
      echo "No brand context found. Before creating content, the agent needs to"
      echo "understand your brand. These 8 questions take about 10 minutes and"
      echo "unlock personalized content that sounds like you, not a content mill."
      echo ""
      echo "Brand Interview Questions:"
      echo ""
      N=1
      for q in "${INTERVIEW_QUESTIONS[@]}"; do
        echo "$N. $q"
        echo ""
        N=$((N+1))
      done
      echo "After the interview, the agent will generate:"
      echo "  - workspace/brand/voice-profile.md"
      echo "  - workspace/brand/audience.md"
      echo "  - workspace/brand/positioning.md"
      echo "  - workspace/brand/competitors.md"
      echo ""
      echo "You'll review what was generated and confirm before anything is saved."
      ;;

    refinement)
      echo "=== SEO Forge: Brand Check-In ==="
      echo ""
      echo "Brand context found, but it's been $DAYS_SINCE days since the last refinement."
      echo "Quick check-in (2 minutes) keeps your content sharp and current."
      echo ""
      echo "Check-In Questions:"
      echo ""
      N=1
      for q in "${REFINEMENT_QUESTIONS[@]}"; do
        echo "$N. $q"
        echo ""
        N=$((N+1))
      done
      echo "Say 'skip' to proceed with existing brand context."
      ;;

    ready)
      echo "=== SEO Forge: Brand Context Ready ==="
      echo ""
      echo "Brand context is current (last refinement: $LAST_REFINEMENT, $DAYS_SINCE days ago)."
      echo "Ready to create content."
      ;;
  esac
fi
