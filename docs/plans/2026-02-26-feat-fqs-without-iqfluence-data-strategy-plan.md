---
title: "FQS bez IQFluence — strategia danych i alternatywne zrodla"
type: feat
status: active
date: 2026-02-26
origin: docs/plans/2026-02-25-feat-fqs-scoring-filter-strategy-voucher-calculator-plan.md
---

# FQS bez IQFluence — strategia danych i alternatywne zrodla

## Problem

IQFluence wymaga minimalnego pakietu subskrypcyjnego, ktory jest za drogi na pilota (>$295/mies. platforma + credits). Budzet na pilota: do $200/mies. Trzeba znalezc alternatywne zrodlo danych dla FQS scoring i influencer discovery.

## Analiza: co z FQS mozna policzyc z Apify Profile Scraper

Apify Profile Scraper (juz uzywany) zwraca bogate dane profilowe i postow. Oto coverage FQS:

### Stage 1 (65 pkt) — coverage z Apify

| Wymiar FQS | Maks pkt | Z Apify? | Zrodlo danych | Jakosc |
|------------|----------|----------|---------------|--------|
| **Niche Fit** | 20 | **TAK** | `latestPosts[].hashtags`, `latestPosts[].mentions`, `biography`, `businessCategoryName` | Bardzo dobra — hashtagi i mentions sa nawet bogatsze niz interests z IQFluence |
| **ER + Quality** | 20 | **TAK** | `latestPosts[].likesCount`, `latestPosts[].commentsCount`, `followersCount` | Dobra — liczymy ER z rzeczywistych postow. Hidden likes: ten sam problem co IQFluence (IG ukrywa = obie usligi nie widza) |
| **Avg Reel Views** | 15 | **TAK** | `latestPosts[].videoViewCount` (type=Video) | Bardzo dobra — mamy views per post |
| **Growth Trend** | 10 | **NIE** | Brak historycznych danych | Brak |

**Stage 1 z Apify: max 55/65 pkt** (brak growth trend)

### Stage 2 (35 pkt) — brak w Apify

| Wymiar FQS | Maks pkt | Z Apify? | Dlaczego nie |
|------------|----------|----------|-------------|
| **Audience Quality** | 20 | **NIE** | Brak audience credibility, reachability, audience types |
| **Audience Fit** | 15 | **NIE** | Brak audience geo, audience brand affinity |

**Stage 2 z Apify: 0/35 pkt**

### Hard Filters — coverage z Apify

| Filter | Z Apify? | Jak? |
|--------|----------|------|
| HF1 ER min | **TAK** | mean(post.likesCount + post.commentsCount) / followersCount |
| HF2 ER > 15% | **TAK** | j.w. |
| HF3 Inactive >60d | **TAK** | `latestPosts[0].timestamp` |
| HF4 Following:Followers >0.8 | **TAK** | `followsCount / followersCount` |
| HF5 Growth spike | **NIE** | Brak historii followerow |
| HF6 Poza EU | **CZESCIOWO** | Heurystyka: jezyk postow, bio keywords, lokalizacja w postach |
| HF7 Likes > 2x views | **TAK** | Z postow: avg(likesCount) vs avg(videoViewCount) |
| HF8 Likes:Comments > 500:1 | **TAK** | Z postow |
| HF9 PPP < 1% | **NIE** | |
| HF10 Mass+suspicious >65% | **NIE** | |
| HF11 Audience credibility | **NIE** | |
| HF12 Growth >50%/3mo | **NIE** | |

**Hard Filters z Apify: 8/12** (brakuje 4 zwiazane z audience i growth)

---

## Odkrycie: Apify datadoping/instagram-profile-analyzer

Istnieje aktor na Apify Store ktory dostarcza **szacunkowe dane audience** na bazie publicznych danych:

**Actor:** `datadoping/instagram-profile-analyzer`

