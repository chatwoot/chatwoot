---
title: "Migrate IQFluence API to influencers.club API"
type: refactor
status: active
date: 2026-02-26
origin: docs/plans/2026-02-26-feat-fqs-without-iqfluence-data-strategy-plan.md
---

# Migrate IQFluence API to influencers.club API

## Overview

Replace all IQFluence API integration with influencers.club API. The audience data structure is **identical** between both providers (confirmed via real API testing), making this a clean swap of the HTTP/service layer while keeping the model, FQS scoring, and frontend display components unchanged.

## Problem Statement / Motivation

IQFluence minimum credit package costs $2,660 upfront (5,000 credits). influencers.club Pro plan costs $208/month with 500 credits included — identical audience data, automated discovery with `ai_search`, and fits the pilot budget ($200/month).

## Proposed Solution

1. Create `app/services/influencers_club/` with 4 service files replacing 7 IQFluence services
2. Update controller, import service, and fetch report job to use new services
3. Rewrite frontend search panel filters (IQFluence GEO_IDs → location strings, keywords → ai_search)
4. Add DB migration for column renames
5. Delete `app/services/iqfluence/` directory

## Technical Approach

### Architecture: What Changes vs What Stays

```
CHANGES (service layer swap)                    STAYS (identical)
─────────────────────────────                   ─────────────────
app/services/iqfluence/ (DELETE 7 files)        InfluencerProfile model
app/services/influencers_club/ (CREATE 4 files) Fqs::HardFilter
controller#search action                        Fqs::Stage1Scorer
controller#search_params                        Fqs::Stage2Scorer
Influencers::ImportService line 9               Fqs::NicheMatcher
Influencers::FetchReportJob lines 3,11,14       Influencers::FqsCalculator
InfluencerSearchPanel.vue (filters rewrite)     Influencers::ApproveService
influencer.json i18n                            Influencers::RejectService
                                                Influencers::ScoreProfileJob
                                                All frontend display components
                                                Pipeline/Labels/Contacts
```

### Field Mapping: influencers.club → InfluencerProfile

Based on real API response (`docs/plans/influencer-discovery/influencers-club-report-domprzyrybakowce.json`):

#### Profile fields (from enrich `result.instagram.*`)

| InfluencerProfile column | IQFluence field | influencers.club field | Notes |
|---|---|---|---|
| username | `user_profile.username` | `username` | Same |
| fullname | `user_profile.fullname` | `full_name` | Different key |
| bio | `user_profile.description` | `biography` | Different key |
| profile_url | `user_profile.url` | Build from username | Not returned |
| profile_picture_url | `user_profile.picture` | `profile_picture` | Different key |
| is_verified | `user_profile.is_verified` | `is_verified` | Same |
| followers_count | `user_profile.followers` | `follower_count` | Different key |
| following_count | `user_profile.following` | `following_count` | Same |
| posts_count | `user_profile.posts_count` | `media_count` | Different key |
| engagement_rate | `user_profile.engagement_rate` | `engagement_percent` | Different key + format |
| avg_likes | `user_profile.avg_likes` | `avg_likes` | Same |
| avg_comments | `user_profile.avg_comments` | `avg_comments` | Same |
| avg_reel_views | `user_profile.avg_reels_plays` | `reels.avg_view_count` | Nested differently |
| hidden_like_posts_rate | `user_profile.hidden_like_posts_rate` | **N/A** | Not available — see mitigation |
| paid_post_performance | `user_profile.paid_post_perfomance` | `has_paid_partnership` (bool) | Different type |
| top_hashtags | `user_profile.top_hashtags` `[{tag,weight}]` | `hashtags_count` `[{name,count}]` | Different shape |
| interests | `user_profile.interests` (category objects) | `niche_class` `["Lifestyle"]` | Different shape |
| follower_growth_rate | Computed from `stat_history` | `creator_follower_growth.3_months_ago` | Pre-computed % |
| last_post_at | `recent_posts[0].created` (timestamp) | `most_recent_post_date` `"2025-05-25"` | String date |
| recent_reels | `top_reels` `[{link,stat,thumbnail}]` | `post_data` (filtered by type) | Different shape |
| target_market | `geo.country` | `country` | String "Poland" |
| stat_history | `user_profile.stat_history` | `creator_follower_growth` | Different format |

