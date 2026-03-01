---
name: seo-forge
description: "Matt Berman's custom SEO content engine. Learns your brand through a smart interview, then creates content that ranks AND converts using Puppet Strings, Scroll Traps, and Care To Click psychology. Anti-AI-Overview by design. DataForSEO integrated. The content your competitors can't copy because it requires real experience."
metadata:
  openclaw:
    version: "1.0"
    author: "Matt Berman"
    emoji: "⚒️"
    user-invocable: true
    category: "seo"
    requires:
      env: []
    optional_env:
      - DATAFORSEO_LOGIN
      - DATAFORSEO_PASSWORD
---

# SEO Forge

Most SEO content is dead on arrival. It ranks for 60 days, gets killed by an AI Overview update, and leaves you with nothing. No authority. No trust. No brand.

SEO Forge is built differently.

It starts by learning who you are. Then it creates content that could only come from you — anchored in your experience, shaped by your voice, structured with psychology frameworks that make people actually read, believe, and act.

Google's AI Overview can summarize any generic article. It can't summarize your story, your client results, or your contrarian take. That's the moat. That's what this builds.

**What makes this different from every other SEO skill:**
- The agent learns your brand before it writes a word
- Every article gets scored against the "Only I Can Write This" test
- Psychology frameworks (Puppet Strings, Scroll Traps, Care To Click) are baked into every section
- Anti-AI-Overview checkpoints throughout the drafting process
- DataForSEO integration for live SERP data (falls back to web search if not configured)
- Voice rules that produce content sounding like a smart human, not a content mill

---

## Three Operating Modes

Before writing a single word, SEO Forge checks your brand context. The mode it chooses shapes everything.

---

### Mode A: First Run Interview

**Triggers when:** No `workspace/brand/` directory exists, or `voice-profile.md` is empty.

The agent runs an 8-question brand interview. This is the differentiator. Other SEO skills assume you're generic. SEO Forge assumes you're not.

**The interview questions:**

1. What do you sell? What's the product or service, specifically?
2. Who buys it? Describe your best customer in one paragraph.
3. What do they struggle with before they find you? What's the pain they can actually feel?
4. What makes you different from competitors? Be specific. Not "we're better" — what's the actual difference?
5. What's your voice like? Pick one: Direct & blunt / Warm & approachable / Technical & precise / Playful & irreverent / Academic & authoritative
6. Share a sentence or two you've actually written — an email, post, text. Something that sounds like you.
7. What 3 topics could you write about better than anyone else because of real experience you've had?
8. Name 2-3 competitors you respect (or hate).

**After the interview, the agent auto-generates:**
- `workspace/brand/voice-profile.md`
- `workspace/brand/audience.md`
- `workspace/brand/positioning.md`
- `workspace/brand/competitors.md`

The agent shows what was generated, asks if anything's off, then saves. Then proceeds to content creation.

**Why this matters:** Every article after this will carry your brand DNA. The content compounds. A year from now you'll have a library of content that sounds like you, not a content farm.

---

### Mode B: Weekly Refinement

**Triggers when:** Brand context exists AND it's been 7+ days since last refinement (tracked in `workspace/brand/learnings.md`).

The agent runs a quick check-in before writing:

> "Quick brand check-in before we write. Takes 2 minutes:"
> - What content performed well recently?
> - Any new products, features, or offers?
> - Questions customers keep asking you?
> - Anything that changed about your audience or positioning?

The agent updates brand files, logs the refinement date, and proceeds.

**User can always say "skip"** — content creation never blocks on refinement. The check-in is a prompt, not a gate.

**Why this matters:** Brand context that doesn't update becomes stale. The weekly refinement is what makes SEO Forge compound. The longer you use it, the sharper it gets.

---

### Mode C: Fast Mode (No Interview)

**Triggers when:** User explicitly skips the interview, or just wants content fast with no brand setup.

