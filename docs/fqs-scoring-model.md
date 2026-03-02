# FQS — Framky Quality Score

## Wzor glowny

```
FQS = ER_Factor × Views_Factor × Geo_Factor × 100
```

Kazdy czynnik odzwierciedla konkretna wartosc influencera. Wynik to iloczyn — slaby czynnik obnizy calosc proporcjonalnie.

## Czynniki

### ER Factor (0 - 3.0)

Bazuje na `engagement_rate` z API (jako decimal, np. 0.02 = 2%).

Funkcja odcinkowo liniowa:
- 0% → 0
- 2% → 1.0 (baseline)
- 5% → 2.0
- 10% → 3.0 (cap)

Bez tierow, bez hidden likes korekty — surowy ER z API.

### Views Factor (0+)

```
Views_Factor = median_reel_views / followers_count
```

Uzywa `median_reel_views` z fallback na `avg_reel_views`.
Mediana filtruje pinned/virale reelsy (np. mrs_wozniak avg=1.2M vs median=9K).

Bez capu — jezeli views >> followers to influencer jest "viralowy".

### Geo Factor (0.1 - 1.0)

```
Geo_Factor = min(eu_audience_ratio / 0.8, 1.0)
```

80% audience w Europie = pelny czynnik (1.0). Floor: 0.1.

---

## Ostrzezenia (dawne Hard Filters)

Ostrzezenia NIE blokuja score — sa wyswietlane w Profile Detail jako zolte banery.
Uzytkownik podejmuje decyzje recznie na podstawie score + ostrzezen.

Sprawdzane warunki:
- ER < 1% (zbyt niski)
- ER > 15% (kupione zaangazowanie)
- Nieaktywny > 60 dni
- Following/followers > 0.8
- Growth spike > 20% w ostatnim okresie
- Monthly growth > 5% (podejrzany wzrost)
- Likes > 2x views (kupione polubienia)
- Likes:comments > 500:1 (bot engagement)
- Mass + suspicious audience > 65%
- Audience credibility < 75%
- 3-month growth > 50%

---

## Discovery mode

Profil bez enrichment: FQS nie jest obliczany (null). Wyswietlamy tylko podstawowe dane z searcha.

---

## Czynniki w planie (jeszcze nie wdrozone)

### Audience Quality (AQ)

Na razie wyswietlamy `audience_types` (% real, mass_followers, suspicious) w UI.
Docelowo mozna dodac jako czynnik: `AQ = real_audience_ratio`.

### Interest Factor

Propozycja: `Interest_Factor = HomeDecor_weight / 0.5` (capped at 1.5, floor 0.1).
Home Decor (#1560) jest jedynym interest ktory roznicuje profile Framky.

### Niche Factor

Na razie wyswietlamy `niche_class` (content categories) w UI.
Docelowo mozna dodac jako czynnik.

---

## Przyklad: coralie_deleng (FQS 105)

```
ER = 2.84% → er_factor = 1.28
Views = 13766 / 16622 = 0.83 → views_factor = 0.83
EU = 83% / 80% = 1.0 → geo_factor = 1.0
FQS = 1.28 × 0.83 × 1.0 × 100 = 105
Warnings: 0
```

## Przyklad: nunu_interior (FQS 82, 4 warnings)

```
ER = 0.84% → er_factor = 0.42
Views = 44266 / 18266 = 2.42 → views_factor = 2.42
EU = 64% / 80% = 0.80 → geo_factor = 0.80
FQS = 0.42 × 2.42 × 0.80 × 100 = 82
Warnings: 4 (mass+suspicious >65%, credibility <75%, etc.)
```

Wysoki FQS mimo botow — AQ factor powinien to naprawic po wdrozeniu.
