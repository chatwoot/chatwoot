---
title: "FQS Scoring, Discovery Filters & Voucher Calculator"
type: feat
status: active
date: 2026-02-25
origin: docs/plans/influencer-discovery/ + Influencer Marketing - Raport wdrożeniowy.md
---

# FQS Scoring, Discovery Filters & Voucher Calculator

## Overview

Plan operacyjny dla trzech kluczowych komponentów systemu influencer discovery Framky:

1. **FQS (Framky Quality Score)** — implementacja dwuetapowego scoringu bazując na danych z IQFluence API
2. **Filtry discovery** — optymalna preselekcja minimalizująca odkrywanie niepotrzebnych rekordów
3. **Kalkulator vouchera** — landing page z dynamicznym wyliczaniem kwoty vouchera na żywo

---

## 1. Sposób liczenia FQS — mapowanie na dane z API

### Problem: hidden likes i brakujące dane

Kluczowe ograniczenie widoczne w raporcie `@domprzyrybakowce`: `hidden_like_posts_rate = 1.0` (100% postów z ukrytymi lajkami), `avg_likes = 0`, `engagement_rate = 0`. To oznacza, że **ER nie może być obliczony z danych publicznych** dla wielu profili. FQS musi obsługiwać degraded mode.

### Etap 1 — dane z IQFluence Discovery API (max 65 pkt)

IQFluence Discovery (`/api/search/newv1/`) zwraca w `match.user_profile` i `match.audience_likers.data`:

| Wymiar FQS                  | Waga | Pole API (Discovery response)                                                                 | Formuła                                                                                                                                                | Fallback gdy brak danych                                                                                                                                                            |
| --------------------------- | ---- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Niche fit** (20 pkt)      | 20   | `user_profile.interests[].name`, `user_profile.relevance`, `top_hashtags[].tag` (z raportu)   | Zlicz trafienia w target categories: Home Decor (1560), Family/lifestyle (?), Traveling (?), Photography, DIY, Family. 3+ = 20, 2 = 14, 1 = 8, 0 = 0   | `relevance` score z Discovery jako proxy (>0.7 = 20, >0.5 = 14, >0.3 = 8)                                                                                                           |
| **ER + Quality** (20 pkt)   | 20   | `user_profile.engagement_rate`, `user_profile.avg_likes`, `user_profile.avg_comments`         | ER vs mediana tieru (z `extra.engagement_rate_histogram`). >=2x = 15, >=1.5x = 11, >=1x = 8, >=0.7x = 4, <0.7x = 0. + Content Quality bonus 0-5 manual | **Gdy `hidden_like_posts_rate > 0.9`:** Nie ufaj ER. Użyj `avg_comments / followers * 100` jako comment-ER. Comment-ER > 0.1% = 8 pkt (cap), reszta proporcjonalnie. Max 10/20 pkt. |
| **Avg Reel Views** (15 pkt) | 15   | `user_profile.avg_reels_plays`                                                                | Views/followers ratio. >=3x = 15, >=2x = 12, >=1x = 9, >=0.5x = 5, <0.5x = 0                                                                           | Zawsze dostępne — Reel views nie zależą od hidden likes                                                                                                                             |
| **Growth trend** (10 pkt)   | 10   | `user_profile.followers_growth` (z Discovery filter) + `stat_history[].followers` (z raportu) | Oblicz growth z `stat_history`: `(last.followers - first.followers) / first.followers / months`. 2-5%/mies = 10, 1-2% = 7, 0-1% = 4, <0 = 0            | `followers_growth` z Discovery response                                                                                                                                             |

Może w tym etapie dodamy też audience quality i audience fit na jakichś domyślnych poziomach, które doprecyzujemy po ściągnięciu pełnych raportów?

**Implementacja Niche fit z danych Discovery:**

