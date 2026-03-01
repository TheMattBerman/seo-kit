# SEO Kit for OpenClaw

An AI agent that finds keywords, writes content, monitors rankings, and self-improves. Two skills that chain into a compounding loop.

**Built by [Matt Berman](https://x.com/TheMattBerman) / [Big Players](https://bigplayers.co)**

---

## What This Does

Most people know what to do for SEO. Nobody does it consistently.

This agent does:

1. **Discovers** keyword opportunities from your actual Google Search Console data
2. **Writes** psychology-driven content in your brand voice (not generic AI slop)
3. **Monitors** rankings weekly and flags what's climbing or dropping
4. **Competes** by finding keywords your competitors rank for that you don't
5. **Repeats** automatically, getting smarter about your brand every week

The loop is the point. Each cycle feeds the next one.

---

## The Two Skills

### seo-agent (Discovery + Monitoring)

The brain that finds opportunities and tracks progress.

| Script | What It Does |
|--------|-------------|
| `seo-discover.sh` | Pulls GSC data, cross-references with DataForSEO, finds strike zone keywords (positions 5-20) |
| `seo-monitor.sh` | Weekly ranking snapshots, flags climbers/droppers, identifies push opportunities |
| `seo-compete.sh` | Competitor gap analysis: keywords they rank for that you don't |

**Data sources:**
- Google Search Console (your real ranking data)
- DataForSEO API (keyword research, search volumes, SERP analysis)

### seo-forge (Content Engine)

The writer that sounds like you, not like ChatGPT.

| Script | What It Does |
|--------|-------------|
| `seo-interview.sh` | 8 questions that build your brand voice, audience, and positioning files |
| `seo-research.sh` | SERP analysis, People Also Ask, search intent classification |
| `seo-check.sh` | Validates your GSC and DataForSEO connections are working |

**What makes it different:**
- **Interview mode**: Learns your brand voice from 8 questions. Content sounds like you wrote it.
- **Weekly refinement**: Asks quick check-in questions to stay current with your business.
- **Psychology frameworks**: Every article targets a core drive and uses proven persuasion structures.
- **Anti-AI-Overview strategy**: Includes personal experience markers that Google's AI can't replicate.
- **"Only I Can Write This" test**: Flags generic content and prompts you to add real experience.

---

## Quick Start

### Prerequisites

- [OpenClaw](https://github.com/openclaw/openclaw) installed and running
- Google Search Console access for your site
- (Optional) [DataForSEO](https://dataforseo.com) API account ($50/month, way less than Ahrefs)

### 1. Clone this repo

```bash
git clone https://github.com/TheMattBerman/seo-kit.git
```

### 2. Copy skills to your OpenClaw workspace

```bash
cp -r seo-kit/seo-agent ~/clawd/skills/
cp -r seo-kit/seo-forge ~/clawd/skills/
```

### 3. Set up Google Search Console auth

Follow the GSC setup in [SETUP.md](./SETUP.md) to get your OAuth token.

### 4. (Optional) Add DataForSEO credentials

```bash
echo 'export DATAFORSEO_LOGIN="your-email"' >> ~/.bashrc
echo 'export DATAFORSEO_PASSWORD="your-api-key"' >> ~/.bashrc
source ~/.bashrc
```

No DataForSEO? The agent falls back to web search for keyword research. Less data, still works.

### 5. Run the health check

```bash
bash seo-agent/scripts/seo-check.sh
```

### 6. Let the agent interview you

Tell your OpenClaw agent: "Run the SEO Forge brand interview"

8 questions. 5 minutes. Every article after this sounds like you.

### 7. Discover your first opportunities

Tell your agent: "Run SEO discover on my site"

### 8. Set it on a schedule

Add a weekly cron in OpenClaw:
- Monday: `seo-discover` + `seo-monitor`
- Tuesday-Thursday: Write content targeting top opportunities
- Friday: `seo-compete` on one competitor

Then forget about it. Check back in a month.

---

## The Self-Improving Loop

```
Week 1: Discover 20 keyword opportunities
         Write 3 articles targeting the best ones

Week 2: Monitor rankings
         2 articles indexed, 1 in strike zone
         Write supporting content for the climber

Week 3: Check GSC again
         Article moved from position 15 to 9
         Run competitor gap, find 8 new opportunities

Week 4: Write 3 more from gap analysis
         First article hits position 6
         Organic traffic up 34%

Repeat forever.
```

---

## Cost

| Service | Cost |
|---------|------|
| OpenClaw | Free (open source) |
| Google Search Console | Free |
| DataForSEO | ~$50/month (optional) |
| **Total** | **$0-50/month** |

Compare that to Ahrefs ($200+/month) or hiring an SEO person ($5,000+/month).

---

## File Structure

```
seo-kit/
  seo-agent/
    SKILL.md          # Full skill instructions for OpenClaw
    scripts/
      seo-discover.sh # Keyword discovery + strike zone finder
      seo-monitor.sh  # Weekly ranking tracker
      seo-compete.sh  # Competitor gap analysis
  seo-forge/
    SKILL.md          # Content engine instructions
    scripts/
      seo-interview.sh # Brand voice interview (8 questions)
      seo-research.sh  # SERP analysis + content research
      seo-check.sh     # Connection health check
  SETUP.md            # Detailed setup guide
  README.md           # This file
```

---

## More OpenClaw Kits

- [meta-ads-kit](https://github.com/TheMattBerman/meta-ads-kit) - AI agent that runs your Meta ads
- [first-1000-kit](https://github.com/TheMattBerman/first-1000-kit) - AI agent that finds your first 1000 customers

---

## License

MIT. Do whatever you want with it.