**Dane:**
- Engagement rate (obliczony)
- Follower growth trends (`followersOverTime`)
- Gender split (`genderSplit`) — szacunkowy
- Audience countries (`audienceCountries`) — szacunkowy
- Audience cities (`audienceCities`) — szacunkowy
- Fake followers detection score
- Popular posts analysis

**Koszt:** ~$1.50 / 1000 profili (w Apify credits)
**Apify plan:** $49/mies. = $49 w credits = ~32 000 profili/mies.

**Ograniczenia:**
- Dane demograficzne sa **estymowane/modelowane**, nie z pierwszej reki (jak IQFluence)
- Brak `audience_interests` i `audience_brand_affinity`
- Brak `audience_reachability`
- Brak `audience_types` (mass_followers, suspicious — ale jest fake followers score)
- Jakosc danych nizsza niz IQFluence/HypeAuditor

Dodatkowo: `datadoping/fake-followers-checker` — dedykowany aktor do fake followers.

---

## Alternatywy zbadane

| Usluga | Cena min. | Audience data? | Status |
|--------|-----------|----------------|--------|
| HypeAuditor | $299/mies. + API fees | TAK (pelne) | Odrzucona — ponad budzet |
| Modash | $833/mies. (API) | TAK (pelne) | Odrzucona — 4x ponad budzet |
| Social Blade | $500+/mies. (enterprise) | NIE (tylko growth) | Odrzucona — drogi + brak demographics |
| Phyllo | ~$199/mies. | TAK ale wymaga OAuth per influencer | Odrzucona — wymaga zgody kazdego influencera |
| Instagram Graph API | Free | NIE (bez auth influencera) | Odrzucona — tylko publiczne dane |
| inBeat | N/A | — | Odrzucona — brak API |
| Heepsy | 69 EUR/mies. | NIE (dashboard only) | Odrzucona — brak API |
| Upfluence | ~$2000/mies. | TAK | Odrzucona — 10x ponad budzet |
| **influencers.club** | **$249/mies.** | **TAK (pelne, identyczne z IQFluence)** | **PRZETESTOWANA — rekomendowana** |

---

## influencers.club API — wyniki testow (2026-02-26)

### Discovery endpoint (`POST /public/v1/discovery/`)

Przetestowany z roznymi filtrami:

| Zapytanie | Filtry | Total wynikow | Koszt |
|-----------|--------|---------------|-------|
| Bez filtrow | brak | 93,000,000 | 0.13 cr |
| Bazowe | PL + 5K-30K followers + ER>2% + keywords_in_bio | **234** | 0.05 cr |
| Z AI search | PL + 5K-50K + ER>2% + ai_search + hashtags | **55** | 0.05 cr |

**Przykladowe wyniki (PL home decor, 5K-50K, ER>2%, ai_search + hashtags):**

| Username | Followers | ER% |
|----------|-----------|-----|
| @alicja_domanska | 16,930 | 2.56% |
| @zupillove | 9,914 | 7.75% |
| @naszabudowa_js | 16,556 | 6.67% |
| @anna_milekmandziej | 7,791 | 9.66% |
| @margo.living | 5,539 | 2.10% |

**Dostepne filtry discovery:**
- `number_of_followers` (min/max)
- `engagement_percent` (min/max)
- `average_likes`, `average_comments`, `average_views_for_reels` (min/max)
- `follower_growth` (growth_percentage + time_range_months)
- `location`, `gender`, `profile_language`
- `ai_search` — AI-powered semantic search (np. "home decor interior design")
- `hashtags`, `brands`, `keywords_in_bio`, `keywords_in_captions`
- `has_done_brand_deals`, `reels_percent`, `income`
- Sort: `relevancy` (dziala), `engagement_percent` (nie dziala jako sort)

### Enrich endpoint (`POST /public/v1/creators/enrich/handle/full/`)

Przetestowany na @domprzyrybakowce — pelny raport zapisany w `docs/plans/influencer-discovery/influencers-club-report-domprzyrybakowce.json`.

**Struktura audience data IDENTYCZNA z IQFluence:**