```python
TARGET_INTERESTS = {1560, 190}  # Home Decor, Toys/Children
TARGET_INTEREST_NAMES = {"home decor", "furniture", "children", "family", "photography", "diy", "interior", "traveling"}

def calc_niche_fit(profile) -> int:
    hits = 0
    # Sposób 1: interests z profilu (najlepszy)
    for interest in profile.get("interests", []):
        if interest["id"] in TARGET_INTERESTS or interest["name"].lower() in TARGET_INTEREST_NAMES:
            hits += 1
    # Sposób 2: top_hashtags (z raportu)
    niche_tags = {"interior", "homedecor", "homedesign", "wnetrza", "einrichtung", "decoration",
                  "gallerywall", "familylife", "familienleben", "rodzina", "photography"}
    for ht in profile.get("top_hashtags", []):
        tag = ht["tag"].lstrip("#").lower()
        if tag in niche_tags:
            hits += 1
    # Sposób 3: relevance score z Discovery
    relevance = profile.get("relevance", 0)
    if relevance > 0.7:
        hits = max(hits, 3)
    elif relevance > 0.5:
        hits = max(hits, 2)

    if hits >= 3: return 20
    if hits >= 2: return 14
    if hits >= 1: return 8
    return 0
```

**Implementacja ER + Quality z obsługą hidden likes:**

```python
def calc_er_quality(profile, tier_median_er: float) -> int:
    hidden_rate = profile.get("hidden_like_posts_rate", 0)
    followers = profile["followers"]

    if hidden_rate > 0.9:
        # Degraded mode: comment-based ER only
        comment_er = profile.get("avg_comments", 0) / followers * 100
        if comment_er > 0.15: return 10  # cap at 10/20
        if comment_er > 0.10: return 8
        if comment_er > 0.05: return 5
        return 2

    er = profile.get("engagement_rate", 0)
    if er == 0 and hidden_rate > 0.7:
        # Partially hidden — cap at 10
        comment_er = profile.get("avg_comments", 0) / followers * 100
        if comment_er > 0.10: return 10
        return 5

    # Normal mode
    ratio = er / tier_median_er if tier_median_er > 0 else 1
    if ratio >= 2.0: return 15
    if ratio >= 1.5: return 11
    if ratio >= 1.0: return 8
    if ratio >= 0.7: return 4
    return 0
    # + manual Content Quality bonus 0-5 (dodawany ręcznie lub z PPP)
```

### Etap 2 — dane z IQFluence Report API (max 35 pkt, tylko dla FQS etap 1 >= 50)

Raport (`/api/reports/new/`) zwraca pełne dane audience w `audience_likers.data` i `audience_followers.data`:

| Wymiar FQS                    | Waga | Pole API (Report)                                                                                  | Formuła                                                                                                                                                                   |
| ----------------------------- | ---- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Audience Quality** (20 pkt) | 20   | `audience_likers.data.audience_credibility` + `credibility_class` + `audience_reachability[]`      | Credibility >=0.9 "excellent" = 12, >=0.8 "good" = 8, <0.8 = HARD REJECT. Reachability: sum weights where code in ["-500", "500-1000"] >= 0.30 = 8, >=0.20 = 5, <0.20 = 2 |
| **Audience Fit** (15 pkt)     | 15   | `audience_likers.data.audience_geo.countries[]` + `audience_likers.data.audience_brand_affinity[]` | Target country weight >=0.60 = 10, >=0.40 = 7, >=0.25 = 4, <0.25 = 0. Brand affinity match (Home Decor 1560 in affinity) = 5, partial = 3, none = 0                       |

**Dlaczego `audience_likers` a nie `audience_followers`:**

Raport IQFluence zwraca trzy sekcje audience: `audience_followers`, `audience_likers`, `audience_commenters`. Dla FQS używamy **`audience_likers`** ponieważ:

- Likers = osoby aktywnie angażujące się z contentem = realni potencjalni klienci
- Followers mogą być nieaktywni, kupieni, lub z follow/unfollow
- Engagement-based audience daje dokładniejszy obraz purchase intent

**Implementacja Audience Quality:**