#### Audience fields (from enrich `result.instagram.audience.audience_followers.data.*`)

| InfluencerProfile column | IQFluence key | influencers.club key | Match? |
|---|---|---|---|
| audience_credibility | `audience_credibility` | `audience_credibility` | **IDENTICAL** |
| audience_credibility_class | `credibility_class` | `credibility_class` | **IDENTICAL** |
| audience_reachability | `audience_reachability` | `audience_reachability` | **IDENTICAL** |
| audience_genders | `audience_genders` | `audience_genders` | **IDENTICAL** |
| audience_ages | `audience_ages` | `audience_ages` | **IDENTICAL** |
| audience_geo | `audience_geo` | `audience_geo` | **IDENTICAL** |
| audience_interests | `audience_interests` | `audience_interests` | **IDENTICAL** |
| audience_brand_affinity | `audience_brand_affinity` | `audience_brand_affinity` | **IDENTICAL** |
| audience_types | `audience_types` | `audience_types` | **IDENTICAL** |

#### Discovery fields (from `POST /public/v1/discovery/` response)

| Field | Available | Notes |
|---|---|---|
| username | YES | `accounts[].profile.username` |
| fullname | YES | `accounts[].profile.full_name` |
| followers_count | YES | `accounts[].profile.followers` |
| engagement_rate | YES | `accounts[].profile.engagement_percent` |
| profile_picture_url | YES | `accounts[].profile.picture` |
| avg_likes | NO | Only in enrich |
| avg_reel_views | NO | Only in enrich |
| bio | NO | Only in enrich |

### Filter Mapping: IQFluence → influencers.club Discovery

| IQFluence filter | influencers.club filter | Format change |
|---|---|---|
| `keywords` | `ai_search` | Semantic search (better) |
| `followers.left_number/right_number` | `number_of_followers.min/max` | Different keys |
| `audience_geo` `[{id:148,weight:0.05}]` | `location` `["Germany"]` | IDs → strings |
| `engagement_rate` `{value:0.015,operator:'gte'}` | `engagement_percent` `{min:1.5}` | Decimal → percentage |
| `audience_gender` `{code:'FEMALE',weight:0.5}` | `gender` `"female"` | Audience → creator filter |
| `audience_lang` `{code:'pl',weight:0.2}` | `profile_language` `["pl"]` | Audience → profile filter |
| `audience_age` `[{code:'25-34',weight:0.25}]` | **N/A** | Not available in discovery |
| `is_verified` (boolean) | **N/A** | Not available in discovery |
| `last_posted` (days) | **N/A** | Not available (use `posting_frequency`) |
| `account_type` `[1,2,3]` | **N/A** | Not available |
| N/A (new) | `hashtags` `["homedecor"]` | New filter |
| N/A (new) | `keywords_in_bio` | New filter |
| N/A (new) | `average_views_for_reels` `{min,max}` | New filter |
| N/A (new) | `follower_growth` `{growth_percentage, time_range_months}` | New filter |
| N/A (new) | `reels_percent` `{min,max}` | New filter |

### Implementation Phases

#### Phase 1: Backend Services (replace IQFluence services)

**1.1 Create `app/services/influencers_club/client.rb`**

