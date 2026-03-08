# SEO Kit Setup Guide

## 1. Google Search Console Authentication

You need OAuth2 credentials to access the GSC API.

### Option A: Use gog CLI (Recommended if you have it)

If you already have `gog` installed, use it for the Search Console OAuth flow.

If you need to install it first, see the gog docs: [gogcli.sh](https://gogcli.sh).

`gog` is Peter Steinberger's Google Workspace CLI and works well for managing Google auth from the terminal.

Set it up like this:

```bash
# 1) Save your Google OAuth client JSON somewhere local
# 2) Register it with gog
gog auth credentials ~/.config/gsc-credentials.json

# 3) Add your Google account and grant access
gog auth add you@gmail.com --services webmasters

# 4) Confirm the account is available
gog auth list
```

After that, `gog` manages the OAuth flow for you and the SEO scripts can use the authenticated account for Search Console access.

### Option B: Manual OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project (or use existing)
3. Enable "Search Console API"
4. Create OAuth 2.0 credentials (Desktop application type)
5. Download the JSON and save as `~/.config/gsc-credentials.json`
6. Run the auth flow:

```bash
bash seo-agent/scripts/seo-check.sh
```

It will prompt you to visit a URL, authorize, and paste the code back.

### Verify GSC Access

```bash
bash seo-agent/scripts/seo-check.sh
```

This lists all sites you have access to in Search Console.

---

## 2. DataForSEO (Optional but Recommended)

DataForSEO provides keyword research, search volumes, and competitor data.

### Sign Up

1. Go to [dataforseo.com](https://dataforseo.com)
2. Create an account (starts at $50/month)
3. Get your login email and API password from the dashboard

### Configure

```bash
echo 'export DATAFORSEO_LOGIN="your-email@example.com"' >> ~/.bashrc
echo 'export DATAFORSEO_PASSWORD="your-api-password"' >> ~/.bashrc
source ~/.bashrc
```

### Without DataForSEO

The agent falls back to web search (Brave Search API via OpenClaw) for keyword ideas. You get less data (no exact search volumes, no keyword difficulty scores) but the core loop still works.

---

## 3. Install Skills in OpenClaw

Copy both skill directories into your OpenClaw workspace:

```bash
cp -r seo-agent ~/clawd/skills/
cp -r seo-forge ~/clawd/skills/
```

Make scripts executable:

```bash
chmod +x ~/clawd/skills/seo-*/scripts/*.sh

```

---

## 4. First Run

### Health Check

Tell your agent: "Run seo-check to verify my GSC and DataForSEO connections"

### Brand Interview

Tell your agent: "Run the SEO Forge brand interview for my site"

This creates:
- `workspace/brand/voice-profile.md` (how you sound)
- `workspace/brand/audience.md` (who you're writing for)
- `workspace/brand/positioning.md` (what makes you different)

### First Discovery

Tell your agent: "Run SEO discover on sc-domain:yourdomain.com"

### First Article

Tell your agent: "Write an SEO article targeting [keyword from discovery]"

---

## 5. Set Up the Weekly Loop

Add these to your OpenClaw cron:

**Monday morning:** "Run seo-discover and seo-monitor on my site. Send me the report."

**Wednesday:** "Write one article targeting the top opportunity from Monday's discovery."

**Friday:** "Run seo-compete against [competitor domain]. Add new opportunities to my keyword list."

The agent handles everything else.

---

## Troubleshooting

**"No GSC token found"**
Run `seo-check.sh` to trigger the auth flow, or check that `~/.config/google-analytics-token.json` exists.

**"DataForSEO returned 401"**
Check your credentials in `~/.bashrc`. The password is the API password from the DataForSEO dashboard, not your account login password.

**"No sites found in Search Console"**
Make sure you've verified your site in [Google Search Console](https://search.google.com/search-console). The API only returns verified properties.

**Scripts not executable**
```bash
chmod +x ~/clawd/skills/seo-*/scripts/*.sh
```