```python
def calc_audience_quality(report) -> int | None:
    """Returns score or None if hard rejected."""
    likers = report.get("audience_likers", {}).get("data", {})

    credibility = likers.get("audience_credibility", 0)
    cred_class = report.get("audience_likers", {}).get("data", {}).get("credibility_class", "")

    # Hard filter
    if cred_class == "bad" or credibility < 0.75:
        return None  # REJECT

    # Credibility score
    cred_score = 0
    if credibility >= 0.9: cred_score = 12
    elif credibility >= 0.8: cred_score = 8
    else: cred_score = 4  # "low" class (0.75-0.8)

    # Reachability: % following < 500 accounts
    reachability = likers.get("audience_reachability", [])
    reachable_pct = sum(r["weight"] for r in reachability if r["code"] in ["-500", "500-1000"])

    reach_score = 0
    if reachable_pct >= 0.30: reach_score = 8
    elif reachable_pct >= 0.20: reach_score = 5
    else: reach_score = 2

    return cred_score + reach_score
```

**Implementacja Audience Fit:**

```python
def calc_audience_fit(report, target_country_code: str) -> int:
    likers = report.get("audience_likers", {}).get("data", {})

    # Geo fit
    countries = likers.get("audience_geo", {}).get("countries", [])
    target_weight = 0
    for c in countries:
        if c.get("code", "").upper() == target_country_code.upper():
            target_weight = c["weight"]
            break

    geo_score = 0
    if target_weight >= 0.60: geo_score = 10
    elif target_weight >= 0.40: geo_score = 7
    elif target_weight >= 0.25: geo_score = 4

    # Brand affinity match
    brand_affinity = likers.get("audience_brand_affinity", [])
    HOME_DECOR_IDS = {1560}  # Home Decor, Furniture & Garden
    ADJACENT_IDS = {190}  # Toys/Children

    affinity_score = 0
    for brand in brand_affinity:
        for interest in brand.get("interest", []):
            if interest.get("id") in HOME_DECOR_IDS:
                affinity_score = 5
                break
            if interest.get("id") in ADJACENT_IDS:
                affinity_score = max(affinity_score, 3)

    return geo_score + affinity_score
```

### Post-filter: Sanity Checks (po pobraniu danych profilu)

Dane z raportu IQFluence dostarczają wszystko do sanity checks:

| Hard Reject                  | Pole API                                                  | Warunek                                                                     |
| ---------------------------- | --------------------------------------------------------- | --------------------------------------------------------------------------- |
| HR1: ER > 15%                | `engagement_rate`                                         | `> 0.15`                                                                    |
| HR2: Likes > 2x views        | `avg_likes`, `avg_reels_plays`                            | `avg_likes > avg_reels_plays * 2`                                           |
| HR3: Likes:Comments > 500:1  | `avg_likes`, `avg_comments`                               | `avg_likes / max(avg_comments, 1) > 500`                                    |
| HR4: PPP < 1%                | `paid_post_perfomance` (uwaga: typo w API — "perfomance") | `< 0.01`                                                                    |
| HR5: Engagement spike > 10x  | `stats[].stat_history[]`                                  | `latest_avg_likes / median(history_avg_likes) > 10`                         |
| HR6: Mass + suspicious > 65% | `audience_likers.data.audience_types[]`                   | sum of `mass_followers` + `suspicious` weights > 0.65                       |
| HR7: Growth > +50% / 3 mies. | `stat_history[]`                                          | `(latest.followers - 3months_ago.followers) / 3months_ago.followers > 0.50` |

**Uwaga dot. HR5:** `stat_history` w raporcie zawiera `avg_likes` per miesiąc. Dla profili z `hidden_like_posts_rate = 1.0` (jak @domprzyrybakowce), `avg_likes = 0` we wszystkich miesiącach — HR5 nie zadziała. W takim przypadku sprawdzamy spike na `avg_reels_plays` lub `avg_comments` jako fallback.

### Czego nie wiemy o FQS

1. **`audience_data` z Influencers.club** — raport wspomina o schemacie `additionalProperties: true` bez udokumentowanej struktury. Nie wiadomo czy IC zwraca cokolwiek użytecznego w audience. Do zbadania przed decyzją o pominięciu IC w etapie 1.

2. **Mediany ER per tier** — potrzebne do normalizacji ER. IQFluence zwraca `extra.engagement_rate_histogram` w raporcie — czy jest dostępny też w Discovery? Jeśli nie, potrzebujemy statycznych benchmarków (Nano >4%, Micro 2-4%, Mid 1-2%).