```ruby
# app/services/influencers_club/client.rb
class InfluencersClub::Client
  include HTTParty

  BASE_URI = 'https://api-dashboard.influencers.club'.freeze

  class ApiError < StandardError
    attr_reader :code, :response

    def initialize(message = nil, code = nil, response = nil)
      @code = code
      @response = response
      super(message)
    end
  end

  def initialize(jwt_token: ENV.fetch('INFLUENCERS_CLUB_JWT_TOKEN'))
    @jwt_token = jwt_token
  end

  def post(path, body = {})
    url = "#{BASE_URI}#{path}"
    response = self.class.post(url, headers: headers, body: body.to_json)
    handle_response(response)
  end

  private

  def headers
    {
      'Authorization' => "Bearer #{@jwt_token}",
      'Content-Type' => 'application/json'
    }
  end

  def handle_response(response)
    case response.code
    when 200..299
      response.parsed_response
    when 429
      raise ApiError.new('influencers.club rate limit exceeded', response.code, response)
    else
      error_message = "influencers.club API error: #{response.code} - #{response.body}"
      Rails.logger.error error_message
      raise ApiError.new(error_message, response.code, response)
    end
  end
end
```

**1.2 Create `app/services/influencers_club/discovery_service.rb`**

Replaces `Iqfluence::SearchService` (`app/services/iqfluence/search_service.rb`).

```ruby
# app/services/influencers_club/discovery_service.rb
class InfluencersClub::DiscoveryService
  DEFAULT_PAGING = { limit: 50, page: 1 }.freeze

  def initialize(client: InfluencersClub::Client.new, account:)
    @client = client
    @account = account
  end

  def perform(filter_params:, paging: DEFAULT_PAGING)
    filters = build_filters(filter_params)
    @client.post('/public/v1/discovery/', {
      platform: 'instagram',
      paging: paging,
      sort: { sort_by: 'relevancy', sort_order: 'desc' },
      filters: filters
    })
  end

  private

  def build_filters(params)
    filters = {}
    filters[:ai_search] = params[:ai_search] if params[:ai_search].present?
    filters[:number_of_followers] = range_filter(params[:followers]) if params[:followers].present?
    filters[:location] = Array(params[:location]).compact_blank if params[:location].present?
    filters[:engagement_percent] = { min: params[:engagement_percent_min].to_f } if params[:engagement_percent_min].present?
    filters[:profile_language] = Array(params[:profile_language]).compact_blank if params[:profile_language].present?
    filters[:gender] = params[:gender] if params[:gender].present?
    filters[:hashtags] = Array(params[:hashtags]).compact_blank if params[:hashtags].present?
    filters[:keywords_in_bio] = Array(params[:keywords_in_bio]).compact_blank if params[:keywords_in_bio].present?
    filters[:average_views_for_reels] = { min: params[:avg_reels_min].to_f } if params[:avg_reels_min].present?
    filters[:follower_growth] = { growth_percentage: params[:growth_min].to_f, time_range_months: 3 } if params[:growth_min].present?
    filters[:reels_percent] = { min: params[:reels_percent_min].to_f } if params[:reels_percent_min].present?
    filters
  end

  def range_filter(range)
    { min: range[:min].to_i, max: range[:max].to_i }.compact_blank
  end
end
```

**1.3 Create `app/services/influencers_club/enrich_service.rb`**

Replaces `Iqfluence::ReportService` (`app/services/iqfluence/report_service.rb`). Key simplification: **synchronous** — no polling needed.

```ruby
# app/services/influencers_club/enrich_service.rb
class InfluencersClub::EnrichService
  def initialize(client: InfluencersClub::Client.new)
    @client = client
  end

  # Returns full profile + audience data. Costs 1 credit.
  def perform(username:, platform: 'instagram')
    @client.post('/public/v1/creators/enrich/handle/full/', {
      platform: platform,
      handle: username
    })
  end
end
```

**1.4 Create `app/services/influencers_club/response_parser.rb`**

Replaces `Iqfluence::ResponseParser` (`app/services/iqfluence/response_parser.rb`).

