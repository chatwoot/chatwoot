---
title: "feat: Influencer search with full filter UI and presets as defaults"
type: feat
status: active
date: 2026-02-26
---

# feat: Influencer search with full filter UI and presets as defaults

## Overview

Refactor the Influencer Search panel so that all IQFluence search filters are exposed as individual UI controls. Presets become shortcuts that pre-fill filter values rather than being the primary search mechanism. This gives operators full control over search parameters while keeping presets as convenient starting points.

## Problem Statement

Currently the search panel has: preset dropdown, keywords, follower min/max, and country toggle buttons. The preset populates these fields, but many IQFluence API filters are not exposed in the UI at all (engagement rate, audience gender, audience age, language, verified status, last posted, reels plays, account type, etc.). Operators cannot fine-tune searches beyond what presets define.

## Proposed Solution

1. **Expand filter controls** — add UI inputs for all useful IQFluence search filters
2. **Presets pre-fill filters** — selecting a preset populates all filter fields; user can then modify any value before searching
3. **Backend maps filter params** — controller builds the IQFluence API filter payload from individual params (including geo ID lookup)

## Files to Modify

| File | Change |
|------|--------|
| `app/javascript/dashboard/components-next/Influencers/InfluencerSearchPanel.vue` | Replace current form with expanded filter UI |
| `app/controllers/api/v1/accounts/influencer_profiles_controller.rb` | Update `search_params` + add filter-to-API mapping |
| `app/services/iqfluence/search_service.rb` | Build proper IQFluence filter payload from structured params |
| `app/javascript/dashboard/i18n/locale/en/influencer.json` | Add i18n keys for new filter labels |

No new files needed. No model/migration changes.

## Filter Controls

Based on IQFluence API (`POST /api/search/newv1/`) filter schema:

### Row 1: Quick Filters (always visible)

| Control | Type | IQFluence param | Default | Notes |
|---------|------|-----------------|---------|-------|
| Preset | `<select>` | — (fills other fields) | empty | On change: fills all filters from preset config |
| Keywords | text input | `filter.keywords` | "" | Free-text search |
| Min followers | number | `filter.followers.left_number` | 5000 | |
| Max followers | number | `filter.followers.right_number` | 30000 | |
| Search button | button | — | — | Dispatches search action |

### Row 2: Country Toggles (always visible)

| Control | Type | IQFluence param | Default | Notes |
|---------|------|-----------------|---------|-------|
| Country buttons | toggle chips | `filter.audience_geo[].id` | [] | DE, PL, FR, NL, GB, IT, ES, AT, BE, DK, SE. Need geo ID mapping (see below). |

### Row 3: Advanced Filters (collapsible, collapsed by default)

| Control | Type | IQFluence param | Default | Notes |
|---------|------|-----------------|---------|-------|
| Min ER | number (step 0.1) | `filter.engagement_rate.value` + `operator: "gte"` | "" (no filter) | Engagement rate % |
| Audience gender | select (Any/Male/Female) | `filter.audience_gender.code` + weight 0.5 | "Any" | |
| Audience age | multi-select chips | `filter.audience_age[].code` + weight 0.25 | [] | Options: 13-17, 18-24, 25-34, 35-44, 45-64, 65+ |
| Language | select | `filter.audience_lang.code` + weight 0.2 | "" | Options: en, de, pl, fr, nl, it, es, da, sv |
| Verified only | checkbox | `filter.is_verified` | false | |
| Last posted (days) | number | `filter.last_posted` | "" | Max days since last post (30, 60, 90) |
| Account type | select | `filter.account_type` | [] | 1=regular, 2=creator, 3=business |

### Geo ID Mapping

IQFluence `audience_geo` requires numeric IDs, not country codes. Two options:

**Option A (recommended for MVP):** Hardcode a lookup table of EU country IDs. Fetch once via `GET /api/geos/?q=Germany&platform=instagram` for each country and store as a constant.

```javascript
// Hardcoded after one-time API lookup
const GEO_IDS = {
  DE: 148,    // Germany
  PL: 616,    // Poland
  FR: 250,    // France
  NL: 528,    // Netherlands
  GB: 826,    // United Kingdom
  IT: 380,    // Italy
  ES: 724,    // Spain
  AT: 40,     // Austria
  BE: 56,     // Belgium
  DK: 208,    // Denmark
  SE: 752,    // Sweden
};
```

**Option B (future):** Dynamic autocomplete that queries `GeosService` on input. Deferred.

For MVP, use hardcoded IDs in `InfluencerSearchPanel.vue`. The backend `SearchService` receives numeric IDs directly.

## Preset Configuration

Presets stay as constants but now define values for ALL filter fields (not just keywords/followers/geo):

```javascript
const SEARCH_PRESETS = {
  'DE micro home decor': {
    audience_geo: ['DE'],
    followers: { min: 5000, max: 30000 },
    keywords: 'interior home decor wohnzimmer',
    engagement_rate_min: 1.5,
    audience_lang: 'de',
    last_posted: 60,
  },
  'PL family photographers': {
    audience_geo: ['PL'],
    followers: { min: 5000, max: 30000 },
    keywords: 'rodzina zdjecia wnetrza',
    engagement_rate_min: 1.5,
    audience_lang: 'pl',
    last_posted: 60,
  },
  // ... etc
};
```

