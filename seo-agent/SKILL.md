---
name: seo-agent
description: "Self-improving SEO system. Finds keywords via DataForSEO, writes content that ranks, monitors GSC for what's climbing, then writes MORE content to push winners higher. A feedback loop, not a one-shot tool."
metadata:
  openclaw:
    emoji: "🔄"
    user-invocable: true
    homepage: https://thevibemarketer.com
    requires:
      env:
        - DATAFORSEO_LOGIN
        - DATAFORSEO_PASSWORD
      tools: ["curl", "jq"]
---

# SEO Agent — The Self-Improving SEO Loop

Most SEO tools do one thing. Discover keywords. Write content. Check rankings. Done.

This isn't that.

The SEO Agent is a **feedback loop** — a system that finds opportunities, acts on them, watches what happens, and feeds those results back into the next round of work. Every cycle makes the next cycle smarter. Rankings climb. The content library grows. And you're always pushing the keywords that are *already moving* instead of starting from scratch.

> "Don't just rank. Rank, learn, and rank higher."

---

## The Loop

```
DISCOVER → WRITE → MONITOR → OPTIMIZE → REPEAT
```

**1. DISCOVER** (`seo-discover.sh`)
Pull your current GSC rankings. Find what's in the strike zone (positions 5-20). Hit DataForSEO for related keywords you're missing. Score opportunities by volume, competition, and current position. Output a prioritized hit list.

**2. WRITE** (You + Claude)
Take the top opportunity from discovery. Generate publication-ready SEO content — outline, draft, optimized headers, FAQs, schema markup. Brand voice from `workspace/brand/voice-profile.md` baked in.

**3. MONITOR** (`seo-monitor.sh`)
Run weekly. Pull current GSC data. Compare to last snapshot. Flag what's climbing, what's dropping, what just cracked the strike zone. This is your radar.

**4. OPTIMIZE** (`seo-compete.sh` + Claude)
Take the winners from monitoring — content climbing from 15 → 8. Write supporting articles that link to them. Add internal links from existing content. Push the climbers over the finish line.

**5. REPEAT**
Discovery now has more context. Monitor has more history. Every loop compounds.

---

## The Strike Zone

Positions 5–20 are where SEO leverage lives.

- **Position 1–4**: Already winning. Defend.
- **Position 5–20**: ⚡ **THE STRIKE ZONE** — close enough to move, not yet getting the clicks. A supporting article, better internal links, or a refreshed page can jump these 5–10 spots. That's the difference between 2% CTR and 8% CTR.
- **Position 21+**: Too far out. Needs a full content build.

The Agent focuses energy here by default.

---

## Scripts

All scripts live in `~/clawd/skills/seo-agent/scripts/`. All use bash + curl + jq. No Python. No npm.

### seo-discover.sh — Find Your Next Opportunity

```bash
./seo-discover.sh --site sc-domain:example.com [--seeds "keyword1,keyword2"] [--limit 20]
```

What it does:
1. Pulls your GSC top queries (last 28 days)
2. Filters for strike zone keywords (positions 5–20)
3. Hits DataForSEO for keyword suggestions around your top queries
4. Gets search volume + competition for all candidates
5. Scores and ranks opportunities
6. Outputs a prioritized JSON list

**Output fields:** `keyword`, `current_position`, `search_volume`, `competition`, `opportunity_score`

Add `--json` for raw machine-readable output. Default is a human-readable table.

### seo-monitor.sh — Track What's Moving

```bash
./seo-monitor.sh --site sc-domain:example.com [--days 28]
```

What it does:
1. Pulls current GSC data
2. Loads previous snapshot from `~/clawd/workspace/seo-agent/snapshots/`
3. Diffs positions: climbing, dropping, new entries
4. Highlights strike zone keywords ready to push
5. Flags content losing ground (act before it falls further)
6. Saves new snapshot for next comparison

Snapshots stored at: `~/clawd/workspace/seo-agent/snapshots/SITE-YYYY-MM-DD.json`

### seo-compete.sh — Find Their Keywords, Take Them

```bash
./seo-compete.sh --site example.com --competitor competitor.com [--limit 30]
```