```ruby
# app/services/influencers_club/response_parser.rb
class InfluencersClub::ResponseParser
  # Parse discovery results into the same format as search results
  def self.parse_discovery_result(account)
    return if account.blank?

    profile = account['profile'] || {}
    {
      username: profile['username'],
      fullname: profile['full_name'],
      platform: 'instagram',
      profile_picture_url: profile['picture'],
      followers_count: profile['followers'],
      engagement_rate: profile['engagement_percent'],
      user_id: account['user_id']
    }.compact
  end

  # Parse full enrich response into InfluencerProfile attributes
  def self.parse_enrich(data)
    return if data.blank?

    ig = data.dig('result', 'instagram') || {}
    audience_data = ig.dig('audience', 'audience_followers', 'data') || ig.dig('audience', 'audience_likers', 'data') || {}
    reels = ig['reels'] || {}

    profile_attrs = parse_profile_fields(ig, reels)
    audience_attrs = parse_audience_fields(audience_data)
    growth = parse_growth(ig['creator_follower_growth'])

    profile_attrs.merge(audience_attrs).merge(
      follower_growth_rate: growth[:monthly_growth],
      stat_history: ig['creator_follower_growth'] || {},
      recent_reels: extract_reels(ig['post_data']),
      last_post_at: parse_date(ig['most_recent_post_date']),
      target_market: ig['country']&.upcase,
      raw_report_data: data
    ).compact
  end

  def self.parse_profile_fields(ig, reels)
    {
      username: ig['username'],
      fullname: ig['full_name'],
      platform: 'instagram',
      profile_url: "https://www.instagram.com/#{ig['username']}/",
      profile_picture_url: ig['profile_picture'],
      bio: ig['biography'],
      is_verified: ig['is_verified'] || false,
      account_type: ig['account_type'],
      followers_count: ig['follower_count'],
      following_count: ig['following_count'],
      posts_count: ig['media_count'],
      engagement_rate: ig['engagement_percent'],
      avg_likes: ig['avg_likes'],
      avg_comments: ig['avg_comments'],
      avg_reel_views: reels['avg_view_count'],
      avg_saves: nil,
      avg_shares: nil,
      hidden_like_posts_rate: detect_hidden_likes(ig),
      paid_post_performance: ig['has_paid_partnership'] ? 1.0 : 0.0,
      top_hashtags: normalize_hashtags(ig['hashtags_count']),
      interests: normalize_interests(ig['niche_class'])
    }
  end
  private_class_method :parse_profile_fields

  def self.parse_audience_fields(audience_data)
    return {} if audience_data.blank?

    reachability = calculate_reachability(audience_data['audience_reachability'] || [])
    {
      audience_credibility: audience_data['audience_credibility'],
      audience_credibility_class: audience_data['credibility_class'],
      audience_reachability: reachability,
      audience_genders: audience_data['audience_genders'] || {},
      audience_ages: audience_data['audience_ages'] || {},
      audience_geo: audience_data['audience_geo'] || {},
      audience_interests: audience_data['audience_interests'] || {},
      audience_brand_affinity: audience_data['audience_brand_affinity'] || {},
      audience_types: audience_data['audience_types'] || {}
    }
  end
  private_class_method :parse_audience_fields

  def self.parse_growth(growth_data)
    return { monthly_growth: nil } if growth_data.blank?

    # Pre-computed 3-month growth percentage -> monthly rate
    three_month_pct = growth_data['3_months_ago'].to_f
    { monthly_growth: (three_month_pct / 3.0 / 100.0).round(4) }
  end
  private_class_method :parse_growth

  def self.detect_hidden_likes(ig)
    # If avg_likes is suspiciously low relative to followers (< 0.01%), likely hidden
    return 0.0 if ig['follower_count'].to_i.zero?

    ratio = ig['avg_likes'].to_f / ig['follower_count']
    ratio < 0.0001 ? 1.0 : 0.0
  end
  private_class_method :detect_hidden_likes

  def self.normalize_hashtags(hashtags_count)
    return [] if hashtags_count.blank?

    hashtags_count.map { |h| { 'tag' => h['name'], 'weight' => h['count'] } }
  end
  private_class_method :normalize_hashtags

  def self.normalize_interests(niche_class)
    return [] if niche_class.blank?

    # niche_class is ["Lifestyle"] — convert to interests-like structure
    Array(niche_class).map { |name| { 'name' => name } }
  end
  private_class_method :normalize_interests

  def self.calculate_reachability(reachability_data)
    return 0.0 if reachability_data.blank?

    reachable_codes = %w[-500 500-1000]
    reachability_data.select { |r| reachable_codes.include?(r['code'].to_s) }.sum { |r| r['weight'].to_f }
  end
  private_class_method :calculate_reachability

  def self.extract_reels(post_data)
    return [] if post_data.blank?

    post_data.select { |p| p['type']&.include?('Video') || p['type']&.include?('Reel') }.first(5).map do |reel|
      {
        url: reel['link'] || reel['url'],
        thumbnail_url: reel['thumbnail'],
        views: reel['stat']&.dig('plays') || reel['views'],
        likes: reel['stat']&.dig('likes') || reel['likes'],
        comments: reel['stat']&.dig('comments') || reel['comments'],
        timestamp: reel['created'] || reel['taken_at']
      }
    end
  end
  private_class_method :extract_reels

  def self.parse_date(date_string)
    return nil if date_string.blank?

    Date.parse(date_string).to_time
  rescue ArgumentError
    nil
  end
  private_class_method :parse_date
end
```

