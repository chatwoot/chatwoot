# Influencer Discovery — Implementation Plan

## Context

Framky sells premium wall photo galleries across 10 EU markets. Paid campaigns (PMAX/Meta) yield ROAS 1.32 vs break-even 1.67. Influencer marketing targets ROAS ~3 via barter collaborations with micro-influencers (5–30K followers). This feature integrates IQFluence API into Chatwoot to automate influencer discovery, scoring (FQS), and pipeline management — replacing manual spreadsheet-based workflows.

---

## 1. Database: `influencer_profiles` table

New model linked 1:1 to `Contact`. Separate table (not just `custom_attributes`) because we need indexing, sorting, and structured queries on IQFluence report data.

**Migration** — `db/migrate/YYYYMMDDHHMMSS_create_influencer_profiles.rb`:

| Column | Type | Purpose |
|--------|------|---------|
| `contact_id` | references (unique) | Links to Contact |
| `account_id` | references | Scoping |
| `platform` | string, default: "instagram" | IG/TikTok/YT |
| `username` | string, not null | Platform handle |
| `profile_url` | string | Full profile URL |
| `profile_picture_url` | string | Avatar |
| `fullname` | string | Display name |
| `bio` | text | Profile bio/description |
| `is_verified` | boolean | Verified badge |
| `followers_count` | integer | Followers |
| `following_count` | integer | Following |
| `posts_count` | integer | Total posts |
| `engagement_rate` | float | ER % |
| `avg_reel_views` | float | Avg reel plays |
| `avg_likes` | float | Avg likes |
| `avg_comments` | float | Avg comments |
| `avg_saves` | float | Avg saves |
| `avg_shares` | float | Avg shares |
| `follower_growth_rate` | float | Monthly % |
| `last_post_at` | datetime | Activity check |
| `audience_credibility` | float | 0–1 score |
| `audience_reachability` | float | % reachable |
| `audience_genders` | jsonb | Gender breakdown |
| `audience_ages` | jsonb | Age breakdown |
| `audience_geo` | jsonb | Country/city breakdown |
| `audience_interests` | jsonb | Interest categories |
| `audience_brand_affinity` | jsonb | Brand affinities |
| `top_hashtags` | jsonb | Array of {tag, weight} |
| `interests` | jsonb | User interests |
| `recent_reels` | jsonb | [{url, thumbnail, views, likes, comments}] |
| `stat_history` | jsonb | Monthly follower/engagement history |
| `iqfluence_report_id` | string | Report ID for re-fetching |
| `iqfluence_search_result_id` | string | For unhide API |
| `fqs_score` | integer | 0–100 final score |
| `fqs_stage1_score` | integer | 0–65 |
| `fqs_stage2_score` | integer | 0–35 |
| `fqs_breakdown` | jsonb | {niche_fit:, er_quality:, reel_views:, growth:, audience_quality:, audience_fit:} |
| `status` | integer, default: 0 | Enum (see below) |
| `rejection_reason` | string | Why rejected |
| `target_market` | string | Which EU market this profile targets |
| `report_fetched_at` | datetime | When report was pulled |
| `last_synced_at` | datetime | Last data refresh |

**Indexes**: `[account_id, username]` unique, `[account_id, status]`, `[account_id, fqs_score]`

**Enum `status`**: `discovered: 0, report_pending: 1, report_fetched: 2, approved: 3, rejected: 4, contacted: 5`

**Model**: `app/models/influencer_profile.rb`
- `belongs_to :contact`, `belongs_to :account`
- `has_one` inverse on Contact: add `has_one :influencer_profile` to `app/models/contact.rb`
- Tier method: nano (<10K), micro (<50K), mid (<500K), macro (500K+)

---

## 2. FQS Calculation — Mapped to IQFluence Attributes

### Hard Filters (eliminate before scoring)

| Filter | IQFluence Source | Logic |
|--------|-----------------|-------|
| ER below minimum | `engagement_rate` | Nano <2%, Micro <1.5%, Mid <1% |
| Inactive >60 days | `last_post_at` (from search or scraping `/api/raw/ig/user/feed/`) | Reject |
| Following:Followers >0.8 | `following_count / followers_count` | Reject |
| Growth spike >20%/7d | `stat_history` or search growth field | Reject |
| >50% sponsored posts | `user_profile.paid_post_performance` + top_posts analysis | Reject |
| Outside EU | `user_profile.geo.country` | Reject |
| Audience credibility "bad" | `audience_followers.data.audience_credibility` < 0.6 | Reject (Stage 2 only) |