```
audience_followers.data:
├── credibility                    # audience quality score
├── audience_types                 # mass_followers, suspicious, real, influencers
├── genders                        # male/female split
├── genders_per_age                # age × gender matrix
├── geo (countries, cities, states)# audience geography
├── languages                      # audience languages
├── brand_affinity                 # brands audience follows
├── interests                      # audience interests categories
├── reachability                   # audience reachability tiers
├── notable_users                  # notable followers
├── demography                     # age brackets
└── followers_count               # total analyzed
```

**Koszt enrich:** 1 kredyt/profil

### Koszty podsumowanie

| Operacja | Koszt | Przyklad |
|----------|-------|---------|
| Discovery search | 0.05 cr | 20 searches = 1 kredyt |
| Full enrich | 1.0 cr | Pelne audience data per profil |
| Trial | 30 searches + 7 credits | Wystarczajace na walidacje |

### Kluczowe wnioski

1. **influencers.club = IQFluence replacement** — identyczna struktura audience data
2. **Discovery + Enrich w jednym** — nie trzeba Apify do discovery
3. **ai_search** — semantic search pozwala na precyzyjne targetowanie niszy bez manualnego zbierania username'ow
4. **Koszt discovery jest minimalny** — 0.05 cr/search, glowny koszt to enrich (1 cr/profil)

---

## Rekomendowane strategie (zaktualizowane po testach influencers.club)

### ~~Strategia A: "Apify-only" — $49/mies.~~ (zastapiona przez D)

Nieaktualna — influencers.club oferuje discovery z filtrami, wiec manual sourcing username'ow nie jest potrzebny.

### Strategia B: "influencers.club only" — $249/mies. ⭐ REKOMENDOWANA

**Idea:** influencers.club jako jedyne zrodlo — Discovery API do wyszukiwania + Enrich API do pelnych danych audience. Apify niepotrzebne.

**Flow:**
```
influencers.club Discovery (ai_search + filtry)
  → Top kandydaci z listy (profile data + ER)
  → Enrich wybranych (1 cr/profil) → pelne audience data
  → FQS auto (100 pkt — pelna formula)
  → Pipeline
```

**FQS formula (pelna — identyczna z oryginalnym planem IQFluence):**

| Wymiar | Maks pkt | Zrodlo |
|--------|----------|--------|
| **Niche Fit** | 20 | Discovery: ai_search, hashtags, keywords_in_bio + Enrich: audience interests, brand_affinity |
| **ER + Quality** | 20 | Discovery: engagement_percent + Enrich: audience credibility, audience_types |
| **Avg Reel Views** | 15 | Enrich: stat_history (reel views) |
| **Audience Quality** | 20 | Enrich: credibility score, audience_types (mass_followers, suspicious, real) |
| **Audience Fit** | 15 | Enrich: audience_followers.data.geo, demographics, languages |
| **Growth Trend** | 10 | Discovery: follower_growth filter + Enrich: stat_history |
| **Total** | **100** | |

**Koszty szacunkowe (pilota):**

| Operacja | Ilosc/mies. | Koszt cr | $ |
|----------|-------------|----------|---|
| Discovery searches | ~100 (10 rynkow x 10 queries) | 5 cr | — |
| Enrich top kandydatow | ~100 profili (10 rynkow x 10) | 100 cr | — |
| **Lacznie** | | **105 cr/mies.** | **$249/mies. (plan)** |

**Zalety:**
- **Pelny FQS 100 pkt** — audience data identyczna z IQFluence
- **Automated discovery** — ai_search + filtry zamiast manualnego zbierania username'ow
- **Jedno API** — prostsza integracja niz Apify + cos
- **Discovery prawie darmowe** — 0.05 cr/search, mozna iterowac filtry
- **Przetestowane** — API zweryfikowane na real data (@domprzyrybakowce)