The agent uses sensible defaults:
- Voice: Direct, conversational, specific. Sounds like a smart friend who knows the topic.
- No brand-specific angles (general authority positioning)
- All psychology frameworks still apply
- Full SERP research still runs

At the end, the agent notes:

> "This would hit harder with your brand voice loaded. Run `/seo-forge interview` anytime to set that up."

---

## The Psychology Frameworks

Every article runs through all three. This isn't optional. The frameworks are what make the content convert, not just rank.

---

### Puppet Strings (Why People Care)

Every article targets one primary human drive. This shapes the hook, the framing, the examples, and the CTA.

| Drive | What It Promises |
|-------|-----------------|
| Wealth | Financial freedom, income, options, security |
| Health | Physical wellness, mental health, longevity |
| Status/Access | Recognition, power, exclusive circles |
| Escape | Relief from the grind, pain, boredom |
| Romance | Connection, attraction, belonging |

Fear is NOT a drive. It's an amplifier. "You're losing wealth" hits harder than "gain wealth."

**Before outlining, the agent declares:**

> "Primary drive: Wealth. Fear amplification: Yes — framed as 'your competitors are already doing this.' Here's why this shapes the article..."

This isn't ceremony. It's the decision that makes everything downstream sharper.

**Bad:** An article about "how to increase revenue" that never commits to a primary drive. It mentions money, success, freedom, and stress all at once. The reader feels nothing.

**Good:** An article that commits to Wealth + fear amplification. Every section reinforces a specific financial outcome. The intro costs them something if they don't keep reading.

---

### Scroll Traps (The First 300 Words)

The intro must use at least 2-3 of these techniques. The first 300 words are everything. If they don't stay, the ranking is worthless.

**1. Term Branding**
Name the concept. Give it a proper noun. Named ideas spread.
- Bad: "There's a way to structure your content so it ranks better."
- Good: "The Content Moat strategy has one rule: publish what AI can't summarize."

**2. Embedded Truths**
Remove all hedge words. Replace "if" with "when", "maybe" with "the reason why."
- Bad: "If you use this approach, you might see better results."
- Good: "When you use this approach, here's what actually changes."

**3. Thought Narration**
Say what the reader is thinking right now. Instant trust.
- Bad: Opening paragraph about the topic's history.
- Good: "You're probably wondering if SEO is even worth it in 2026. Fair question."

**4. Pattern Interrupt**
Break the expected flow. Short sentence. Then longer ones. Question left hanging.
- Bad: Paragraph after paragraph of equal-length sentences.
- Good: "Three years. That's how long it took one client to rank for a term their competitors owned."

**5. Specificity**
"47 brands" not "many brands." "$2,400/month" not "significant cost."
- Bad: "Many companies have seen results using this strategy."
- Good: "23 companies in our study used this strategy. 19 saw first-page rankings within 90 days."

**6. Tribal Signaling**
"If you've ever X, this is for you."
- Bad: Generic opener that could apply to anyone.
- Good: "If you've spent $10K on content that ranked for 6 weeks and then disappeared, this is for you."

---

### Care To Click (Persuasion Arc)

Every article follows this emotional progression. Map each section to a stage before drafting.

| Stage | Goal | What It Does |
|-------|------|-------------|
| **Care** | Make them feel the problem | Intro. Twist the knife. Make the cost of ignoring this real. |
| **Believe** | Make them trust you | Data, specific results, your real experience. |
| **See** | Make them see the path | Examples, case studies, numbered systems. |
| **Want** | Make them want the outcome | Benefits made personal. "Here's what your life looks like after." |
| **Stay** | Make them keep reading | Loop openers. "But here's where it gets interesting." |
| **Click** | Make them act | Native CTA. Closes the loop opened in the intro. |

Short articles cover Care, Believe, and Click. Long-form articles run all six.

**The mapping is shown before drafting:**

> "Care → Click Arc:
> - Care: Open with the cost of bad SEO content. Specific dollar amount.
> - Believe: Client result. 3 months, first page, exact keyword.
> - See: The 8-phase process with real examples for each.
> - Want: What their content library looks like 12 months from now.
> - Stay: Loop openers at sections 3, 5, and 7.
> - Click: Free content audit CTA that ties back to the intro."