3. **`paid_post_perfomance` (typo w API)** — czy to pole jest dostępne w Discovery response czy tylko w raporcie? Jeśli tylko w raporcie, HR4 uruchamia się dopiero w etapie 2.

4. **Korelacja FQS z ROAS** — cała formuła FQS to hipoteza. Wagi wymiarów (20/20/15/10/20/15) oparte na intuicji, nie danych. Po pilocie DE (Faza 2, 5-8 współprac) trzeba skorelować FQS z rzeczywistym ROAS i ewentualnie przesunąć wagi.

---

## 2. Selekcja filtrów Discovery — minimalizacja niepotrzebnych rekordów

### Strategia: IQFluence jako primary discovery (nie IC)

**Kluczowy insight:** IQFluence Discovery API (`/api/search/newv1/`) pozwala filtrować po audience na etapie wyszukiwania — to eliminuje profili z niewłaściwą audience ZANIM wydamy kredyt na raport. IC Discovery jest tańsze (0.01 credit/profil), ale audience data jest estymowana i niesprawdzona.

**Rekomendacja:** Używaj IQFluence jako primary discovery engine. IC Enrich Full (1 credit) tylko jako backup do pobrania verified email, jeśli IQFluence go nie zwróci.

### Filtry w IQFluence Discovery API — optymalna konfiguracja

Filtr dzielimy na **warstwy eliminacyjne** (od najtańszej do najdroższej):

#### Warstwa 1: Filtry profilowe (eliminują ~70% bazy, koszt = 0)

```json
{
  "filter": {
    "followers": { "left_number": 5000, "right_number": 30000 },
    "engagement_rate": { "value": 0.02, "operator": "gte" }, - dodajmy też drugą granicę lte, bo zdarzają się osoby z kupionym engagement i wtedy mają ER na poziomie > 30%
    "reels_plays": { "left_number": 1000, "right_number": 0 },
    "posts_count": { "left_number": 30, "right_number": 0 },
    "last_posted": 90,
    "is_hidden": false,
    "account_type": [2],
    "with_contact": [{ "type": "email", "action": "should" }]
  }
}
```

**Dlaczego `account_type: [2]` (Creator only):**

- Business (3) = sklepy, restauracje, studia — nie będą promować innej marki
- Personal (1) = brak insights, brak Partnership Ads
- Creator (2) = jedyny typ z którego można uruchomić PA



#### Warstwa 2: Filtry audience (eliminują kolejne ~50% pozostałych)

```json
{
  "filter": {
    "audience_geo": [{ "id": 51477, "weight": 0.45 }],
    "audience_lang": { "code": "de", "weight": 0.45 },
    "audience_gender": { "code": "FEMALE", "weight": 0.55 },
    "audience_age": [
      { "code": "25-34", "weight": 0.30 },
      { "code": "35-44", "weight": 0.20 }
    ],
    "audience_credibility": 0.75,
    "audience_credibility_class": ["low", "normal", "good", "excellent"]
  }
}
```

**Klucz: wagi `weight` w filtrach audience.**

IQFluence używa weighted matching — `weight: 0.45` oznacza "min 45% audience z tego kraju". To jest **najsilniejszy lever jakości** bo:

- Influencer z DE z 80% audience z DE = 4x wartościowszy niż ten z 20% z DE
- Audience geo filter na poziomie discovery eliminuje profili z rozproszoną audience ZANIM wydamy raport

**Audience age: dlaczego `25-34` weight 0.30 + `35-44` weight 0.20:**

- Framky buyer persona = kobieta 25-44 z domem i dziećmi
- Łącznie min 50% audience w target age range
- Nie filtrujemy zbyt ciasno (IQFluence nie pozwala na cross-tab w Discovery)

#### Warstwa 3: Filtry niche/relevance (eliminują kolejne ~30%)

```json
{
  "filter": {
    "relevance": {
      "value": "einrichtung wohnzimmer wanddeko gallerywall zuhause familienleben",
      "weight": 0.5,
      "threshold": 0.45
    },
    "text_tags": [
      { "type": "hashtag", "value": "homedecor", "action": "should" },
      { "type": "hashtag", "value": "interior", "action": "should" },
      { "type": "hashtag", "value": "gallerywall", "action": "should" }
    ],
    "audience_brand_category": [
      { "id": 1560, "weight": 0.10 }
    ]
  }
}
```