**Wady:**
- $249/mies. = $49 ponad budzet ($200)
- Lock-in na jednego providera (ale audience data structure = IQFluence, wiec migracja latwa)
- Discovery zwraca basic data (username, followers, ER) — enrich potrzebny dla pelnych danych

**Mitygacja kosztu:** Negocjowac z influencers.club nizsza cene lub trial period na pilota.

### Strategia C: "Apify + manualna weryfikacja" — $49/mies. (fallback)

**Idea:** Jesli $249/mies. jest nieakceptowalne. Apify Profile Scraper do scrapingu + manualna weryfikacja audience.

**Flow:**
1. Manual sourcing username'ow (hashtagi, competitors' followers)
2. Apify Profile Scraper → FQS Stage 1 (55 pkt, bez audience)
3. Top 30 kandydatow → manualna weryfikacja audience (45 pkt)

**Wady vs Strategia B:**
- Brak automated discovery (manual sourcing)
- Brak audience data (manual scoring — subiektywne)
- Nie skaluje sie ponad 50 profili
- FQS Stage 2 manualny zamiast auto

### Strategia D: "influencers.club Discovery + Apify Enrich" — $49-99/mies. (hybrid)

**Idea:** influencers.club Discovery (0.05 cr/search) do wyszukiwania, Apify Profile Scraper do scrapingu pelnych danych postow. Enrich z influencers.club tylko dla top kandydatow.

**Flow:**
```
influencers.club Discovery (ai_search + filtry) → lista username'ow
  → Apify Profile Scraper (batch scrape — posty, hashtagi, ER)
  → FQS Stage 1 auto (55 pkt)
  → Top ~20 kandydatow → influencers.club Enrich (1 cr/profil)
  → FQS Stage 2 auto (45 pkt)
  → Pipeline
```

**Koszty szacunkowe:**

| Operacja | Ilosc/mies. | Koszt |
|----------|-------------|-------|
| influencers.club Discovery | ~50 searches | 2.5 cr ($0 — trial) |
| Apify Profile Scraper | ~200 profili | ~$5 w Apify credits |
| influencers.club Enrich | ~20-30 top profili | 20-30 cr |
| **Lacznie** | | **$49 (Apify) + pay-per-credit influencers.club** |

**Zalety:**
- Automated discovery z ai_search
- Pelny FQS 100 pkt dla top kandydatow
- Nizszy koszt niz Strategia B (enrich tylko top 20-30)

**Wady:**
- Dwa rozne API do integracji
- Nie wiadomo czy influencers.club oferuje pay-per-credit bez planu $249

---

## Rekomendacja (zaktualizowana)

### Na pilota: **Strategia B** (influencers.club only) — $249/mies.