#### Phase 2: Update Consumers (controller, import service, jobs)

**2.1 Update `app/controllers/api/v1/accounts/influencer_profiles_controller.rb`**

Changes in `search` action (line 27-40) and `search_params` (line 114-123):

```ruby
# controller#search — BEFORE (line 28-30):
service = Iqfluence::SearchService.new(account: Current.account)
response = service.perform(filter_params: search_params)
accounts = response.is_a?(Hash) ? (response['accounts'] || []) : []
# ...
parsed = Iqfluence::ResponseParser.parse_search_result(result)

# controller#search — AFTER:
service = InfluencersClub::DiscoveryService.new(account: Current.account)
response = service.perform(filter_params: search_params)
accounts = response.is_a?(Hash) ? (response['accounts'] || []) : []
# ...
parsed = InfluencersClub::ResponseParser.parse_discovery_result(result)
```

```ruby
# search_params — AFTER:
def search_params
  params.permit(
    :ai_search, :gender, :engagement_percent_min,
    :avg_reels_min, :growth_min, :reels_percent_min,
    followers: %i[min max],
    location: [],
    profile_language: [],
    hashtags: [],
    keywords_in_bio: []
  ).to_h.deep_symbolize_keys
end
```

**2.2 Update `app/services/influencers/import_service.rb`**

Change line 9:

```ruby
# BEFORE:
attrs = Iqfluence::ResponseParser.parse_search_result(@search_result)

# AFTER:
attrs = InfluencersClub::ResponseParser.parse_discovery_result(@search_result)
```

Note: Discovery results have fewer fields than IQFluence search results. Stage 1 scoring will be limited until enrich is run. The `run_stage1_scoring` call (line 47) will produce a partial score — this is acceptable because enrich + full scoring happens next.

**2.3 Update `app/jobs/influencers/fetch_report_job.rb`**

Replace entire file — the enrich is synchronous (no polling):

```ruby
# app/jobs/influencers/fetch_report_job.rb
class Influencers::FetchReportJob < ApplicationJob
  queue_as :medium
  retry_on InfluencersClub::Client::ApiError, wait: :polynomially_longer, attempts: 3

  def perform(profile_id)
    profile = InfluencerProfile.find(profile_id)
    return unless profile.report_pending? || profile.discovered?

    profile.update!(status: :report_pending) if profile.discovered?

    response = InfluencersClub::EnrichService.new.perform(username: profile.username)
    return handle_empty_report(profile) if response.blank?

    attrs = InfluencersClub::ResponseParser.parse_enrich(response)
    profile.update!(
      attrs.merge(
        report_fetched_at: Time.current,
        status: :report_fetched,
        last_synced_at: Time.current
      )
    )

    Influencers::ScoreProfileJob.perform_later(profile.id)
  end

  private

  def handle_empty_report(profile)
    Rails.logger.warn("[Influencers::FetchReportJob] Empty enrich for profile #{profile.id} (#{profile.username})")
  end
end
```