**Dlaczego `threshold: 0.45` a nie wyżej:**

- Za ciasny threshold (>0.6) odcina lifestyle/family influencerów, którzy nie tagują #interior ale mają idealną audience
- 0.45 = "adjacent niches OK" (family, photography, DIY)
- `audience_brand_category: Home Decor >=10%` uzupełnia — audience interesuje się home decor nawet jeśli influencer nie jest stricte wnętrzarski

#### Warstwa 4: Growth (stabilność)

```json
{
  "filter": {
    "followers_growth": {
      "interval": "i3months",
      "value": -0.05,
      "operator": "gte"
    }
  }
}
```

### Pełny request per rynek — przykład DE

```json
{
  "filter": {
    "followers": { "left_number": 5000, "right_number": 30000 },
    "engagement_rate": { "value": 0.02, "operator": "gte" },
    "reels_plays": { "left_number": 1000, "right_number": 0 },
    "posts_count": { "left_number": 30, "right_number": 0 },
    "last_posted": 90,
    "is_hidden": false,
    "account_type": [2],
    "gender": { "code": "FEMALE" },
    "with_contact": [{ "type": "email", "action": "should" }],
    "audience_geo": [{ "id": 51477, "weight": 0.45 }],
    "audience_lang": { "code": "de", "weight": 0.45 },
    "audience_gender": { "code": "FEMALE", "weight": 0.55 },
    "audience_age": [
      { "code": "25-34", "weight": 0.30 },
      { "code": "35-44", "weight": 0.20 }
    ],
    "audience_credibility": 0.75,
    "audience_credibility_class": ["low", "normal", "good", "excellent"],
    "relevance": {
      "value": "einrichtung wohnzimmer wanddeko gallerywall zuhause familienleben",
      "weight": 0.5,
      "threshold": 0.45
    },
    "text_tags": [
      { "type": "hashtag", "value": "homedecor", "action": "should" },
      { "type": "hashtag", "value": "interior", "action": "should" }
    ],
    "audience_brand_category": [{ "id": 1560, "weight": 0.10 }],
    "followers_growth": {
      "interval": "i3months",
      "value": -0.05,
      "operator": "gte"
    }
  },
  "sort": {
    "field": "engagements",
    "direction": "desc"
  },
  "paging": {
    "limit": 100,
    "skip": 0
  }
}
```

### Oczekiwane wyniki i koszty per rynek

| Etap                         | Rekordów    | Koszt IQFluence                  | Koszt IC   |
| ---------------------------- | ----------- | -------------------------------- | ---------- |
| Discovery (IQFluence search) | ~200-400    | 0 (search is free, unhide costs) | —          |
| Unhide top 100               | 100         | ~100 credits                     | —          |
| Post-filter (sanity checks)  | ~70-80 pass | 0                                | —          |
| FQS etap 1 >= 50 → Report    | ~50         | 50 raportów                      | —          |
| IC Enrich (verified email)   | ~50         | —                                | 50 credits |
| FQS final >= 70 → Pipeline   | ~25-35      | —                                | —          |

**Łącznie per rynek:** ~100 unhides + ~50 raportów IQFluence + ~50 IC credits = dobrze w limitach (350 raportów/mies., 500 IC credits/mies.)

### Adaptacja per rynek (mniejsze rynki)

| Rynek              | `followers` min | `audience_geo` weight | `audience_lang` weight | Uwagi                                       |
| ------------------ | --------------- | --------------------- | ---------------------- | ------------------------------------------- |
| DE, FR, IT, ES, PL | 5000            | 0.45-0.50             | 0.45-0.55              | Duże rynki — ciasne filtry                  |
| NL, UK             | 5000            | 0.40-0.45             | 0.40-0.45              | UK: EN jest globalny, niższy lang threshold |
| AT, BE, DK         | **3000**        | **0.30**              | **0.30-0.45**          | Małe rynki — luzujemy filtry żeby mieć pulę |

---

## 3. Kalkulator vouchera — landing page z dynamicznym wyliczaniem