### Stage 1 (65 pts) — from search results + basic profile

| Dimension | Pts | IQFluence Source | Scoring |
|-----------|-----|-----------------|---------|
| **Niche Fit** | 0–20 | `user_profile.interests[]`, `top_hashtags[]`, `account_category`, bio keywords | Count matching categories against configured list (home, interior, family, photography, DIY). 3+ = 20, 2 = 14, 1 = 8, 0 = 0 |
| **ER + Quality** | 0–20 | `engagement_rate`, `avg_likes / avg_comments` ratio | Compare ER to tier median. ≥2x = 15, ≥1.5x = 11, ≥1x = 8, ≥0.7x = 4, <0.7x = 0. Quality bonus (0–5): healthy likes:comments ratio (100:2–5 = 5, skewed = 0) |
| **Avg Reel Views** | 0–15 | `avg_reels_plays` (report) or calculated from `recent_reels` | Views/followers ratio. ≥3x = 15, ≥2x = 12, ≥1x = 9, ≥0.5x = 5, <0.5x = 0 |
| **Growth Trend** | 0–10 | `stat_history` follower deltas (last 3 months avg) or search `followers_growth` | Monthly %. 2–5% = 10, 1–2% = 7, 0–1% = 4, negative = 0 |

### Stage 2 (35 pts) — from IQFluence report (only for Stage 1 ≥ 50)

| Dimension | Pts | IQFluence Source | Scoring |
|-----------|-----|-----------------|---------|
| **Audience Quality** | 0–20 | `audience_followers.data.audience_credibility`, `audience_followers.data.audience_reachability` | Credibility: ≥0.9 = 12, ≥0.8 = 8, <0.8 = hard reject. Reachability: ≥30% = 8, ≥20% = 5, <20% = 2 |
| **Audience Fit** | 0–15 | `audience_followers.data.audience_geo` (countries), `audience_followers.data.audience_brand_affinity` | Target market % of audience: ≥60% = 10, ≥40% = 7, ≥25% = 4, <25% = 0. Brand affinity overlap with home/decor: match = 5, partial = 3, none = 0 |

### Decision Thresholds
- **≥70**: Auto-approve → tag "influencer", assign to pipeline stage "Qualified"
- **50–69**: Manual review (shown in Review queue)
- **<50**: Auto-reject

### Key Design Decisions

1. **Single API**: IQFluence for both stages. Stage 1 scores from search/basic data, Stage 2 from full report. No Influencers.club integration.
2. **Hardcoded segments**: 3–5 predefined search presets (e.g., "DE micro home decor", "PL family photographers") as constants. Editable UI deferred.
3. **Cost control**: Single report fetch = no confirmation. Bulk fetch (>5) = confirmation dialog with estimated credit cost.

### Niche Categories Configuration
MVP: hardcoded constant `NICHE_CATEGORIES` with keywords/interests for Framky. Later: account-level setting editable in UI.

```ruby
NICHE_CATEGORIES = {
  home: %w[home decor decoration interior house apartment],
  interior: %w[interior design furniture living room bedroom],
  family: %w[family kids children parenting motherhood],
  photography: %w[photography photo portrait lifestyle],
  diy: %w[diy crafts handmade renovation]
}.freeze

SEARCH_PRESETS = {
  'DE micro home decor' => { audience_geo: ['DE'], followers: { min: 5_000, max: 30_000 }, keywords: 'interior home decor wohnzimmer' },
  'PL family photographers' => { audience_geo: ['PL'], followers: { min: 5_000, max: 30_000 }, keywords: 'rodzina zdjecia wnetrza' },
  'FR interior micro' => { audience_geo: ['FR'], followers: { min: 5_000, max: 30_000 }, keywords: 'decoration interieur maison' },
  'NL home lifestyle' => { audience_geo: ['NL'], followers: { min: 5_000, max: 30_000 }, keywords: 'interieur woonkamer binnenkijken' },
  'UK home decor' => { audience_geo: ['GB'], followers: { min: 5_000, max: 30_000 }, keywords: 'homedecor interiordesign gallerywall' },
}.freeze
```

---

## 3. Backend Architecture

### IQFluence API Client — `app/services/iqfluence/`

