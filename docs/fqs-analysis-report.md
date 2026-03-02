# Analiza FQS — Raport i Propozycje Zmian

## Context

Analiza 5 rekordów influencerów w bazie (4 z pełnym enrichment, 1 discovery-only). Wszystkie 4 enriched profile zostały odrzucone — 100% rejection rate. Raport identyfikuje bugi, słabe punkty scoringu i propozycje napraw.

---

## KRYTYCZNE BUGI

### BUG 1: HF6 — target_market "GERMANY" → "GE" (fałszywy reject)

**Plik**: `app/services/influencers/fqs/hard_filter.rb:115`

API `ig['country']` zwraca **nazwę kraju** ("Germany"), nie kod ISO ("DE"). `target_market` przechowuje surową wartość. HF6 bierze `country.to_s.upcase[0, 2]` — "GERMANY" → "GE" (Georgia), nie "DE" (Germany).

**Wpływ**: `lacasadelaurii` i `swz.living` fałszywie odrzucone jako "poza EU".

**Dotknięci**: Każdy profil, gdzie API zwraca pełną nazwę kraju zamiast kodu ISO.

**Fix**: Dodać mapowanie `country_name → ISO_code` lub normalizację w `ResponseParser`.

> Proponuję zrezygnować z HF6 - mamy w FQS wskaźnik % audience w EU, tym będziemy się posługiwać.

---

### BUG 2: Hidden likes nie wykrywane (swz.living)

**Plik**: `app/services/influencers_club/response_parser.rb:94`

`swz.living` ma `avg_likes: 3.0` przy `followers: 8901`. To ewidentnie ukryte polubienia. Ale próg `< 0.0001` (0.01%) to:

- 3/8901 = 0.000337 = 0.034% — **powyżej progu**, więc nie wykrywane.
- Żeby wykryć, potrzeba < 0.89 likes, co jest absurdalnie niskie.

**Konsekwencja**: Profile z ukrytymi likes traktowane jak normalne, co zaniża ER quality score i odpala HF1 (zamiast przejść na degraded scoring).

> jeżeli mamy sytuacje w których są hidden likes, które zaburzają mocno wskaźnik ER, to musimy znaleźć lepszy sposób - czy widzimy ile jest likes dla poszczególnych postów (np. ostatnie posty)? Żeby wykrywać sytuację w której mamy ukrywane likes i sztucznie zaniżony ER.

---

### BUG 3: API ER vs Computed ER — masywna rozbieżność

**Dane**:

| Profil         | API ER | Computed (likes+comments)/followers | Różnica |
| -------------- | ------ | ----------------------------------- | ------- |
| nunu_interior  | 0.843% | 1.198%                              | 1.4x    |
| lacasadelaurii | 1.679% | 5.72%                               | 3.4x    |
| wohnsinnig_    | 0.115% | 5.91%                               | **51x** |
| swz.living     | 0.438% | 0.448%                              | 1.0x    |

`wohnsinnig_` ma ER 0.115% wg API, ale 1181 avg_likes / 20424 followers = 5.78%. Ta rozbieżność 51x oznacza, że API liczy ER inaczej (możliwe: waży ostatnie posty inaczej, uwzględnia reach, albo dane są po prostu stale).

**Konsekwencja**: `wohnsinnig_` z 1181 likes i 5.78% "prawdziwym" ER jest odrzucane przez HF1 za ER 0.115% < 1.5%. To falsy reject.

**Fix**: Walidacja — jeśli `(avg_likes + avg_comments) / followers` daje >2x wyższy ER niż API, użyć computed ER zamiast API ER. Albo przynajmniej logować rozbieżność.

---

## PROBLEMY ZE SCORINGIEM

### Problem 4: quality_bonus dodawane przy zerowym base ER

**Plik**: `app/services/influencers/fqs/stage1_scorer.rb:40-50`

`wohnsinnig_` ma ER ratio 0.046 → `er_base_score = 0`. Ale `quality_bonus` (likes:comments = 1181/25.83 = 45.7 → 4 pkt) dodawane jest i tak. Wynik: `er_quality: 4` zamiast 0.

**Problem**: Quality bonus ma sens tylko gdy bazowy ER jest przyzwoity. Przy zerowym base, bonus fałszywie podnosi score.