### Formuła

```
Voucher (EUR) = Base(followers) × FQS_mult × Content_mult × Rights_mult
```

### Architektura landing page

Influencer otrzymuje link do landing page (np. `framky.com/partner/[handle]`) z:

- Informacjami o Framky i zasadach współpracy
- Interaktywnym kalkulatorem vouchera
- Formularzem akceptacji

**Kalkulator działa na froncie (JavaScript) — żadne API call nie jest potrzebne.** Dane influencera (followers, FQS, tier) są pre-loaded w URL params lub w backend context przy generowaniu strony.

### Parametry wejściowe (pre-filled z Chatwoot)

Influencer NIE widzi tych parametrów — są wbudowane w link:

| Parametr    | Źródło               | Przykład |
| ----------- | -------------------- | -------- |
| `followers` | Chatwoot custom attr | 18000    |
| `fqs_score` | Chatwoot custom attr | 78       |
| `market`    | Chatwoot custom attr | DE       |

### Parametry wybierane przez influencera (interaktywne)

| Parametr            | Opcje                                                | Wpływ na voucher          |
| ------------------- | ---------------------------------------------------- | ------------------------- |
| **Content package** | Stories only / Light / Standard / Premium            | 0.5x / 0.7x / 1.0x / 1.5x |
| **Content rights**  | Brak / Limited 60d / Extended bezterminowo           | 1.0x / 1.2x / 1.4x        |
| **Extras**          | Link in Bio 7d (+80 EUR), Reminder Stories (+70 EUR) | Flat add                  |

### Lookup tables (w EUR dla landing page)

**Base value:**

| Followers | Base (EUR) |
| --------- | ---------- |
| 1K-5K     | 100        |
| 5K-15K    | 175        |
| 15K-30K   | 250        |
| 30K-75K   | 375        |

**FQS multiplier:**

| FQS   | Multiplier |
| ----- | ---------- |
| 80+   | 1.3x       |
| 70-79 | 1.1x       |
| 60-69 | 0.9x       |
| 50-59 | 0.7x       |

### Implementacja kalkulatora (frontend)

```javascript
function calculateVoucher(followers, fqsScore, contentPackage, rights, extras) {
  // Base value
  let base;
  if (followers < 5000) base = 100;
  else if (followers < 15000) base = 175;
  else if (followers < 30000) base = 250;
  else base = 375;

  // FQS multiplier
  let fqsMult;
  if (fqsScore >= 80) fqsMult = 1.3;
  else if (fqsScore >= 70) fqsMult = 1.1;
  else if (fqsScore >= 60) fqsMult = 0.9;
  else fqsMult = 0.7;

  // Content package multiplier
  const contentMults = {
    'stories_only': 0.5,
    'light': 0.7,        // 1 Reel + 3 Stories
    'standard': 1.0,     // 1 Reel + 1 Karuzela + 5 Stories
    'premium': 1.5       // 2 Reels + 1 Karuzela + 8 Stories
  };

  // Rights multiplier
  const rightsMults = {
    'none': 1.0,
    'limited_60d': 1.2,
    'extended': 1.4
  };

  let voucher = base * fqsMult * contentMults[contentPackage] * rightsMults[rights];

  // Flat extras
  if (extras.includes('link_in_bio')) voucher += 80;
  if (extras.includes('reminder_stories')) voucher += 70;

  return voucher;
}
```

### UX landing page

1. **Sekcja intro** — co to Framky, jak wygląda produkt, zdjęcia galerii w prawdziwych wnętrzach
2. **Sekcja "Wybierz współpracę"** — checkboxy/radio z pakietami content. Przy każdym pakiecie opis deliverables + etykieta "Najczęściej wybierane" przy Standard
3. **Sekcja "Prawa do contentu"** — radio z wyjaśnieniem co obejmują Limited vs Extended
4. **Sekcja "Extras"** — opcjonalne checkboxy (Link in Bio, Reminder Stories)
5. **Kalkulator na żywo** — pasek boczny (sticky) lub sekcja na dole:
   
   - "Wartość Twojego vouchera: **€XXX**"
   
   - "To odpowiada: **[nazwa produktu Framky]**" (mapowanie na Tier 1/2/3)
   
   - Wizualizacja produktu (zdjęcie odpowiedniego tieru)