---

## The "Only I Can Write This" Test

This replaces every generic quality checklist.

**The question:** "What sentence in this article could ONLY come from someone with real experience? If there isn't one, the article will lose to the next person who has one."

Every article must have at least 3 experience anchors — specific stories, numbers, or insights that couldn't be synthesized from other articles on the internet.

**If brand interview revealed experience areas:** Use them. Pull specifics from the interview.

**If no brand context exists:** Flag it:

> "This article needs your personal touch in sections 2 and 5. Here are prompts to help you add your experience:
> - Section 2: What's the worst-performing piece of content you've ever published? What happened?
> - Section 5: What result surprised you most using this approach with a real client or project?"

**Bad experience anchor:** "Many marketers have found that consistency is key."

**Good experience anchor:** "I ran this strategy for a spirits brand in 2022. We went from zero organic traffic to 40K monthly visitors in 8 months. The one change that did it wasn't the keyword strategy — it was adding the founder's actual opinions to every article."

---

## Anti-AI-Overview Strategy

Google's AI Overview can answer any generic query before a user clicks. Your content has to go where AIO can't.

**AIO can't touch:**
- Personal stories and first-hand experience
- Proprietary data or original research
- Contrarian takes with specific reasoning
- Specificity that can't be synthesized ("we tested this across 47 accounts over 6 months")
- Interactive elements, tools, templates
- Expert opinions that require judgment calls

**At each major section, the agent checks:**

> "Could Google's AI Overview answer this section from publicly available sources? If yes, go deeper or go personal."

This isn't a box-checking exercise. It's the editorial standard. Any section that AIO could fully answer gets flagged for either deeper specificity or a personal angle.

---

## DataForSEO Integration

When `DATAFORSEO_LOGIN` and `DATAFORSEO_PASSWORD` are set in your environment, the agent pulls live data before writing.

**What it pulls:**
- Top 10 SERP results for the target keyword (titles, URLs, descriptions, estimated word counts)
- People Also Ask questions (all of them — these become mandatory sections)
- Search volume and competition score
- Related keywords for the content cluster

**If DataForSEO is not configured:** Falls back to web_search for SERP analysis and PAA extraction. Never blocks. Notes the data source at the top.

**Research quality signal:**

> "Research mode: DataForSEO live data" or "Research mode: Web search (DataForSEO not configured)"

Use `scripts/seo-research.sh` to run the data pull independently.

---

## Matt's Voice Rules

These apply to ALL content, on top of whatever brand voice is configured. Non-negotiable.

**Never use:**
- Em dashes — use commas, periods, colons, or restructure the sentence
- Corporate speak: leverage, harness, cutting-edge, innovative, revolutionary, game-changer, robust, streamline, facilitate, comprehensive, utilize
- AI-isms: delve, landscape, tapestry, myriad, nuanced, seamless, "in today's fast-paced world", "it's worth noting", "let's dive in"
- Hedge words: might, perhaps, arguably, it could be said