#### Phase 3: Database Migration

```ruby
# db/migrate/YYYYMMDDHHMMSS_rename_iqfluence_columns.rb
class RenameIqfluenceColumns < ActiveRecord::Migration[7.0]
  def change
    rename_column :influencer_profiles, :iqfluence_report_id, :external_report_id
    rename_column :influencer_profiles, :iqfluence_search_result_id, :external_search_id
  end
end
```

#### Phase 4: Frontend Search Panel

Rewrite `app/javascript/dashboard/components-next/Influencers/InfluencerSearchPanel.vue`:

**Key changes:**
- Remove `GEO_IDS` constant — country toggles send name strings directly (`"Germany"`, `"Poland"`)
- Replace `keywords` input with `ai_search` input (semantic search)
- Add `hashtags` input (comma-separated)
- Replace `engagement_rate_min` (decimal 0.015) with `engagement_percent_min` (percentage 1.5 — no division by 100)
- Replace `audience_gender` with `gender` (creator gender)
- Replace `audience_lang` with `profile_language`
- Remove `audience_age`, `is_verified`, `last_posted`, `account_type` filters (not in discovery API)
- Add new filters: `avg_reels_min`, `growth_min`, `reels_percent_min`
- Update presets to use `ai_search` + `location` + `hashtags`

**Updated presets:**

```javascript
const SEARCH_PRESETS = {
  'DE micro home decor': {
    followers: { min: 5000, max: 30000 },
    ai_search: 'home decor interior design wall art',
    location: ['Germany'],
    profile_language: ['de'],
    engagement_percent_min: 1.5,
    hashtags: ['homedecor', 'interior', 'einrichtung'],
  },
  'PL family photographers': {
    followers: { min: 5000, max: 30000 },
    ai_search: 'wnętrza rodzina zdjęcia dom',
    location: ['Poland'],
    profile_language: ['pl'],
    engagement_percent_min: 1.5,
    hashtags: ['wnetrza', 'homedecor'],
  },
  // ... similar for FR, NL, UK
};
```

**Updated filters:**

```javascript
const DEFAULT_FILTERS = {
  ai_search: '',
  followers_min: 5000,
  followers_max: 30000,
  location: [],
  engagement_percent_min: '',
  gender: '',
  profile_language: '',
  hashtags: '',      // comma-separated string, split before sending
  keywords_in_bio: '',
};
```

**Updated handleSearch:**

```javascript
async function handleSearch() {
  const payload = {
    ai_search: filters.ai_search || undefined,
    followers: { min: filters.followers_min, max: filters.followers_max },
    location: filters.location.length
      ? filters.location.map(code => EU_COUNTRIES.find(c => c.code === code)?.name).filter(Boolean)
      : undefined,
  };

  if (filters.engagement_percent_min)
    payload.engagement_percent_min = filters.engagement_percent_min;  // already percentage
  if (filters.gender) payload.gender = filters.gender.toLowerCase();
  if (filters.profile_language) payload.profile_language = [filters.profile_language];
  if (filters.hashtags) payload.hashtags = filters.hashtags.split(',').map(h => h.trim()).filter(Boolean);
  if (filters.keywords_in_bio) payload.keywords_in_bio = filters.keywords_in_bio.split(',').map(k => k.trim()).filter(Boolean);

  await store.dispatch('influencerProfiles/search', payload);
}
```

#### Phase 5: i18n and Cleanup