6. **CTA "Akceptuję współpracę"** — formularz z potwierdzeniem warunków

### Mapowanie na produkty Framky

| Wyliczona kwota EUR | Produkt                     | Wartość katalogowa |
| ------------------- | --------------------------- | ------------------ |
| do 150 EUR          | Tier 1 — Pojedyncza ramka   | ~100-150 EUR       |
| 150-320 EUR         | Tier 2 — Zestaw multi-frame | ~200-315 EUR       |
| 320+ EUR            | Tier 3 — Pełna galeria      | ~375-480 EUR       |

### Flow danych

```
Chatwoot → generuje link z params (handle, followers, fqs)
  → Influencer otwiera landing page
  → Wybiera pakiet content + rights + extras
  → Kalkulator pokazuje voucher na żywo
  → Influencer akceptuje
  → Webhook do Chatwoot: aktualizacja custom attributes
    (content_package, rights, voucher_value, voucher_product)
  → Pipeline stage: Outreach → Negocjacja (auto)
```

### Kwestie do rozwiązania

1. **Czy influencer widzi kwotę numeryczną czy tylko "Galeria XL"?**
   
   - Opcja A: Pokazujemy kwotę EUR + mapowanie na produkt → transparentność
   
   - Opcja B: Pokazujemy tylko produkt ("Otrzymasz Galerię Framky XL, wartość ~€380") → prostsze UX
   
   - **Rekomendacja:** Opcja B — influencer wybiera content, widzi jaki produkt dostanie. Kwota EUR widoczna, ale secondary.

2. **Czy FQS jest widoczny dla influencera?**
   
   - NIE. FQS jest wewnętrznym scoringiem Framky. Influencer widzi tylko efekt (większy/mniejszy voucher).

3. **Czy base value oparta na followers jest "fair"?**
   
   - Influencer z 10K followers dostaje €175 base, influencer z 25K dostaje €250. Różnica jest widoczna jeśli porównają. Ale link jest unikalny per influencer, więc porównywanie jest mało prawdopodobne.

---

## 4. Czego jeszcze nie wiemy?

### Krytyczne (blokujące start pilotu)

| #   | Pytanie                                                        | Dlaczego ważne                                                                                                                                                  | Jak zwalidować                                                          |
| --- | -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| 1   | **Jak wygląda `audience_data` z IC API?**                      | Raport mówi `additionalProperties: true` — brak schematu. Jeśli IC zwraca coś użytecznego, etap 1 FQS może być tańszy (0.01 credit zamiast IQFluence unhide).   | Wykonać 1 IC Enrich Full call i sprawdzić response                      |
| 2   | **Czy IQFluence Discovery jest darmowy czy kosztuje credits?** | Search (`/search/newv1/`) zwraca `hidden_result: true` dla nie-odblokowanych profili. Unhide kosztuje credits. Ile? Dokumentacja nie precyzuje cost per unhide. | Sprawdzić pricing IQFluence lub wykonać test call                       |
| 3   | **Jak działa `audience_relevance` w Discovery?**               | Filtr `audience_relevance: { "value": "string" }` — co oznacza value? Topic? Keywords? Brak dokumentacji.                                                       | Test call z różnymi values                                              |
| 4   | **Brakujące geo IDs**                                          | PL, NL, UK, AT, DK — potrzebne do filtrów audience_geo.                                                                                                         | `GET /api/geos/?q=Poland` etc.                                          |
| 5   | **Jak wygenerować unikalny link do landing page?**             | Czy z Chatwoot (custom automation/webhook), czy osobny mikroserwis?                                                                                             | Zależy od stack — prawdopodobnie Cloudflare Worker lub Next.js endpoint |

### Ważne (potrzebne przed Fazą 2)

