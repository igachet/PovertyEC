# Ecuador LSMS 2014 – Consumption Poverty Line

<!--
DISCLAIMER: This is personal code written by the author for a specific
analytical exercise. It is shared as-is, without warranty of any kind, and
is not an official or endorsed product of any institution. Users are free
to use, copy, and adapt this code for their own purposes at their own risk.
Please verify all methodological choices and results independently before
relying on them.
-->

## Purpose

Computes Ecuador's official consumption-based poverty line and poverty
indicators from LSMS 2014 (ECV 2013-2014) household survey data, following
the cost-of-basic-needs / Engel coefficient methodology.

## Structure

```
PovertyEC/
├── README.md
├── code/
│   ├── 00_master.do                       <- run only this file
│   ├── 00a_programmes.do                  <- shared utility programs
│   ├── 01_poverty_line.do                 <- main pipeline, called by 00_master.do
│   ├── 01a_prepare_consumption_data.do     <- builds consumption aggregate components
│   ├── 01a1_education.do
│   ├── 01a2_fuel.do
│   ├── 01a3_services.do
│   ├── 01a4_non_food.do
│   ├── 01a5_food.do
│   ├── 01a6_durables.do
│   ├── 01a7_calories.do                    <- household caloric intake
│   ├── 01a7a_prepare_calories_data.do      <- calorie/weights inputs for 01a7
│   ├── 01b_cpi.do                          <- consumer price index deflator
│   ├── 01d_prov.do                         <- province/region identifiers
│   ├── 01e_region_area.do                  <- area x region (6-way) indicator
│   ├── 01f_aux_numpers.do                  <- rebuilds household members/weights
│   ├── 01g_deflactor.do                    <- merges geographic deflators
│   ├── 01i_lsms2014_results.do             <- final results matrix
│   └── ados/                               <- user-written Stata programs (not numbered)
│       ├── gcuan.do                        <- weighted quantile groups
│       └── gini-libro.do                   <- weighted Gini coefficient
├── data/
│   ├── raw/                <- raw ECV 2013-2014 survey files (not redistributed; see Data section)
│   │   └── aux_data/        <- calories.xlsx, Datos_INEC.xlsx
│   └── final/               <- EcuPoverty_LSMS2014.dta (pipeline output)
├── outputs/
│   ├── run_log.log         <- full run log
│   └── tables/              <- exported result tables (extreme poverty line, geo prices, summary)
├── data_hashes.txt         <- checksum of the final output dataset, for replicators to verify
└── LICENSE
```

The numbering in `code/` reflects call order and nesting: `01a_*` files are
called from `01a_prepare_consumption_data.do`, `01a7a_*` is called from
`01a7_calories.do`, and so on. Files in `code/ados/` define reusable Stata
programs (`gcuan`, `gini`) rather than sequential pipeline steps, so they
are not numbered.

## Computational requirements

- Stata 19 (the pipeline is version-pinned via `version 19` in
  `00_master.do`; it has not been tested on earlier releases).
- No user-installed packages (`ssc install`) are required. Two
  user-written programs are vendored in `code/ados/` (`gcuan.do`,
  `gini-libro.do`) and loaded automatically by `00a_programmes.do`.
- No random-number generation is used anywhere in the pipeline (the
  reference-population search, basket pricing, and poverty-line
  derivation are all deterministic given the raw data and the fixed
  parameters in `01_poverty_line.do`), so no seed needs to be set.

## Data integrity

After a successful run, `01_poverty_line.do` writes a Stata `checksum` of
`data/final/EcuPoverty_LSMS2014.dta` to `data_hashes.txt`. Replicators can
compare this value against their own run's `data_hashes.txt` to confirm
their output dataset is byte-identical to the one originally produced.

## License

See `LICENSE` (MIT). Note the license covers the code only; third-party
survey/data files referenced in the Data Availability Statement are
governed by their own terms of access.

## Data

Raw inputs are the ECV 2013-2014 (LSMS) household survey files
(`data/raw/ECV6R_*.dta`, `data/raw/weights.dta`) plus
`data/raw/aux_data/calories.xlsx` (2005 calorie reference values used to
homologate poverty lines across survey rounds). These files are not
redistributed here; obtain them from INEC (Ecuador) or the World Bank
Microdata Library and place them in `data/raw/` and `data/raw/aux_data/` before
running. See the Data Availability Statement below.

### Data Availability Statement

| Dataset | Source | Access | Used for |
|---|---|---|---|
| ECV 2013-2014 (LSMS) household survey | INEC Ecuador / World Bank Microdata Library | Restricted; request from source | Consumption aggregate, calories, weights |
| 2005 calorie reference (`calories.xlsx`) | [fill in: source survey/study] | [fill in] | Homologating poverty line to 2005 base |
| 2010 Census population shares (hardcoded in `01_poverty_line.do`) | INEC 2010 Census | Public | Weighting geographic basket costs |

*Fill in the bracketed cells above with the exact citation/link before
distributing this package; these are restricted-use microdata and must
not be redistributed with the code.*

## How to run

**Expected runtime:** approximately [fill in once timed, e.g. "15-20
minutes"] on a standard laptop (the survey files are moderate-sized
household/person-level `.dta` files; no step requires special hardware or
more than a few GB of RAM).

1. Open `code/00_master.do`.
2. Set the `$root` global at the top to the local path of this project.
3. Run the file. It sets up a log in `outputs/run_log.log`, loads shared
   programmes (`code/00a_programmes.do`), and runs `code/01_poverty_line.do`,
   which in turn calls every other file in `code/` in sequence.