**Fix**: `return 0 if base.zero?` przed dodaniem bonusu, albo `bonus = base > 0 ? quality_bonus : 0`.

> Nie rozumiem tego wskaźnika - co on wnosi do analizy?

---

### Problem 5: Niche fit = 20/20 dla WSZYSTKICH profili

Wszystkie 4 enriched profile dostały 20/20 za niche fit. Metryka nie różnicuje — skoro wszyscy dostają max, to 20 punktów jest "darmowych" i nie pomaga w rankingu.

**Przyczyna**: Kategorie (home, interior, family, photography, diy) mają szerokie keywordy. "design", "lifestyle", "photo" to bardzo ogólne terminy. Bio matching `include?` łapie fragmenty słów.

**Fix**:

- Zaostrzyć matchowanie (word boundary, nie substring)
- Dodać wagi per kategoria (exact match > partial match)
- Albo zmniejszyć max do 10 pkt i przenieść 10 pkt na ważniejsze metryki

> Jak szczegółowo jest wyliczany niche fit? Faktycznie powinniśmy zmniejszyć jego wagę np. do 5 punktów.

---

### Problem 6: Hard filter raportuje tylko PIERWSZY failure

**Plik**: `app/services/influencers/fqs/hard_filter.rb:16`

`.find` zatrzymuje się na pierwszym fail. `nunu_interior` ma HF1 + HF10 + HF11 (trzy failures!), ale raport pokazuje tylko HF1.

**Konsekwencja**: Nie widać pełnego obrazu problemów z profilem. Przy review manualnym nie wiadomo ile jest problemów.

**Fix**: Zamienić `.find` na `.select`, zapisywać listę failures, raportować all reasons.

---

### Problem 7: Audience credibility scoring za hojny na dole

**Plik**: `app/services/influencers/fqs/stage2_scorer.rb:33-40`

`nunu_interior` ma credibility 20.3% i dostaje **4 pkt** (takie same jak 79.9%). Profil z 20% credibility to spam/boty — powinien dostać 0.

**Obecne progi**: ≥0.9 → 12, ≥0.8 → 8, <0.8 → 4
**Propozycja**: ≥0.9 → 12, ≥0.8 → 8, ≥0.7 → 4, ≥0.5 → 2, <0.5 → 0

---

### Problem 8: Growth score — nadmierny wzrost nie karany wystarczająco

**Plik**: `app/services/influencers/fqs/stage1_scorer.rb:125-133`

`nunu_interior` ma 6.24% monthly growth i dostaje 7 pkt. Ale 6.24%/msc to ~100% rocznie — podejrzane dla organic growth.

**Obecne progi**: 2-5% → 10, ≥1% → 7, ≥0% → 4, <0 → 0
**Problem**: >5% dostaje tyle samo co 1%, choć >5% jest bardziej podejrzane.

**Propozycja**: 2-5% → 10, 1-2% → 7, 0-1% → 4, <0 → 0, >5% → 4 (zamiast 7) — lub dodać HF dla monthly growth >8%.

---

## RAPORT SZCZEGÓŁOWY PER PROFIL

### 1. nunu_interior (FQS: 68, rejected by HF1)

| Komponent        | Score  | Max     | Analiza                                                                                    |
| ---------------- | ------ | ------- | ------------------------------------------------------------------------------------------ |
| niche_fit        | 20     | 20      | Max — ok, to profil interior                                                               |
| er_quality       | 5      | 20      | ER 0.843% vs median 2.5% (ratio 0.34) → base 0 + bonus 5 (likes:comments = 143/76 = 1.9:1) |
| reel_views       | 12     | 15      | Views/followers = 2.41 — silny wynik                                                       |
| growth           | 7      | 10      | 6.24%/msc → 7 pkt (powyżej sweet spot 2-5%)                                                |
| audience_quality | 9      | 20      | Credibility 20.3% → 4pkt + Reachability 21% → 5pkt                                         |
| audience_fit     | 15     | 15      | EU 64.4% → 10pkt + interests max 5pkt                                                      |
| **TOTAL**        | **68** | **100** |                                                                                            |

**Hard filters failed**: HF1 (ER 0.843% < 1.5%), **HF10** (mass+suspicious 81.8% > 65%), **HF11** (credibility 20.3% < 75%)