| #   | Pytanie                                                                         | Dlaczego ważne                                                                                           |
| --- | ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| 6   | **Rzeczywisty Action rate z Reela dla premium product (AOV >200 EUR)**          | Cały model ROAS opiera się na Action rate 0.8% — niesprawdzone. Przy 0.4% ROAS spada poniżej break-even. |
| 7   | **Czy vanity URL framky.com/[handle] jest technicznie implementowalny?**        | Zależy od platformy e-commerce. WooCommerce redirect plugin? Cloudflare Page Rule? Oba mają limity.      |
| 8   | **Jak integrować webhook e-commerce → Chatwoot przy użyciu kodu rabatowego?**   | Chatwoot nie ma natywnego lookup "znajdź kontakt po custom attribute". Potrzebny middleware.             |
| 9   | **Czy IQFluence `audience_brand_category` ID 1560 (Home Decor) jest stabilny?** | Jeśli IDs się zmieniają, filter przestaje działać.                                                       |
| 10  | **Ile profili jest w IQFluence dla DE micro + home decor?**                     | Jeśli <100, filtry są za ciasne i trzeba luzować. Jeśli >1000, filtry działają.                          |

### Nice-to-know (po pilocie)

| #   | Pytanie                                                                                                               |
| --- | --------------------------------------------------------------------------------------------------------------------- |
| 11  | Czy `saves` i `shares` z IQFluence Discovery faktycznie predykują ROAS lepiej niż ER?                                 |
| 12  | Czy `audience_likers` daje lepsze wyniki niż `audience_followers` do scoringu?                                        |
| 13  | Jaki jest optymalny `relevance.threshold`? 0.45 to educated guess.                                                    |
| 14  | Czy stałe współprace (recurring) faktycznie podnoszą ROAS? (assumption z raportu)                                     |
| 15  | Jak Partnership Ads wpływają na FQS kalibrację? (osobny kanał konwersji)                                              |
| 16  | Jak obsłużyć influencerów, którzy chcą content rights ale nie chcą Reela? (edge case: Stories only + Extended rights) |
| 17  | Jak wygląda churn rate — ile influencerów publikuje po otrzymaniu produktu? Raport zakłada >70%, ale brak danych.     |

### Architektoniczne decyzje do podjęcia

| Decyzja                                | Opcje                                                                                                   | Rekomendacja                                                                                |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **Gdzie hostować landing page?**       | A) Subdomena framky.com/partner/ (WooCommerce) B) Osobna apka (Next.js) C) Statyczna strona (HTML + JS) | **C** na start — najprostsze. Upgrade do B jeśli potrzeba dynamicznych danych z backendu.   |
| **Gdzie liczyć FQS?**                  | A) Python script (cron/manual) B) Chatwoot service object C) n8n workflow                               | **A** na start — osobny skrypt, output do Chatwoot API. Niezależne od Chatwoot deployments. |
| **Gdzie przechowywać dane discovery?** | A) Chatwoot custom attributes only B) Osobna DB + sync do Chatwoot                                      | **A** na start — Chatwoot jest source of truth. Upgrade do B przy >100 influencerów/mies.   |

---

## Acceptance Criteria

- [ ] FQS scoring script działa z danymi z IQFluence Discovery + Report API
- [ ] FQS poprawnie obsługuje hidden likes (degraded mode)
- [ ] Sanity checks (HR1-HR7) poprawnie odrzucają fraud (walidacja na @iam_alissia)
- [ ] Discovery query dla DE zwraca >50 profili po filtrach
- [ ] Landing page z kalkulatorem vouchera działa z pre-filled parametrami
- [ ] Kalkulator poprawnie mapuje na produkty Framky (Tier 1/2/3)
- [ ] Webhook landing page → Chatwoot aktualizuje custom attributes
- [ ] Brakujące geo IDs (PL, NL, UK, AT, DK) ustalone

## Sources & References

- **Raport wdrożeniowy:** Influencer Marketing - Raport wdrożeniowy.md — FQS formuła (§3.3), wycena vouchera (§4.1), filtrry (§8.6)
- **IQFluence API:** docs/plans/influencer-discovery/discovery-api.md — Discovery, Unhide, Report endpoints
- **IQFluence Report examples:** docs/plans/influencer-discovery/report.json (domprzyrybakowce), report-2.json, report-3.json
- **Instagram Scraping API:** docs/plans/influencer-discovery/instagram-scraping-api.md — supplementary data source