No manual steps are required during the run; the reference-population
search and poverty-line rounding are fully deterministic given the fixed
parameters documented in `01_poverty_line.do` (caloric norms, census
population shares, and a rounding convention applied to the extreme
poverty line before computing the Engel coefficient — kept for consistency
with the original SPSS-based estimates).

## Code description

The pipeline runs in four stages, all orchestrated by `01_poverty_line.do`:

1. **Consumption aggregate** (`01a_prepare_consumption_data.do` and its
   `01a1`-`01a7a` components): builds per capita household consumption
   from food, education, fuel, utilities, rent, non-food, and durables
   components, deflated to constant prices (`01b_cpi.do`), and merges in
   household caloric intake.
2. **Reference population** (`01_poverty_line.do`, percentile section):
   ranks households by per capita consumption (`code/ados/gcuan.do`) and
   identifies the group whose mean caloric intake is closest to the
   caloric norm - this group is used to price the minimum food basket.
3. **Basket cost by geographic zone** (`01_poverty_line.do`, geo-prices
   section, using `01d_prov.do` / `01e_region_area.do` / `01f_aux_numpers.do`
   / `01g_deflactor.do`): computes the cost per calorie of the reference
   population's food basket in each of the 6 area x region zones, scaled
   to the FAO caloric norm, and weights zones by 2010 census population
   shares to get the national extreme poverty line.
4. **Engel coefficient and poverty line** (`01_poverty_line.do`, final
   section, using `01i_lsms2014_results.do`): computes the food share of
   consumption (Engel coefficient) among households near the extreme
   poverty line, divides the extreme poverty line by this coefficient to
   get the full poverty line, flags households as poor/extreme poor, and
   computes headcount rates and the Gini coefficient
   (`code/ados/gini-libro.do`).

## Output

- `outputs/run_log.log`: full run log.
- `data/final/EcuPoverty_LSMS2014.dta`: household-level dataset with the
  consumption aggregate, Engel coefficient, extreme poverty/poverty flags,
  weights, and geographic identifiers.
- `outputs/tables/extreme_poverty_line.csv`: extreme poverty line (USD/day, USD/month) for LSMS14 and LSMS05-at-LSMS14-prices.
- `outputs/tables/geo_prices.csv`: basket cost per day by the 6 area x region zones.
- `outputs/tables/lsms2014_summary.csv`: extreme poverty, poverty, Gini and Engel summary (matches `lsms2014` matrix / List of Exhibits).

## Stability check

The restructured pipeline (`code/00_master.do`) was validated against the
original, unstructured version of the scripts by running both
independently and comparing the final poverty headcount: both produce
**25.91%** (`tab poverty [w=weight_per]`), confirming the refactor
preserves the original methodology and estimates.

## List of Exhibits

| Exhibit | Description | Produced by | Output file |
|---|---|---|---|
| Extreme poverty line (USD/day, USD/month) | Cost of the minimum-calorie food basket, LSMS14 and LSMS05-at-LSMS14-prices | `01_poverty_line.do`, extreme poverty section | `outputs/tables/extreme_poverty_line.csv` |
| Basket cost by geographic zone | Daily basket cost for the 6 area x region (Costa/Sierra/Amazonia x Urban/Rural) zones | `01_poverty_line.do`, geo-prices section | `outputs/tables/geo_prices.csv` |
| Engel coefficient | Food share of consumption among households near the extreme poverty line | `01_poverty_line.do`, Engel coefficient section | `outputs/tables/lsms2014_summary.csv` |
| Poverty line (USD/day, USD/month) | Extreme poverty line / Engel coefficient | `01_poverty_line.do`, poverty line section | `outputs/tables/lsms2014_summary.csv` |
| Extreme poverty headcount rate | Share of population below the extreme poverty line | `01_poverty_line.do` / `01i_lsms2014_results.do` | `outputs/tables/lsms2014_summary.csv` |
| Poverty headcount rate | Share of population below the poverty line | `01_poverty_line.do` / `01i_lsms2014_results.do` | `outputs/tables/lsms2014_summary.csv` |
| Gini coefficient | Inequality of per capita consumption | `01_poverty_line.do` (calls `code/ados/gini-libro.do`) | `outputs/tables/lsms2014_summary.csv` |
| Final household-level dataset | Consumption aggregate, poverty flags, weights, geographic identifiers | full pipeline | `data/final/EcuPoverty_LSMS2014.dta` |

## Pre-submission checklist

- [x] All file paths are relative to a single `$root` global; no
      machine-specific hardcoded paths remain in `code/`.
- [x] The full pipeline runs end-to-end from a single entry point
      (`code/00_master.do`) with no manual/interactive steps (`pause`,
      `br`) required.
- [x] Re-running the pipeline produces identical results (see Stability
      check above).
- [x] Results are written to named output files (`outputs/tables/*.csv`,
      `data/final/*.dta`), not just the console or log.
- [x] A checksum of the final dataset is recorded (`data_hashes.txt`) for
      replicators to verify their run matches.
- [x] Software/version requirements are documented (Stata 19, no
      external packages beyond the vendored `code/ados/` programs).
- [x] No randomization/seed dependency in the pipeline.
- [x] License included (`LICENSE`, MIT, code only).
- [ ] Data Availability Statement fully completed (2005 calorie reference
      source/citation still marked `[fill in]`).
- [x] Superseded `do/` folder removed.