**5.1 Update `app/javascript/dashboard/i18n/locale/en/influencer.json`:**
- `INFLUENCER.SEARCH.BUTTON`: "Search IQFluence" → "Discover Influencers"
- `INFLUENCER.SEARCH.NO_RESULTS`: Remove IQFluence mention
- `INFLUENCER.SEARCH.KEYWORDS` → `INFLUENCER.SEARCH.AI_SEARCH` with new placeholder
- Add: `INFLUENCER.SEARCH.HASHTAGS`, `INFLUENCER.SEARCH.HASHTAGS_PLACEHOLDER`
- Remove: `INFLUENCER.SEARCH.AUDIENCE_AGE`, `INFLUENCER.SEARCH.ACCOUNT_TYPE*`, `INFLUENCER.SEARCH.VERIFIED_ONLY`

**5.2 Delete `app/services/iqfluence/` directory (7 files):**
- `client.rb`
- `search_service.rb`
- `report_service.rb`
- `response_parser.rb`
- `scraping_service.rb`
- `unhide_service.rb`
- `geos_service.rb`

**5.3 ENV variable:**
- Remove: `IQFLUENCE_API_KEY`
- Add: `INFLUENCERS_CLUB_JWT_TOKEN`

## System-Wide Impact

- **Interaction graph**: Controller → DiscoveryService/EnrichService → Client → influencers.club API. FetchReportJob → EnrichService → ResponseParser → profile.update! → ScoreProfileJob. No change to scoring/approval chain.
- **Error propagation**: `InfluencersClub::Client::ApiError` replaces `Iqfluence::Client::ApiError`. Job retry logic unchanged (3 attempts, polynomial backoff). Controller returns 500 on API errors (existing behavior).
- **State lifecycle risks**: Import creates profile in `discovered` state with fewer fields than before (discovery returns minimal data). Profile must be enriched before meaningful FQS scoring. Partial failure during enrich leaves profile in `report_pending` — job retry handles this.
- **API surface parity**: REST endpoints unchanged. Frontend API client (`influencerProfiles.js`) unchanged. Only the search payload shape changes.

## Decisions & Mitigations

### D1: Discovery returns minimal data → Stage 1 scoring limited at import

**Decision:** Accept partial Stage 1 scoring at import time. Only `engagement_rate` and `followers_count` are available from discovery. Niche fit, reel views, and growth require enrich data.

**Mitigation:** After import, auto-enqueue `FetchReportJob` to get full data. Stage 1 score will be recalculated after enrich completes (before Stage 2 runs). Users see a "pending" state until enrich completes.

### D2: `hidden_like_posts_rate` not available from influencers.club

**Decision:** Compute heuristically from `avg_likes` vs `follower_count`. If `avg_likes / follower_count < 0.01%` → flag as hidden likes. This matches the observation: @domprzyrybakowce has `avg_likes: 3.0` with 115K followers = obvious hidden likes.

### D3: `audience_age` and `is_verified` filters removed from discovery

**Decision:** These were IQFluence-specific. influencers.club discovery doesn't support them. Users can still filter by these after enrichment (in the review list). The `ai_search` and `hashtags` filters more than compensate.

### D4: JWT token is long-lived (tested: exp=2045)

**Decision:** Treat JWT as static API key. No refresh logic needed. Store in `ENV['INFLUENCERS_CLUB_JWT_TOKEN']`.

### D5: `interests` field changes shape

**Decision:** `niche_class` returns `["Lifestyle"]` instead of IQFluence interest objects with IDs. `NicheMatcher` currently checks both interest names and IDs. Update `NicheMatcher` to also match against `niche_class`-style strings. The audience-level `audience_interests` (used in Stage 2) is identical.

## Acceptance Criteria