**Ocena**: Słuszny reject. 76% mass followers + 20% credibility = masywny bot audience. Ale FQS 68 jest zawyżony — audience_quality 9/20 za 20% credibility to za dużo.

---

### 2. lacasadelaurii (FQS: 61, rejected by HF6)

| Komponent        | Score  | Max     | Analiza                                                                                      |
| ---------------- | ------ | ------- | -------------------------------------------------------------------------------------------- |
| niche_fit        | 20     | 20      | Max                                                                                          |
| er_quality       | 4      | 20      | ER 1.679% vs 2.5% median (ratio 0.67) → base 0 + bonus 4 (likes:comments = 1473/62 = 23.8:1) |
| reel_views       | 5      | 15      | Views/followers = 0.71 → 5pkt                                                                |
| growth           | 7      | 10      | 1.43%/msc → 7pkt                                                                             |
| audience_quality | 16     | 20      | Credibility 82.8% → 8pkt + Reachability 62.1% → 8pkt                                         |
| audience_fit     | 9      | 15      | EU 35.6% → 4pkt + interests 5pkt                                                             |
| **TOTAL**        | **61** | **100** |                                                                                              |

**Hard filters failed**: **HF6** (target_market "GERMANY" → "GE" ≠ EU) — **BUG! Fałszywy reject.**

**Ocena**: Ten profil powinien przejść HF6 (Niemcy to EU). Bez tego buga, byłby w manual review (61 < 70). Profil ma przyzwoite metryki: 82.8% credibility, 62.1% reachability. Główna słabość to niski EU audience (35.6%) i średni ER.

---

### 3. wohnsinnig_ (FQS: 51, rejected by HF1)

| Komponent        | Score  | Max     | Analiza                                                              |
| ---------------- | ------ | ------- | -------------------------------------------------------------------- |
| niche_fit        | 20     | 20      | Max                                                                  |
| er_quality       | 4      | 20      | API ER 0.115% → base 0 + bonus 4 (likes:comments = 1181/26 = 45.7:1) |
| reel_views       | 0      | 15      | Views/followers = 0.34 < 0.5 → 0pkt                                  |
| growth           | 0      | 10      | -1.7%/msc → 0pkt (ujemny wzrost)                                     |
| audience_quality | 12     | 20      | Credibility 77.1% → 4pkt + Reachability 78.9% → 8pkt                 |
| audience_fit     | 15     | 15      | EU 86.8% → 10pkt + interests 5pkt                                    |
| **TOTAL**        | **51** | **100** |                                                                      |

**Hard filters failed**: HF1 (ER 0.115% < 1.5%), **HF3** (last post 2025-12-21, inactive >60 days)

**Ocena**: HF3 (inaktywny) jest uzasadniony. Ale HF1 bazuje na API ER 0.115%, podczas gdy computed ER (z avg_likes) to 5.9% — **51x rozbieżność**. Prawdziwe ER tego profilu jest prawdopodobnie ok. Audience świetny: 86.8% EU, 77% credibility, 78.9% reachability.

---

### 4. swz.living (FQS: 59, rejected by HF1)

| Komponent        | Score  | Max     | Analiza                                                                                             |
| ---------------- | ------ | ------- | --------------------------------------------------------------------------------------------------- |
| niche_fit        | 20     | 20      | Max                                                                                                 |
| er_quality       | 5      | 20      | ER 0.438% vs 4% median (ratio 0.11) → base 0 + bonus 5 (likes:comments = 3/37 = 0.08 → 5pkt bonus!) |
| reel_views       | 0      | 15      | Brak danych reels → 0pkt                                                                            |
| growth           | 10     | 10      | 4.07%/msc → max 10pkt (sweet spot)                                                                  |
| audience_quality | 12     | 20      | Credibility 74.5% → 4pkt + Reachability 68.6% → 8pkt                                                |
| audience_fit     | 12     | 15      | EU 53.6% → 7pkt + interests 5pkt                                                                    |
| **TOTAL**        | **59** | **100** |                                                                                                     |

**Hard filters failed**: HF1 (ER 0.438% < 2%), **HF6** (target_market "GERMANY" → "GE" — BUG), **HF11** (credibility 74.5% < 75%)

**Problemy**:

- avg_likes = 3.0 = ewidentnie hidden likes, ale nie wykryte
- Bonus 5pkt za likes:comments ratio 0.08:1 jest absurdalny — 3 likes vs 37 comments to odwrócony pattern (komentarze > likes = ukryte polubienia, nie "quality engagement")

---

## PODSUMOWANIE ZNALEZIONYCH PROBLEMÓW

| #   | Typ     | Severity     | Opis                                                             |
| --- | ------- | ------------ | ---------------------------------------------------------------- |
| 1   | BUG     | **CRITICAL** | HF6: "GERMANY" → "GE" zamiast "DE" — fałszywe rejecty            |
| 2   | BUG     | **HIGH**     | Hidden likes nie wykrywane (próg 0.0001 za niski)                |
| 3   | BUG     | **HIGH**     | API ER vs computed ER — do 51x rozbieżność, fałszywe HF1 rejecty |
| 4   | SCORING | **MEDIUM**   | quality_bonus dodawany przy zerowym base ER                      |
| 5   | SCORING | **MEDIUM**   | niche_fit 20/20 dla wszystkich — brak dyskryminacji              |
| 6   | UX      | **MEDIUM**   | Hard filter raportuje tylko pierwszy failure                     |
| 7   | SCORING | **LOW**      | Credibility <50% dostaje 4/12 zamiast 0                          |
| 8   | SCORING | **LOW**      | Growth >5% nie karany — dostaje tyle co 1%                       |

---

## PROPONOWANE ZMIANY

### Faza 1: Bug fixes (krytyczne)

1. **Fix HF6 country mapping** — W `ResponseParser.parse_enrich`, zmapować `ig['country']` na ISO code przed zapisem do `target_market`. Dodać mapping hash lub użyć gem `countries`.

2. **Fix hidden likes detection** — Podnieść próg z `0.0001` na `0.003` (0.3%), lub porównywać z `tier_min_er / 5`.

3. **Dodać ER sanity check** — W FqsCalculator, przed scoringiem porównać API ER z `(avg_likes + avg_comments) / followers`. Jeśli computed > 3x API, użyć computed. Logować rozbieżność.

### Faza 2: Scoring improvements

4. **quality_bonus warunkowy** — Nie dodawać bonusu gdy `er_base_score == 0`.

5. **Zaostrzyć niche matching** — Dodać word boundary (`\b` regex) zamiast `include?` w bio. Rozważyć podwyższenie progu z 1 kategorii = 8pkt do 2 kategorii minimum.

6. **Hard filter — wszystkie failures** — Zmienić `evaluate` by zbierał wszystkie failures, nie tylko pierwszy.

7. **Credibility scoring granulacja** — Dodać progi: ≥0.9→12, ≥0.8→8, ≥0.7→4, ≥0.5→2, <0.5→0.

8. **Growth penalizacja >5%** — Zmienić na: 2-5%→10, 1-2%→7, 5-8%→4, 0-1%→4, >8%→0, <0→0.

### Faza 3: Architectural

9. **Likes:comments ratio sanity** — Jeśli `avg_comments > avg_likes * 2`, traktować jako anomalię (ukryte likes lub engagement pod/ring).

10. **Discovery scoring** — Dodać followers_count i following_count ratio do discovery scoring (mamy te dane). Nie opierać się wyłącznie na ER.

---

## PLIKI DO MODYFIKACJI

- `app/services/influencers_club/response_parser.rb` — country name→code mapping, hidden likes threshold
- `app/services/influencers/fqs/hard_filter.rb` — evaluate all failures, target_market handling
- `app/services/influencers/fqs/stage1_scorer.rb` — quality_bonus conditional, growth scoring
- `app/services/influencers/fqs/stage2_scorer.rb` — credibility scoring thresholds
- `app/services/influencers/fqs/niche_matcher.rb` — word boundary matching
- `app/services/influencers/fqs_calculator.rb` — ER sanity check, discovery scoring enhancement

## WERYFIKACJA

1. Po fixach, re-run FqsCalculator na wszystkich profilach i porównać wyniki
2. `lacasadelaurii` powinno przejść HF6 po fixie country mapping
3. `swz.living` powinno być wykryte jako hidden_likes
4. `wohnsinnig_` powinno używać computed ER zamiast API ER
5. `nunu_interior` powinno mieć audience_quality bliższe 0 niż 9