**Dlaczego zmiana z C na B:**
1. **Discovery API dziala swietnie** — ai_search + filtry daja precyzyjne wyniki (55 profili zamiast 93M)
2. **Audience data identyczna z IQFluence** — pelny FQS 100 pkt bez kompromisow
3. **Jedno API zamiast trzech** — prostsza implementacja, mniej maintenance
4. **$49 ponad budzet to akceptowalny trade-off** za:
   - Automated discovery (vs manual sourcing username'ow)
   - Auto audience scoring (vs manualna weryfikacja 50 profili)
   - Skalowanie (200+ profili/mies. vs max 50 manualnie)
5. **Mozna negocjowac** trial/discount z influencers.club (mamy juz trial z 7 credits)

### Fallback jesli $249 nieakceptowalne: **Strategia D** (hybrid)

Uzyc influencers.club Discovery (tanie) + Apify scraping + influencers.club Enrich tylko dla top ~20 profili.

### Na Faze 2 (skalowanie): pozostac na influencers.club lub migracja na IQFluence

Audience data structure jest identyczna — migracja to tylko zmiana HTTP client, nie modelu danych.

---

## Zmiany w implementacji vs istniejacy plan (zaktualizowane)

### Co sie zmienia w backend (Strategia B — influencers.club)

| Komponent | Byl (IQFluence) | Jest (influencers.club) |
|-----------|-----------------|------------------------|
| `app/services/iqfluence/` | IQFluence HTTP client | **`app/services/influencers_club/`** — influencers.club HTTP client |
| `Iqfluence::SearchService` | `/api/search/newv1/` | **`InfluencersClub::DiscoveryService`** — `POST /public/v1/discovery/` |
| `Iqfluence::ReportService` | `/api/reports/new/` | **`InfluencersClub::EnrichService`** — `POST /public/v1/creators/enrich/handle/full/` |
| `Iqfluence::ResponseParser` | Parser IQFluence JSON | **`InfluencersClub::ResponseParser`** — parser (audience data structure identyczna!) |

### Co sie NIE zmienia

| Komponent | Dlaczego bez zmian |
|-----------|-------------------|
| `InfluencerProfile` model | Audience data structure identyczna z IQFluence → ten sam schemat |
| `Fqs::Stage1Scorer` | Niche Fit, ER, Reel Views — dostepne z enrich |
| `Fqs::Stage2Scorer` | audience_followers.data ma te same klucze co IQFluence |
| `Fqs::HardFilter` | Wszystkie 12 filtrow dzialaja (audience data pelne) |
| `Fqs::NicheMatcher` | audience interests + brand_affinity dostepne |
| Frontend: SearchPanel, ReviewList, ProfileDetail | Wyswietlaja te same dane |
| Pipeline, Labels, Contacts | Niezalezne od zrodla danych |

**BRAK Manual Audience Scoring UI** — niepotrzebny, bo influencers.club zwraca pelne audience data automatycznie.

### FQS formula (pelna — bez zmian vs oryginalny plan)

| Wymiar | Maks pkt | Auto | Zrodlo influencers.club |
|--------|----------|------|------------------------|
| **Niche Fit** | 20 | TAK | Enrich: audience interests, brand_affinity + Discovery: hashtags |
| **ER + Quality** | 20 | TAK | Discovery: engagement_percent + Enrich: audience credibility |
| **Avg Reel Views** | 15 | TAK | Enrich: stat_history |
| **Audience Quality** | 20 | TAK | Enrich: credibility, audience_types (mass_followers, suspicious, real) |
| **Audience Fit** | 15 | TAK | Enrich: audience_followers.data.geo, demographics, languages |
| **Growth Trend** | 10 | TAK | Discovery: follower_growth filter + Enrich: stat_history |
| **Total** | **100** | | |

### Discovery flow (zaktualizowany)

**Bylo (IQFluence):**
```
IQFluence Search → Unhide → Import → FQS auto → Report → FQS Stage 2 auto
```

**Jest (influencers.club):**
```
influencers.club Discovery (ai_search + filtry po rynku)
  → Przeglad wynikow (username, followers, ER)
  → Wybor kandydatow do enrichment
  → influencers.club Enrich (pelne audience data)
  → Import do Chatwoot
  → FQS auto (100 pkt — pelna formula)
  → Pipeline
```

**Kluczowa przewaga nad IQFluence:** `ai_search` pozwala na semantic search ("home decor wall art photography") zamiast polegania tylko na category filters.

---

## Implementacja influencers.club Client

### `app/services/influencers_club/client.rb`

```ruby
class InfluencersClub::Client
  include HTTParty

  BASE_URI = 'https://api-dashboard.influencers.club'.freeze

  class ApiError < StandardError
    attr_reader :code, :response

    def initialize(message = nil, code: nil, response: nil)
      @code = code
      @response = response
      super(message)
    end
  end

  def initialize
    @jwt_token = ENV.fetch('INFLUENCERS_CLUB_JWT_TOKEN')
  end

  # Discovery — 0.05 cr/search
  def discover(filters:, platform: 'instagram', page: 1, limit: 20)
    post('/public/v1/discovery/', {
      platform: platform,
      paging: { limit: limit, page: page },
      sort: { sort_by: 'relevancy', sort_order: 'desc' },
      filters: filters
    })
  end

  # Full enrich — 1 cr/profile
  def enrich_by_handle(username, platform: 'instagram')
    post("/public/v1/creators/enrich/handle/full/", {
      platform: platform,
      handle: username
    })
  end

  private

  def post(path, body)
    response = self.class.post(
      "#{BASE_URI}#{path}",
      body: body.to_json,
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{@jwt_token}"
      }
    )
    handle_response(response)
  end

  def handle_response(response)
    case response.code
    when 200..299 then response.parsed_response
    when 429 then raise ApiError.new('Rate limited', code: 429, response: response)
    else raise ApiError.new("influencers.club API error: #{response.code}", code: response.code, response: response)
    end
  end
end
```

### `app/services/influencers_club/discovery_service.rb`

```ruby
class InfluencersClub::DiscoveryService
  def initialize(client: InfluencersClub::Client.new)
    @client = client
  end

  # Discover influencers for a market
  # market_config example:
  #   { location: ["Poland"], language: ["pl"], followers_min: 5000, followers_max: 50000,
  #     er_min: 2.0, ai_search: "home decor wall art", hashtags: ["wnetrza", "homedecor"] }
  def search(market_config, page: 1, limit: 20)
    filters = build_filters(market_config)
    @client.discover(filters: filters, page: page, limit: limit)
  end

  private

  def build_filters(config)
    filters = {}
    filters[:number_of_followers] = { min: config[:followers_min], max: config[:followers_max] } if config[:followers_min]
    filters[:engagement_percent] = { min: config[:er_min] } if config[:er_min]
    filters[:location] = config[:location] if config[:location]
    filters[:profile_language] = config[:language] if config[:language]
    filters[:ai_search] = config[:ai_search] if config[:ai_search]
    filters[:hashtags] = config[:hashtags] if config[:hashtags]
    filters[:keywords_in_bio] = config[:keywords_in_bio] if config[:keywords_in_bio]
    filters[:gender] = config[:gender] if config[:gender]
    filters[:reels_percent] = { min: config[:reels_percent_min] } if config[:reels_percent_min]
    filters
  end
end
```

### `app/services/influencers_club/response_parser.rb`

```ruby
class InfluencersClub::ResponseParser
  # Parse enrich response into InfluencerProfile attributes
  # Audience data structure is IDENTICAL to IQFluence
  def parse_enrich(data)
    profile = data['profile'] || {}
    audience = data.dig('audience_followers', 'data') || {}
    stat_history = data['stat_history'] || []

    {
      username: profile['username'],
      fullname: profile['fullname'],
      bio: profile['description'],
      profile_url: profile['url'],
      profile_picture_url: profile['picture'],
      is_verified: profile['is_verified'] || false,
      followers_count: profile.dig('followers'),
      following_count: profile.dig('following'),
      posts_count: profile.dig('media_count'),
      engagement_rate: profile['engagement_rate'],
      avg_reel_views: profile.dig('avg_reels_plays'),
      avg_likes: profile['avg_likes'],
      avg_comments: profile['avg_comments'],
      last_post_at: nil, # from stat_history or recent_posts
      platform: 'instagram',

      # Audience data (Stage 2 FQS) — same structure as IQFluence
      audience_credibility: audience['credibility'],
      audience_types: audience['audience_types'],
      audience_genders: audience['genders'],
      audience_ages: audience['demography'],
      audience_geo_countries: audience.dig('geo', 0, 'countries'),
      audience_geo_cities: audience.dig('geo', 0, 'cities'),
      audience_languages: audience['languages'],
      audience_interests: audience['interests'],
      audience_brand_affinity: audience['brand_affinity'],
      audience_reachability: audience['reachability'],

      # Raw data for future use
      raw_audience_data: data['audience_followers'],
      raw_stat_history: stat_history
    }
  end

  # Parse discovery results (basic profile data only)
  def parse_discovery_results(data)
    (data['accounts'] || []).map do |account|
      profile = account['profile'] || {}
      {
        user_id: account['user_id'],
        username: profile['username'],
        fullname: profile['full_name'],
        followers_count: profile['followers'],
        engagement_rate: profile['engagement_percent'],
        profile_picture_url: profile['picture']
      }
    end
  end
end
```

---

## Migration path: influencers.club → IQFluence (opcjonalna)

Audience data structure jest **identyczna** miedzy influencers.club a IQFluence. Migracja wymagalaby jedynie:

1. **Zamien `InfluencersClub::Client`** na `Iqfluence::Client` — inny base URL i auth
2. **Zamien `InfluencersClub::DiscoveryService`** na `Iqfluence::SearchService` — inne nazwy parametrow filtrów
3. **`InfluencersClub::ResponseParser`** → `Iqfluence::ResponseParser` — minimalne zmiany (ta sama struktura audience)

**Model `InfluencerProfile`, FQS scorery i frontend NIE zmieniaja sie.**

---

## Otwarte pytania (zaktualizowane)

| # | Pytanie | Wplyw | Status |
|---|---------|-------|--------|
| 1 | ~~Czy influencers.club ma trial/demo API access?~~ | — | ✅ ROZWIAZANE — ma trial (30 searches + 7 credits) |
| 2 | ~~Czy audience data jest porownywalna z IQFluence?~~ | — | ✅ ROZWIAZANE — identyczna struktura |
| 3 | ~~Czy Discovery API ma filtry?~~ | — | ✅ ROZWIAZANE — pelne filtry + ai_search |
| 4 | Jaki plan influencers.club wystarczy na pilota? | Koszt miesieczy | Zbadac plany cenowe — czy 105 cr/mies. miesci sie w najtanszym planie |
| 5 | Czy mozna negocjowac cene ponizej $249/mies.? | Budzet | Kontakt z sales |
| 6 | Czy influencers.club oferuje pay-per-credit bez planu? | Strategia D | Sprawdzic |
| 7 | Jak dobrze `ai_search` dziala na rynkach DE, AT, CH? | Skalowanie | Test z niemieckimi queries |

---

## Acceptance Criteria (zaktualizowane dla Strategii B)

- [ ] `InfluencersClub::Client` poprawnie autentykuje i wywoluje Discovery + Enrich
- [ ] `InfluencersClub::DiscoveryService` poprawnie buduje filtry per rynek
- [ ] `InfluencersClub::ResponseParser` poprawnie mapuje enrich data na `InfluencerProfile`
- [ ] FQS pelna formula (100 pkt) poprawnie oblicza wszystkie wymiary z danych influencers.club
- [ ] Hard Filters (12/12) dzialaja z pelnych audience data
- [ ] Hidden likes handling (audience_likers: empty_audience → fallback na audience_followers)
- [ ] Discovery flow: search → review → enrich → FQS auto → Pipeline dziala end-to-end
- [ ] Credits tracking — monitorowanie zuzycia creditow w UI

## Sources

- **FQS original plan:** `docs/plans/2026-02-25-feat-fqs-scoring-filter-strategy-voucher-calculator-plan.md`
- **Implementation plan:** `docs/plans/2026-02-25-feat-influencer-discovery-final-plan.md`
- **IQFluence API docs:** `docs/plans/influencer-discovery/iqfluence-api.json`
- **influencers.club pelny raport:** `docs/plans/influencer-discovery/influencers-club-report-domprzyrybakowce.json`
- **influencers.club API base:** `https://api-dashboard.influencers.club`
- **influencers.club docs:** `https://docs.influencers.club/`
- **Testy API (2026-02-26):** Discovery (234/55 wynikow z filtrami), Enrich (pelne audience data identyczne z IQFluence)
- **Porownanie Apify vs IQFluence:** analiza z poprzedniej konwersacji
- **Research alternatyw:** HypeAuditor ($299+), Modash ($833+), Social Blade ($500+), Phyllo (wymaga OAuth), inBeat/Heepsy/Upfluence (brak API lub za drogie)