- [ ] `InfluencersClub::Client` authenticates via Bearer JWT and handles 429/error responses
- [ ] `InfluencersClub::DiscoveryService` sends correct filter payload (tested: 55 results for PL home decor)
- [ ] `InfluencersClub::ResponseParser.parse_discovery_result` maps discovery data correctly
- [ ] `InfluencersClub::ResponseParser.parse_enrich` maps all profile + audience fields correctly
- [ ] `InfluencersClub::EnrichService` returns full audience data (1 credit/profile)
- [ ] Controller `search` action uses new services and returns results to frontend
- [ ] Controller `search_params` permits new filter params (ai_search, location, hashtags, etc.)
- [ ] `ImportService` uses new response parser
- [ ] `FetchReportJob` uses `EnrichService` (no polling) and `parse_enrich`
- [ ] FQS scoring (Stage 1 + Stage 2 + hard filters) produces correct scores from influencers.club data
- [ ] `NicheMatcher` handles `niche_class` string format alongside IQFluence interest objects
- [ ] Search panel sends new filter format (ai_search, location strings, hashtags)
- [ ] Country toggles send location name strings (not GEO_IDs)
- [ ] Presets use ai_search + location + hashtags
- [ ] i18n updated — no "IQFluence" references remain
- [ ] `app/services/iqfluence/` directory deleted
- [ ] DB migration renames iqfluence columns
- [ ] `INFLUENCERS_CLUB_JWT_TOKEN` env var documented

## File Change Summary

| Action | File | Lines changed |
|--------|------|---------------|
| CREATE | `app/services/influencers_club/client.rb` | ~50 |
| CREATE | `app/services/influencers_club/discovery_service.rb` | ~45 |
| CREATE | `app/services/influencers_club/enrich_service.rb` | ~15 |
| CREATE | `app/services/influencers_club/response_parser.rb` | ~130 |
| CREATE | `db/migrate/..._rename_iqfluence_columns.rb` | ~7 |
| MODIFY | `app/controllers/api/v1/accounts/influencer_profiles_controller.rb` | ~15 |
| MODIFY | `app/services/influencers/import_service.rb` | ~2 |
| MODIFY | `app/jobs/influencers/fetch_report_job.rb` | ~15 |
| MODIFY | `app/javascript/dashboard/components-next/Influencers/InfluencerSearchPanel.vue` | ~100 |
| MODIFY | `app/javascript/dashboard/i18n/locale/en/influencer.json` | ~10 |
| DELETE | `app/services/iqfluence/client.rb` | -57 |
| DELETE | `app/services/iqfluence/search_service.rb` | -42 |
| DELETE | `app/services/iqfluence/report_service.rb` | -~50 |
| DELETE | `app/services/iqfluence/response_parser.rb` | -135 |
| DELETE | `app/services/iqfluence/scraping_service.rb` | -~30 |
| DELETE | `app/services/iqfluence/unhide_service.rb` | -~20 |
| DELETE | `app/services/iqfluence/geos_service.rb` | -~20 |

**Net: ~260 lines added, ~355 deleted. Simpler codebase.**

## Sources & References

- **Origin plan:** [docs/plans/2026-02-26-feat-fqs-without-iqfluence-data-strategy-plan.md](docs/plans/2026-02-26-feat-fqs-without-iqfluence-data-strategy-plan.md)
- **influencers.club full report sample:** [docs/plans/influencer-discovery/influencers-club-report-domprzyrybakowce.json](docs/plans/influencer-discovery/influencers-club-report-domprzyrybakowce.json)
- **influencers.club API base:** `https://api-dashboard.influencers.club`
- **influencers.club docs:** `https://docs.influencers.club/`
- **API testing (2026-02-26):** Discovery: 234 results (PL, 5K-30K, ER>2%), 55 results (with ai_search). Enrich: full audience data identical to IQFluence.
- **Pricing:** influencers.club Pro $208/month (500 credits) vs IQFluence $2,660 (5,000 credits minimum)
- **IQFluence API docs:** [docs/plans/influencer-discovery/iqfluence-api.json](docs/plans/influencer-discovery/iqfluence-api.json)
- **FQS scoring plan:** [docs/plans/2026-02-25-feat-fqs-scoring-filter-strategy-voucher-calculator-plan.md](docs/plans/2026-02-25-feat-fqs-scoring-filter-strategy-voucher-calculator-plan.md)
- **Implementation plan:** [docs/plans/2026-02-25-feat-influencer-discovery-final-plan.md](docs/plans/2026-02-25-feat-influencer-discovery-final-plan.md)