When a preset is selected:
1. All filter fields are updated to preset values
2. Fields not defined in the preset are **reset to defaults** (not left as-is)
3. User can freely modify any field after preset is applied
4. Changing any field does NOT clear the preset selection (it's just a starting point)

## Backend Changes

### Controller `search_params`

```ruby
# app/controllers/api/v1/accounts/influencer_profiles_controller.rb
def search_params
  params.permit(
    :keywords, :sort, :page, :is_verified, :last_posted,
    :engagement_rate_min, :audience_gender, :audience_lang,
    followers: %i[min max],
    audience_geo: [],      # now receives numeric IDs directly
    audience_age: [],      # array of codes like "18-24"
    account_type: []       # array of ints
  ).to_h.deep_symbolize_keys
end
```

### SearchService `build_filter_payload`

The `SearchService` needs a method that translates flat params into the IQFluence nested filter structure:

```ruby
# app/services/iqfluence/search_service.rb
def build_filter_payload(params)
  filter = {}
  filter[:keywords] = params[:keywords] if params[:keywords].present?
  filter[:followers] = { left_number: params.dig(:followers, :min), right_number: params.dig(:followers, :max) } if params[:followers]
  filter[:audience_geo] = params[:audience_geo].map { |id| { id: id.to_i, weight: 0.05 } } if params[:audience_geo]&.any?
  filter[:engagement_rate] = { value: params[:engagement_rate_min].to_f, operator: 'gte' } if params[:engagement_rate_min].present?
  filter[:audience_gender] = { code: params[:audience_gender], weight: 0.5 } if params[:audience_gender].present?
  filter[:audience_lang] = { code: params[:audience_lang], weight: 0.2 } if params[:audience_lang].present?
  filter[:audience_age] = params[:audience_age].map { |code| { code: code, weight: 0.25 } } if params[:audience_age]&.any?
  filter[:is_verified] = params[:is_verified] if params[:is_verified].present?
  filter[:last_posted] = params[:last_posted].to_i if params[:last_posted].present?
  filter[:account_type] = params[:account_type].map(&:to_i) if params[:account_type]&.any?
  filter
end

def perform(filter_params:, sort: DEFAULT_SORT, paging: DEFAULT_PAGING)
  filter = build_filter_payload(filter_params)
  @client.post('/api/search/newv1/', { filter: filter, sort: sort, paging: paging })
end
```

## UI Layout

```
+------------------------------------------------------------------+
| Preset: [DE micro home ▼]  Keywords: [interior home decor    ]   |
| Min: [5000]  Max: [30000]                     [Search IQFluence] |
+------------------------------------------------------------------+
| DE  PL  FR  NL  GB  IT  ES  AT  BE  DK  SE                      |
+------------------------------------------------------------------+
| ▸ Advanced filters                                               |
+------------------------------------------------------------------+
  (when expanded:)
| Min ER: [1.5]  Gender: [Any ▼]  Age: [18-24] [25-34] [35-44]   |
| Language: [de ▼]  Verified: [ ]  Last posted: [60] days         |
| Account type: [Any ▼]                                            |
+------------------------------------------------------------------+
```

## Acceptance Criteria

- [ ] All IQFluence search filters listed above are available as individual UI controls in `InfluencerSearchPanel.vue`
- [ ] Advanced filters section is collapsible (collapsed by default)
- [ ] Selecting a preset fills all filter fields with preset values (and resets fields not in preset to defaults)
- [ ] User can modify any filter after applying a preset
- [ ] Country buttons send numeric geo IDs to the API (via hardcoded `GEO_IDS` mapping)
- [ ] `SearchService.build_filter_payload` correctly maps flat params to IQFluence nested filter structure
- [ ] Controller `search_params` permits all new filter fields
- [ ] i18n keys added for all new filter labels
- [ ] Empty/default filter values are not sent to the API (to avoid unnecessary filtering)

## Implementation Steps

1. **`InfluencerSearchPanel.vue`** — Add advanced filters section with collapsible toggle, add `GEO_IDS` constant, update `applyPreset()` to fill all fields, update `handleSearch()` to send all filters including geo IDs
2. **`search_service.rb`** — Add `build_filter_payload` method that maps flat params to IQFluence filter structure, update `perform` to use it
3. **`influencer_profiles_controller.rb`** — Update `search_params` to permit new fields, pass them through to service
4. **`influencer.json`** — Add i18n keys: `SEARCH.ADVANCED_FILTERS`, `SEARCH.MIN_ER`, `SEARCH.AUDIENCE_GENDER`, `SEARCH.AUDIENCE_AGE`, `SEARCH.LANGUAGE`, `SEARCH.VERIFIED_ONLY`, `SEARCH.LAST_POSTED`, `SEARCH.ACCOUNT_TYPE`

## Sources

- IQFluence Search API spec: `docs/plans/influencer-discovery/discovery-api.md`
- Current search panel: `app/javascript/dashboard/components-next/Influencers/InfluencerSearchPanel.vue`
- Current controller: `app/controllers/api/v1/accounts/influencer_profiles_controller.rb`
- Current search service: `app/services/iqfluence/search_service.rb`