What it does:
1. Uses DataForSEO to find all keywords your competitor ranks for
2. Cross-references against your rankings
3. Returns the gap — keywords they're winning that you're not targeting
4. Scored by their position + search volume (easiest wins first)

This feeds directly back into DISCOVER as a seed list.

---

## Configuration

On first use, create `~/clawd/workspace/seo-agent/config.yaml`:

```yaml
site: "sc-domain:example.com"
competitors:
  - competitor1.com
  - competitor2.com
content_directory: "./content"
monitor_frequency: "weekly"
target_positions: [5, 20]   # the strike zone
min_search_volume: 100
```

Scripts read this config automatically. Override any setting with CLI flags.

---

## Setup

### 1. DataForSEO Credentials
```bash
export DATAFORSEO_LOGIN=your@email.com
export DATAFORSEO_PASSWORD=yourpassword
```

### 2. Google Search Console Auth
Same auth as `gsc-report`. If you've set that up, you're ready.

Options:
- `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json`
- `gcloud auth application-default login`
- `export GOOGLE_ACCESS_TOKEN=ya29.xxx`

### 3. Your Site URL
Find your exact property URL in [Search Console](https://search.google.com/search-console). It's either:
- `https://example.com` (URL prefix property)
- `sc-domain:example.com` (domain property — broader, recommended)

### 4. (Optional) Brand Voice
Drop your brand voice profile at `~/clawd/workspace/brand/voice-profile.md`. The agent reads this when generating content briefs and drafts. Run the `brand-voice` skill first if you haven't.

---

## Running the Full Loop

**Week 1 — Discovery**
```
Run: seo-discover.sh --site your-site --limit 20
Output: Prioritized keyword hit list
Action: Pick top 3 opportunities → generate content with Claude
```

**Week 2+ — Monitor + Optimize**
```
Run: seo-monitor.sh --site your-site
Output: What moved, what's in strike zone
Action: Find climbers → write supporting content → add internal links
```

**Ongoing — Compete**
```
Run: seo-compete.sh --site your-site --competitor their-site
Output: Their keywords, your gaps
Action: Feed gaps back into discovery as seeds
```

---

## How Claude Uses This

When you run the SEO Agent loop, Claude:

1. **Reads** discovery output → selects the best opportunity based on your goals
2. **Generates** a full content brief: target keyword, secondary keywords, outline, angle, word count, FAQ section, schema markup suggestions
3. **Drafts** the article (or hands off outline for your writer)
4. **Reads** monitor output → identifies what to optimize next
5. **Writes** supporting articles with internal link strategy built in
6. **Updates** `workspace/brand/learnings.md` with what's working

---

## DataForSEO Endpoints Used

| Purpose | Endpoint |
|---------|----------|
| Keyword volume | `POST /v3/keywords_data/google_ads/search_volume/live` |
| Related keywords | `POST /v3/keywords_data/google_ads/keywords_for_keywords/live` |
| Keyword expansion | `POST /v3/dataforseo_labs/google/keyword_suggestions/live` |
| SERP check | `POST /v3/serp/google/organic/live/advanced` |
| Competitor keywords | `POST /v3/dataforseo_labs/google/competitors_domain/live` |
| Keyword gaps | `POST /v3/dataforseo_labs/google/domain_intersection/live` |

API base: `https://api.dataforseo.com`
Auth: HTTP Basic — `$DATAFORSEO_LOGIN:$DATAFORSEO_PASSWORD`

---

## Output Files

| Path | Contents |
|------|----------|
| `workspace/seo-agent/snapshots/SITE-DATE.json` | Weekly ranking snapshots |
| `workspace/seo-agent/config.yaml` | Your site config |
| `workspace/brand/learnings.md` | Ranking insights (appended) |
| `workspace/brand/keyword-plan.md` | Active keyword targets |

---

## Why This Works

Most people do SEO once and forget it. They publish and pray.

The SEO Agent turns SEO into a system. Every week you know:
- What moved
- Why it moved
- What to do next

Compound that for 6 months and you've got a content moat competitors can't buy their way out of.

The scripts are the engine. You (and Claude) are the brain. Together, that's the loop.