| File | Responsibility |
|------|---------------|
| `client.rb` | Faraday HTTP wrapper, Bearer auth (`IQFLUENCE_API_KEY` env var), JSON request/response |
| `search_service.rb` | `POST /api/search/newv1/` — builds filter payload, paginates, returns parsed results |
| `report_service.rb` | `GET /api/reports/new/?url=&platform=` — fetches detailed report |
| `scraping_service.rb` | `/api/raw/ig/user/reels/`, `/api/raw/ig/user/info/` — real-time data |
| `response_parser.rb` | Maps IQFluence JSON → `InfluencerProfile` attribute hash |

### Services — `app/services/influencers/`

| File | Responsibility |
|------|---------------|
| `import_service.rb` | Creates Contact (identifier: `ig:<username>`) + InfluencerProfile from search result. Syncs key metrics to `contact.custom_attributes` for pipeline card display. Runs Stage 1 FQS. |
| `fqs_calculator.rb` | Orchestrates hard filters → Stage 1 → Stage 2 (if report exists). Updates profile scores. Returns decision. |
| `fqs/hard_filter.rb` | Pass/fail checks with rejection reason |
| `fqs/stage1_scorer.rb` | 65-point scoring from basic metrics |
| `fqs/stage2_scorer.rb` | 35-point scoring from report data |
| `fqs/niche_matcher.rb` | Matches interests/hashtags against configured categories |
| `approve_service.rb` | Sets status=approved, adds "influencer" label, assigns to pipeline first stage, syncs custom_attributes |
| `reject_service.rb` | Sets status=rejected with reason |

### Controller — `app/controllers/api/v1/accounts/influencer_profiles_controller.rb`

| Action | Method | Purpose |
|--------|--------|---------|
| `index` | GET | List profiles with status/FQS filters, pagination, sorting |
| `show` | GET | Full profile detail with reels |
| `search` | POST | Proxy to IQFluence search, excludes already-imported usernames |
| `import` | POST | Single import from search result |
| `bulk_import` | POST | Batch import |
| `request_report` | POST (member) | Queue report fetch job |
| `bulk_request_report` | POST (collection) | Queue multiple report fetches |
| `approve` | POST (member) | Approve + pipeline assignment |
| `reject` | POST (member) | Reject with reason |
| `recalculate` | POST (member) | Re-run FQS |

### Routes — add after contacts block (~line 195 in `config/routes.rb`):

```ruby
resources :influencer_profiles, only: [:index, :show] do
  collection do
    post :search
    post :import
    post :bulk_import
    post :bulk_request_report
  end
  member do
    post :request_report
    post :approve
    post :reject
    post :recalculate
  end
end
```

### Background Jobs — `app/jobs/influencers/`

| Job | Purpose |
|-----|---------|
| `fetch_report_job.rb` | Calls `Iqfluence::ReportService`, updates profile, sets status=report_fetched, enqueues `score_profile_job` |
| `score_profile_job.rb` | Runs `FqsCalculator` with full data, auto-approve/reject if thresholds met |
| `bulk_fetch_reports_job.rb` | Enqueues individual `FetchReportJob` for each ID (with rate-limit spacing) |

---

## 4. Frontend Architecture

### Routes — `app/javascript/dashboard/routes/dashboard/influencers/`

```
/influencers              → InfluencersIndex (default: search tab)
/influencers/review       → InfluencersIndex (review tab)
/influencers/pipeline     → InfluencersIndex (pipeline/kanban tab)
/influencers/rejected     → InfluencersIndex (rejected tab)
```

Register in main dashboard routes alongside contacts.

### Sidebar — Add to `Sidebar.vue` (after Contacts block, ~line 451):

```javascript
{
  name: 'Influencers',
  label: t('SIDEBAR.INFLUENCERS'),
  icon: 'i-lucide-sparkles',
  children: [
    { name: 'Search', label: t('SIDEBAR.INFLUENCER_SEARCH'), to: 'influencers_search' },
    { name: 'Review', label: t('SIDEBAR.INFLUENCER_REVIEW'), to: 'influencers_review' },
    { name: 'Pipeline', label: t('SIDEBAR.INFLUENCER_PIPELINE'), to: 'influencers_pipeline' },
    { name: 'Rejected', label: t('SIDEBAR.INFLUENCER_REJECTED'), to: 'influencers_rejected' },
  ],
}
```