**Always use:**
- Contractions (don't, won't, can't — never do not, will not, cannot)
- Short paragraphs (2-3 sentences max)
- Specific numbers ("47 brands" not "many brands", "$2,400/month" not "significant cost")
- Stories over theory ("I ran this for a client" beats "Research shows")

---

## The Full Workflow

```
CHECK MODE → RESEARCH → BRIEF → OUTLINE → DRAFT → HUMANIZE → OPTIMIZE → SCHEMA → REVIEW → SAVE
```

---

### Phase 0: Mode Check

Run `scripts/seo-check.sh` to determine operating mode:
- No brand context → Mode A (Interview)
- Brand context exists, 7+ days since refinement → Mode B (Quick check-in)
- Brand context exists, recent → Mode C default (skip check-in, proceed)
- User explicitly skipped → Fast Mode

Load brand context per the _vibe-system protocol. SEO Forge reads: voice-profile.md, audience.md, positioning.md, competitors.md, keyword-plan.md, learnings.md.

---

### Phase 1: Research

This phase is not optional when web tools are available.

**If DataForSEO is configured:** Run `scripts/seo-research.sh "[keyword]"` to pull live SERP data, PAA, volume, and related keywords.

**If DataForSEO is not configured:** Run web searches for the target keyword. Capture the top 5 results: titles, URLs, content types, structure, angles, gaps.

**What to capture:**
- Top 5-10 SERP results: title, URL, content type, apparent word count, unique angles, gaps
- All People Also Ask questions (these become mandatory sections or FAQ entries)
- Featured Snippet format (if present)
- AI Overview presence (if present — note what it covers, because that's what you must go beyond)

**Gap analysis:**
1. What's missing? Questions unanswered, angles unexplored.
2. What's outdated? Old information, deprecated methods.
3. What's generic? Surface-level advice anyone could give.
4. What's the AIO blind spot? What can't the AI Overview synthesize?

---

### Phase 2: Puppet Strings Assignment

Before outlining, declare the psychology:

> "Primary drive: [X]
> Fear amplification: [Yes/No]
> Why this drive fits this keyword: [2-3 sentences]
> How it shapes the article: [Hook will..., Examples will..., CTA will...]"

This isn't ceremony. It determines every creative decision in the draft.

---

### Phase 3: Content Brief

```
Target Keyword: [keyword]
Secondary Keywords: [from PAA + related]
Search Intent: [Informational / Commercial / Transactional]
Content Type: [Pillar Guide / How-To / Comparison / Listicle]
Target Word Count: [based on competitor analysis]
Primary Drive: [Puppet Strings assignment]
Fear Amplification: [Yes/No]
Unique Angle: [what makes our take different — informed by positioning.md]
AIO Blind Spot: [what Google's AI Overview can't cover here]
Care To Click Arc: [mapped]
Experience Anchors Needed: [3 specific areas]
PAA Questions to Cover: [list]
Competitor Gaps: [list]
CTA: [what action should readers take]
```

---

### Phase 4: Outline

Structure the outline with the Care To Click arc mapped to sections.

Every outline includes:
- **Hook** (Scroll Traps — at least 2-3 techniques, called out by name)
- **Quick Answer / TL;DR** (for skimmers; also grabs Featured Snippet)
- **H2 sections** mapped to PAA questions
- **Experience anchor callouts** (3+ sections where personal experience is required)
- **AIO checkpoint flags** on sections that risk being generic
- **Loop opener placements** (every 2-3 major sections)
- **FAQ section** (schema-ready format)
- **CTA** (closes the loop opened in the intro)

---

### Phase 5: Draft

Write with voice-profile.md loaded. If no profile exists, use: direct, conversational, specific, opinionated.

**The first paragraph rule:** Answer the search query in the first 2-3 sentences. Don't make them scroll.

- Bad: "In today's competitive digital landscape, brands are increasingly turning to content marketing..."
- Good: "SEO content fails for one reason: it says nothing that only you could say. Here's how to fix that in 8 steps, with examples from real campaigns."

**At each experience anchor callout:** Pause and inject personal experience. If no brand interview data exists, write a placeholder: `[EXPERIENCE ANCHOR: Add your story/result about X here]`

**At each AIO checkpoint:** Ask: "Could an AI Overview answer this from public sources?" If yes, go deeper or inject a specific data point / personal story.

**The "So What?" chain:** For every point made, ask "so what?" until you hit something the reader actually cares about. Write from the bottom of the chain up.

---

### Phase 6: Humanize

Run every draft through this list before moving on.

**Kill on sight:**
- AI words: delve, comprehensive, crucial, leverage, landscape, streamline, robust, utilize, facilitate, unlock, unleash, game-changer, tapestry, myriad, nuanced, seamless
- AI phrases: "In today's fast-paced world", "It's important to note", "Let's dive in", "Without further ado", "This comprehensive guide"
- Hedge words: might, perhaps, arguably, it could be said, possibly, potentially
- Em dashes (replace with comma, period, colon, or restructure)

**Inject:**
- Contractions everywhere (don't, won't, isn't)
- Short paragraphs (2-3 sentences max — if you've written 4 in a row, split them)
- Specificity (swap every vague number or claim for a real one)
- Opinions (commit to positions instead of hedging)
- Rhythm variation (short sentence. Then a longer one that develops an idea. Fragment. Question?)

**Scroll Trap audit:**
- Count contrast words (but, except, turns out, instead, however, yet). If zero — the draft is flat.
- Add at least one loop opener per major section: "But here's where it gets weird." / "Turns out." / "And this is the part nobody talks about."
- Confirm Thought Narration at at least one major turning point.

---

### Phase 7: On-Page SEO

- Primary keyword in title (front-loaded), H1, first 100 words, and at least one H2
- Secondary keywords across H2s naturally (don't force them)
- Meta description: under 160 characters, includes primary keyword, has a compelling hook
- Internal links: 4-8 per piece
- External citations: 2-4 for factual claims
- Featured Snippet optimization: match the dominant SERP snippet format

---

### Phase 8: Schema Markup

Generate JSON-LD for every article. Included in the file's YAML frontmatter.

**Article schema:** Always. Includes headline, description, author, dates, publisher, keywords.

**FAQ schema:** Always (every article has a FAQ section). Each PAA question becomes a schema entry.

**HowTo schema:** For how-to tutorial content. Each step becomes a schema entry.

---

### Phase 9: Quality Review

**The "Only I Can Write This" test:**
Run the test on the full draft. Count experience anchors. If fewer than 3, flag the gaps and provide prompts.

**AIO audit:**
Read through every major section. For each one: could an AI Overview fully answer this? If yes, it needs to go deeper.

**Content quality:**
- [ ] Answers title question in first 300 words
- [ ] At least 3 experience anchors (real, specific, not synthesizable)
- [ ] Unique angle present (not just aggregation of existing content)
- [ ] All PAA questions answered
- [ ] SERP gaps addressed
- [ ] Would I bookmark this? Would I share it?

**Voice quality:**
- [ ] No AI-isms
- [ ] No corporate speak
- [ ] No em dashes
- [ ] No hedge words
- [ ] Contractions throughout
- [ ] Short paragraphs
- [ ] Specific numbers
- [ ] Reads naturally out loud

**SEO quality:**
- [ ] Primary keyword in title, H1, first paragraph
- [ ] Secondary keywords in H2s
- [ ] Meta description under 160 characters
- [ ] 4-8 internal links
- [ ] 2-4 external citations
- [ ] Schema markup generated

---

### Phase 10: Save

**File location:** `workspace/campaigns/content/{keyword-slug}.md`

Create `workspace/campaigns/content/` if it doesn't exist.

**Append to:** `workspace/brand/assets.md`

**Log refinement date in:** `workspace/brand/learnings.md`

---

## File Output Format

```yaml
---
title: "[Article Title]"
keyword: "[primary keyword]"
secondary_keywords: ["kw1", "kw2", "kw3"]
intent: "[informational|commercial|transactional]"
content_type: "[pillar-guide|how-to|comparison|listicle]"
word_count: [N]
puppet_string: "[primary drive]"
fear_amplification: [true|false]
scroll_traps_used: ["Term Branding", "Embedded Truths", "..."]
experience_anchors: 3
aio_blind_spots: ["...", "..."]
meta_description: "[under 160 chars]"
created: "[YYYY-MM-DD]"
status: "draft"
schema: |
  [Article JSON-LD here]
  [FAQ JSON-LD here]
---

[Article body here]
```

---

## How This Connects

SEO Forge doesn't work alone. It's one piece of a content system.

**Input from:**
- **keyword-research** → Provides target keyword, cluster, intent, content type, and content briefs
- **positioning-angles** → Finds the unique angle that competitors aren't owning
- **brand-voice** → Defines how the content should sound
- **the-forge** → Psychology framework audit (run finished drafts through The Forge for hook scoring)

**Chains to:**
- **content-atomizer** → Turns the article into LinkedIn posts, tweets, email excerpts
- **seo-agent** → Monitors rankings for the published article, triggers refresh when rankings drop

**The full flow:**
1. Keyword research identifies the opportunity
2. Positioning angles finds the differentiated take
3. Brand voice defines how it should sound
4. **SEO Forge creates the article** (you are here)
5. Content atomizer distributes it across channels
6. SEO agent monitors and triggers refreshes when needed

---

## Invocation

```
/seo-forge [keyword]
/seo-forge interview          → Force brand interview (Mode A)
/seo-forge check              → Check brand context status
/seo-forge refresh [keyword]  → Refresh existing article
```

**Examples:**
- `/seo-forge "how to scale a spirits brand"`
- `/seo-forge "AI marketing tools for agencies" --intent commercial`
- `/seo-forge interview` (set up brand context before writing)
- `/seo-forge refresh "liquor brand marketing"` (update an existing article)

---

## Implementation Notes

When executing this skill as an agent, follow these rules exactly:

1. **Run the mode check first.** Always check brand context status before doing anything else. The operating mode shapes everything.

2. **Never skip SERP research.** When web tools are available, Phase 1 is mandatory. The differentiation comes from knowing what's already ranking and going further.

3. **Declare Puppet Strings before outlining.** The drive assignment is not flavor text. It determines the hook, the framing, the examples, and the CTA. Show it explicitly.

4. **Map the Care To Click arc before drafting.** Every section should map to a stage. Show the mapping.

5. **Flag experience anchor gaps.** If the draft has fewer than 3 experience anchors, surface it. Don't paper over it with generic content. Give the user specific prompts to fill the gaps.

6. **Run AIO checkpoints on every major section.** Could an AI Overview answer this? If yes, it needs to go deeper or go personal.

7. **Apply Matt's voice rules after every draft phase.** No em dashes. No hedge words. No AI-isms. Contractions throughout. Specific numbers always.

8. **Save to disk.** The file is the deliverable, not the terminal output. Create directories if needed.

9. **Generate schema markup.** Article + FAQ JSON-LD for every piece. HowTo schema for tutorial content. Include in frontmatter.

10. **Log the refinement date.** After every article, append to `workspace/brand/learnings.md` with the date, keyword, and key decisions made.

11. **Offer content-atomizer chain.** After saving, always offer to atomize the article into social posts.

12. **Show brand context working.** When voice-profile.md is loaded, mention specifically how it shaped the writing. When positioning.md is loaded, name the angle used.

---

## The Test

Before publishing, every article answers yes to all of these:

1. Does it answer the query better than what's currently ranking?
2. Would an expert in this field approve of the accuracy?
3. Would a reader bookmark or share this?
4. Does it sound like a specific person with real experience, not a content mill?
5. Are there at least 3 things in here that couldn't be synthesized from other articles?
6. Could Google's AI Overview fully answer this? (If yes, it needs revision.)
7. Does it pass Matt's voice rules? (No em dashes, no hedge words, no AI-isms, contractions throughout.)
8. Does it answer ALL People Also Ask questions captured in research?
9. Is schema markup valid and complete?
10. Is it saved to disk with proper frontmatter?

If any answer is no, revise before calling it done.

---

## Feedback Loop

After saving:

> "How did this land? Shipped as-is, minor edits, or major rewrite?"

- **Shipped as-is** → log to learnings.md under "What Works." Note the drive used, the angle, the content type.
- **Minor edits** → ask what changed, log the insight.
- **Major rewrite** → ask what missed. Suggest updating voice-profile.md or running `/positioning-angles` for a sharper angle.
- **Haven't used yet** → note it. Check next session.
