# Airport Transfer Cost Dataset — Southeast & East Asia

> A hand-verified dataset of airport-to-city transport options in Bangkok, Seoul, and Singapore, built for travellers who need to know what a transfer will actually cost — and what happens when they land at 1 a.m.

**17 routes · 3 cities · 25 fields · every price traced to a named source**

Built by Trịnh Ngọc Tú · Last verified: August 2026 https://www.linkedin.com/in/trinhngoctulady/

---

## Why this exists

Search "how to get from Suvarnabhumi to the city" and you get a hundred blog posts. Every
one answers the same question the same way: a single price, no date, no source, no way to
compare against anywhere else.

None of them answer the question a traveller actually has:

> *"My flight lands at 1 a.m., I have a large suitcase, I'm travelling with three friends,
> and I have 400,000 VND. What should I do?"*

That question needs **structured data**, not prose. This project builds it.

The target user is a Vietnamese traveller going abroad independently for the first time —
budget-conscious, moderate English, and disproportionately likely to book cheap red-eye
flights that land after public transport has stopped running.

---

## Key findings

**1. The late-night penalty is real and it is large.**

In Bangkok, every public option shuts down in the evening — the S1 bus at 20:00, the
Airport Rail Link at 24:00. A traveller landing at 1 a.m. has no option under 312,000 VND,
against 35,100 VND for the same trip by train in daylight. **A cheap red-eye flight can
cost 8.9× more to get out of the airport.**

**2. The same pattern holds in all three cities.**

| City | Cheapest / most expensive, solo | Same gap, group of 4 |
|---|---|---|
| Seoul | 14.5× | 3.6× |
| Bangkok | 13.3× | 3.3× |
| Singapore | 11.0× | 2.8× |

Singapore penalises the convenience-seeker least, which tracks with it having the
strongest public transport of the three.

**3. Group size flips the recommendation.**

Every guide says "take the train, it's cheaper." That advice is correct for one person and
wrong for a family. Because taxis are priced *per vehicle* and trains *per person*, a group
of four in Bangkok pays 78,000 VND each for a door-to-door taxi versus 35,100 VND for a
train with stairs and no luggage rack. The gap collapses from 8.9× to 2.2×.