### API — `app/javascript/dashboard/api/influencerProfiles.js`

Extends `ApiClient` with: `search()`, `import()`, `bulkImport()`, `requestReport()`, `bulkRequestReport()`, `approve()`, `reject()`, `recalculate()`

### Store — `app/javascript/dashboard/store/modules/influencerProfiles.js`

State: `records`, `searchResults`, `uiFlags`, `meta`, pagination. Standard CRUD actions + search/import/approve/reject.

### Components — `app/javascript/dashboard/components-next/Influencers/`

| Component | Purpose |
|-----------|---------|
| `InfluencerSearchPanel.vue` | Filter form: follower range, ER range, country multi-select (EU markets), keywords, hashtags. Predefined segment presets (dropdown). |
| `InfluencerSearchResults.vue` | Grid of result cards with checkboxes, bulk import bar, "already imported" indicators |
| `InfluencerSearchResultCard.vue` | Avatar, username, followers, ER, avg views, location, niche tags |
| `InfluencerReviewList.vue` | Table of profiles with FQS, status, key metrics, approve/reject actions |
| `InfluencerProfileCard.vue` | Row: avatar, username, followers, ER, FQS badge, audience credibility, recent reels thumbnails |
| `InfluencerProfileDetail.vue` | Slide-over panel: full metrics, FQS breakdown, audience charts, reels list, approve/reject |
| `InfluencerReelPreview.vue` | Reel thumbnail + play link (opens Instagram), views/likes overlay |
| `FqsScoreBadge.vue` | Color-coded badge: green ≥70, yellow 50–69, red <50. Hover shows breakdown tooltip. |
| `InfluencerBulkActions.vue` | Floating bar: "N selected" + Import / Fetch Reports / Approve / Reject buttons |
| `InfluencerPipelineView.vue` | Reuses existing `PipelineKanbanBoard.vue` filtered to "influencer" label |

---

## 5. Screens

### Screen 1: Search (`/influencers`)
- **Top**: Tab bar (Search | Review | Pipeline | Rejected)
- **Left panel**: Search filters (collapsible) — segment presets dropdown, follower range, ER range, country, keywords, hashtags. "Search IQFluence" button.
- **Main area**: Grid of `InfluencerSearchResultCard`. Already-imported profiles greyed out with "Imported" badge. Checkboxes for selection.
- **Bottom bar**: "Import Selected (N)" and "Import & Fetch Reports" buttons.

### Screen 2: Review (`/influencers/review`)
- **Top**: Same tab bar. Sub-filters: status (Pending Report / Awaiting Review / All), FQS range slider, sort dropdown (FQS desc, date, followers).
- **Main area**: `InfluencerReviewList` table with columns: Profile (avatar+name+username), Followers, ER, FQS (badge), Audience Credibility, Avg Reel Views, Status chip. Each row expandable or click → `InfluencerProfileDetail` slide-over.
- **Detail slide-over**: Full metrics, FQS breakdown chart, 3 recent reels with thumbnails/links, audience geo pie chart, approve/reject buttons.
- **Bulk actions**: Select all + bulk approve/reject/fetch report.

### Screen 3: Pipeline (`/influencers/pipeline`)
- Kanban board (reusing `PipelineKanbanBoard.vue`) for "influencer" label.
- Stages: Qualified → Outreach → Negotiation → Contracted → Active → Completed.
- Cards show: avatar, name, followers, ER, FQS badge (via existing `PipelineContactCard.vue` custom_attributes display).
- Drag-and-drop between stages.

### Screen 4: Rejected (`/influencers/rejected`)
- Simple table of rejected profiles with rejection reason.
- "Re-evaluate" action (re-runs FQS, moves back to Review if score changed).

---

## 6. Integration with Existing Chatwoot Systems

| System | Integration Point |
|--------|------------------|
| **Contact** | `has_one :influencer_profile`. Imported influencers are contacts with `contact_type: :lead` and `identifier: "ig:<username>"` |
| **custom_attributes** | `ImportService` and `ApproveService` sync followers, engagement_rate, avg_views to `contact.custom_attributes` so existing `PipelineContactCard` displays them |
| **Labels** | `ApproveService` adds "influencer" label via `contact.update_labels` |
| **Pipeline/Kanban** | "influencer" label gets seeded pipeline stages. `ApproveService` creates `ContactPipelineStage` for first stage. Existing kanban in `/contacts/labels/influencer` works + new `/influencers/pipeline` wraps same component |
| **Custom Attribute Definitions** | Existing `influencer_attributes.rake` already seeds display definitions for pipeline cards |
| **Sidebar** | New "Influencers" section added to `Sidebar.vue` menuItems |
| **Conversations** | When influencer is contacted (status=contacted), conversations link through existing contact association |

---

## 7. Implementation Sequence

### Phase 1: Backend Foundation
1. Migration: create `influencer_profiles` table
2. Model: `InfluencerProfile` + add `has_one` to Contact
3. `Iqfluence::Client` — HTTP wrapper with auth
4. `Iqfluence::SearchService` — search endpoint integration
5. `Iqfluence::ResponseParser` — map API responses to model attributes
6. `Influencers::ImportService` — create Contact + InfluencerProfile from search result
7. Controller with `index`, `show`, `search`, `import`, `bulk_import`
8. Routes

### Phase 2: FQS + Reports
9. `Fqs::HardFilter` — elimination checks
10. `Fqs::NicheMatcher` — category matching
11. `Fqs::Stage1Scorer` — 65-point scoring
12. `Iqfluence::ReportService` — report fetching
13. `Fqs::Stage2Scorer` — 35-point scoring
14. `Influencers::FqsCalculator` — orchestrator
15. `Influencers::FetchReportJob` + `ScoreProfileJob` + `BulkFetchReportsJob`
16. Controller actions: `request_report`, `bulk_request_report`, `approve`, `reject`, `recalculate`
17. `Influencers::ApproveService` + `RejectService`

### Phase 3: Frontend
18. API module: `influencerProfiles.js`
19. Store module: `influencerProfiles.js`
20. Routes + register in dashboard router
21. Sidebar entry in `Sidebar.vue`
22. Search screen: `InfluencerSearchPanel` + `InfluencerSearchResults` + `InfluencerSearchResultCard`
23. Review screen: `InfluencerReviewList` + `InfluencerProfileCard` + `InfluencerProfileDetail`
24. `FqsScoreBadge` + `InfluencerReelPreview`
25. Bulk actions bar
26. i18n keys in `en.json`

### Phase 4: Pipeline Integration
27. Seed task: "influencer" label + pipeline stages (Qualified, Outreach, Negotiation, Contracted, Active, Completed)
28. Pipeline kanban view in Influencers tab (wrapping existing `PipelineKanbanBoard`)
29. Rejected list view

---

## 8. Key Files to Modify

- `app/models/contact.rb` — add `has_one :influencer_profile`
- `config/routes.rb` — add influencer_profiles routes (~line 195)
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` — add Influencers menu (~line 451)
- `app/javascript/dashboard/routes/index.js` — register influencer routes

## 9. Key Files to Create

- `db/migrate/*_create_influencer_profiles.rb`
- `app/models/influencer_profile.rb`
- `app/controllers/api/v1/accounts/influencer_profiles_controller.rb`
- `app/services/iqfluence/client.rb`, `search_service.rb`, `report_service.rb`, `response_parser.rb`
- `app/services/influencers/import_service.rb`, `fqs_calculator.rb`, `approve_service.rb`, `reject_service.rb`
- `app/services/influencers/fqs/hard_filter.rb`, `stage1_scorer.rb`, `stage2_scorer.rb`, `niche_matcher.rb`
- `app/jobs/influencers/fetch_report_job.rb`, `score_profile_job.rb`, `bulk_fetch_reports_job.rb`
- `app/javascript/dashboard/routes/dashboard/influencers/routes.js`
- `app/javascript/dashboard/api/influencerProfiles.js`
- `app/javascript/dashboard/store/modules/influencerProfiles.js`
- `app/javascript/dashboard/components-next/Influencers/*.vue` (10+ components)

## 10. Verification

1. **Backend**: `bundle exec rspec spec/models/influencer_profile_spec.rb` + controller specs
2. **FQS**: Unit tests for each scorer with known inputs → expected scores
3. **API integration**: Test with real IQFluence API key against sandbox/test profiles
4. **Frontend**: `pnpm test` for component specs
5. **E2E**: Manual flow — Search → Import → Fetch Report → See FQS → Approve → See in Kanban
6. **Lint**: `bundle exec rubocop -a` + `pnpm eslint`