This finding is only visible because the schema distinguishes `per_person` from
`per_vehicle` pricing — see [Schema decisions](#schema-decisions).

**4. Language difficulty correlates with price uncertainty — tentatively.**

Routes scored 2–3 on `language_difficulty_1_5` (self-service machines, fixed fares) have a
price spread of 1.0 — the price is the price. Routes scored 4 (verbal negotiation with a
driver) spread to 1.38–1.67. The hypothesis is that *not speaking the local language is a
measurable cost*, not just an inconvenience.

**With 17 rows this is a hypothesis, not a conclusion.** Some cells hold only one or two
routes. Testing it properly needs more cities.

---

## Method

Prices for this kind of thing are not published in one place, and the sources that do exist
disagree. The collection protocol was fixed before data entry began:

1. **Official operator source first** — airport authority, rail company, or transit agency.
2. **One recent secondary source** for the practical detail official pages omit (which
   counter, cash or card, what to say).
3. **A community source** (Reddit, recent vlogs) for scam and surcharge context only —
   never for prices.

Every row carries a `source_url` and a `last_updated` date. Where sources conflicted, the
row takes the **lowest minimum and highest maximum** across sources, with all sources
recorded. A wide range is honest information: it tells the user this route is
unpredictable.

### Why the protocol matters

An early Bangkok row recorded the S1 airport bus as running 05:00–23:00, taken from a
single travel-booking page. The official Suvarnabhumi Airport site gives 06:00–20:00.

The three-hour error was not cosmetic. It sat directly on top of the project's main
finding: a traveller landing at 21:00 would have been told a 46,800 VND bus was available
when the only real option cost 312,000 VND. The two-source rule caught it. A single-source
dataset would have shipped it.

---

## Schema decisions

Three fields in this dataset do not appear in commercial travel data, and they carry most
of its value.

**`operates_from` / `operates_to`** — Booking platforms model transport as always
available, because their inventory is. Public transport is not. These two fields are what
make the late-night analysis possible at all.

**`language_difficulty_1_5`** — A subjective 1–5 score for how hard the route is *without
the local language*. 1 is a fully self-service English interface (a ride-hail app); 5
requires verbal negotiation. No transactional dataset generates this field, because no
booking system has a reason to record it.

**`price_basis`** — `per_person` or `per_vehicle`. Added after the initial build, when
group-size calculations started returning nonsense: the schema had been treating a 400 THB
taxi fare and a 45 THB train ticket as the same kind of number. Trains scale with headcount;
taxis do not. Without this field every multi-passenger estimate is wrong.

### Full field list

| Field | Notes |
|---|---|
| `route_id` | `CITY-NN`, e.g. `BKK-01` |
| `city`, `country`, `origin`, `destination` | |
| `method_type` | `metro` / `train` / `bus` / `taxi` / `ride_hail` / `private_car` |
| `method_name` | Local operator name |
| `currency`, `price_min_local`, `price_max_local` | Range in local currency |
| `price_min_vnd`, `price_max_vnd` | Derived via the `rates` sheet |
| `price_basis` | `per_person` / `per_vehicle` |
| `duration_min`, `duration_max` | Minutes |
| `comfort_1_5` | 1 = standing, no aircon. 5 = private door-to-door |
| `luggage_ok` | `yes` / `tight` / `no` — scored for a 24-inch suitcase |
| `operates_from`, `operates_to` | 24h. `24:00` means runs to midnight |
| `how_to_buy` | Concrete: which counter, cash or card, what to say |
| `app_needed` | App to install before departure |
| `language_difficulty_1_5` | See above |
| `scam_risk_note` | Known overcharge patterns, and legitimate surcharges |
| `source_url` | One or more, `;`-separated |
| `last_updated` | `YYYY-MM-DD` |

---

## Pipeline

Excel is the source of truth. The CSV and the database are generated and must never be
edited by hand.

```
metravel_transport_dataset.xlsx   ← the only file you edit
            │
            │  python3 refresh.py
            ▼
   transport_prices.csv  ──►  metravel.db  ──►  quality report
                                                (10 automated checks)
```

`refresh.py` exports, loads, and then validates. It flags missing prices, missing sources,
missing scores, `min > max`, non-standard `luggage_ok` and `price_basis` values, and any
row still marked unverified. The dataset is only considered publishable when every check
returns zero.

### Running it

```bash
pip3 install openpyxl
python3 refresh.py
sqlite3 metravel.db < analysis.sql
```

---

## Files

| File | Purpose |
|---|---|
| `metravel_transport_dataset.xlsx` | Source of truth. Includes a README sheet and an exchange-rate sheet |
| `transport_prices.csv` | Flat export, generated |
| `refresh.py` | ETL + data quality checks |
| `analysis.sql` | Seven analytical queries with commentary |

`metravel.db` is generated and not tracked.

---

## Limitations

**Sample size.** 17 routes across 3 cities. Enough to observe a pattern, not enough to
support statistical claims. The language-difficulty finding in particular rests on cells
holding one or two routes.

**Source hierarchy is uneven.** Bangkok and Seoul rows are anchored to airport-authority
pages. Singapore rows currently rest on recent travel guides rather than the Changi
Airport official site — a known weakness, flagged rather than hidden.

**Subjective fields.** `comfort_1_5` and `language_difficulty_1_5` are one person's
judgement. They were scored in a single pass across all rows to keep the scale consistent —
an earlier version scored city by city and the scale drifted noticeably between them.

**Prices decay.** Every row is dated. Anything older than roughly six months should be
re-verified before use.

**Route coverage.** One or two destinations per airport, chosen as the most common
first-time-traveller destinations. Not a complete map of either city.

---

## Roadmap

- Re-anchor Singapore rows to Changi Airport official sources
- Add per-day cost baselines (food, accommodation, activities) by travel style, to support
  full-trip budget estimates
- Automated staleness check: flag any row where `last_updated` exceeds 180 days
- Public web interface with filtering by arrival time, group size, and budget

---

## License

<!-- TODO: chọn một license. MIT hoặc CC BY 4.0 đều hợp lý cho dataset. -->

Data compiled from publicly available sources, each cited per row. Please retain
attribution and the `last_updated` dates if you reuse it.
## License

MIT License — see [LICENSE](LICENSE).

Data compiled from publicly available sources...