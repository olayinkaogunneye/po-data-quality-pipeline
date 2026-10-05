# Data Quality Pipeline for Purchase Order Data (Snowflake + dbt)

A medallion-style ELT pipeline that ingests messy, SAP-style purchase order data, profiles and validates it, routes every bad record to a quarantine table with a reason, and measures its own accuracy against a known answer key.

The project is built around one question: **how do you stop bad data from silently flowing between enterprise systems, and how do you prove your checks actually work?**

## Status

| Component | Status |
|---|---|
| Synthetic data generator with injected problems and an answer key | Done |
| Bronze load into Snowflake (Python connector) | Done |
| Data profiling (SQL) | Done |
| Staging models and data tests (dbt) | Done |
| Quarantine and silver models (dbt) | Done |
| Evaluation of rules against the answer key (recall and precision) | Done |
| Pipeline monitoring (incremental run history and latest-snapshot view) | Done |
| Anomaly detection (Isolation Forest) for statistical outliers | Planned |
| LLM classification of free-text item descriptions | Planned |
| Gold layer, fuzzy duplicate matching, dbt docs lineage | Planned |

## Key results

| Metric | Result |
|---|---|
| Records generated | 23 suppliers, 2,020 PO headers, 6,017 PO lines |
| Problems injected (answer key) | 231 across 11 issue types |
| Caught by rule-based validation | 70 of 231 (30.3%) |
| Recall on the 7 rule-based issue types | 100% (10 of 10 each) |
| Precision of the quarantine rules | 100% (no flagged row was outside the answer key) |
| Not caught by rules, by design | 161: 148 price and quantity outliers, 10 near-duplicate POs, 3 supplier name variants |
| Row accounting | Every staging row lands in silver or quarantine: 1,970 + 50 = 2,020 headers (10 are duplicate copies); 5,875 + 142 = 6,017 lines |

The 100% figures need context: the rules were written after profiling data that we corrupted ourselves, so they are expected to match. They show that each known failure type is detected and routed correctly. They do not predict performance on real data, where problems are not known in advance. The 0% rows are the more informative result: they show what fixed rules cannot see.

## Business problem

Enterprise data moves constantly between systems, for example purchase orders flowing from an ERP into reporting and finance tools. It arrives with missing values, duplicates, wrong formats, references to records that do not exist, and values that are valid on paper but clearly wrong. If nothing checks it, those errors reach reports and decisions.

This pipeline is the checkpoint in the middle: receive everything as-is, separate trustworthy rows from untrustworthy ones, record why, and make the pipeline's health visible.

## Architecture

```
 Python generator            Snowflake                                         dbt
 (Faker, pandas)
       |
       v
   CSV files --PUT--> internal stage --COPY INTO--> BRONZE (raw, all VARCHAR)
                                                         |
                                                         v
                                                  PROFILING (SQL)
                                                         |
                                                         v
                                              STAGING (typed views, no rows removed)
                                                         |
                                  +----------------------+----------------------+
                                  v                                             v
                         QUARANTINE (failed rows,                       SILVER (typed and validated,
                          one row per broken rule)                       strict tests fail the build)
                                  |                                             |
                                  +----------------------+----------------------+
                                                         v
                                   EVALUATION (recall and precision vs answer key)
                                   MONITORING (run history, latest snapshot)
```

Schemas in the `PO_QUALITY` database: `BRONZE`, `PROFILING`, `STAGING`, `QUARANTINE`, `SILVER`, `EVALUATION`, `MONITORING`, `TEST_FAILURES`.

## Tech stack

- **Snowflake**: storage, SQL compute, stage-based file loading
- **dbt (dbt-core, dbt-snowflake)**: transformations, tests, lineage
- **Python**: data generation (Faker, pandas, numpy), loading (snowflake-connector-python)
- **SQL**: profiling, validation logic, evaluation
- **Git/GitHub, VS Code**

## The data

The data is synthetic, modelled loosely on SAP procurement tables. It is generated rather than downloaded so that problems can be injected deliberately and logged, which makes honest evaluation possible.

| Table | One row is | SAP analogue |
|---|---|---|
| `suppliers` | A supplier | Vendor master (LFA1) |
| `po_headers` | A purchase order | PO header (EKKO) |
| `po_items` | A line on an order | PO item (EKPO) |

Two further files are evaluation-only and never feed the pipeline: `ground_truth_categories` (the true spend category of each line) and `corruption_log` (one row per injected problem).

About 4% of POs carry a rule-detectable problem, plus about 2.5% of lines are statistical outliers. Injected problem types:

| Issue type | Count | Intended detection |
|---|---|---|
| missing_currency, invalid_currency, bad_date_format, orphan_supplier, exact_duplicate_header, delivery_before_order, missing_item_field | 10 each | Rules |
| price_outlier, quantity_outlier | 89, 59 | Anomaly detection (planned) |
| near_duplicate_po, inconsistent_supplier_name | 10, 3 | Fuzzy matching (planned) |

Outliers are applied before order totals are computed, so they pass every rule and can only be found statistically.

## Pipeline layers

1. **Bronze** loads the CSVs untouched. Every column is `VARCHAR` so that bad dates, invalid currency codes and nulls load without failing.
2. **Profiling** (`sql/02_profiling.sql`) records null rates, distinct counts, pattern checks and numeric spreads in the `PROFILING` schema, before any rules are written.
3. **Staging** (dbt views) converts types with `try_to_date`, `try_to_decimal` and `try_to_number`, which return NULL instead of failing. Raw date values are kept alongside typed ones so "missing" can be told apart from "wrongly formatted". Staging never deletes rows.
4. **Quarantine** (dbt tables) holds one row per broken rule per record, with a readable reason.
5. **Silver** (dbt tables) holds typed rows that passed every rule, deduplicated. Silver tests are configured with `severity: error`, so bad data reaching silver fails the build.
6. **Evaluation** compares quarantine output with the corruption log.
7. **Monitoring** appends a snapshot of row counts and failure rates on every run, and exposes the latest one as a view.

### Validation rules

| Rule | Applies to | Implemented in |
|---|---|---|
| duplicate_po_id | PO headers | quarantine model (first copy kept, extra copies logged) |
| missing_currency, invalid_currency | PO headers | quarantine model, staging tests |
| bad_date_format, missing_order_date | PO headers | quarantine model, staging tests |
| orphan_supplier | PO headers | quarantine model, relationships test |
| missing_description, missing_quantity | PO lines | quarantine model, staging tests |
| delivery_before_order | PO lines | quarantine model, singular dbt test |
| parent_po_quarantined | PO lines | quarantine model |

## Results in detail

### Recall by injected issue type

| Issue type | Intended method | Injected | Caught by rules | Recall |
|---|---|---|---|---|
| bad_date_format | Rules | 10 | 10 | 100% |
| delivery_before_order | Rules | 10 | 10 | 100% |
| exact_duplicate_header | Rules | 10 | 10 | 100% |
| invalid_currency | Rules | 10 | 10 | 100% |
| missing_currency | Rules | 10 | 10 | 100% |
| missing_item_field | Rules | 10 | 10 | 100% |
| orphan_supplier | Rules | 10 | 10 | 100% |
| inconsistent_supplier_name | Fuzzy matching (not built) | 3 | 0 | 0% |
| near_duplicate_po | Fuzzy matching (not built) | 10 | 0 | 0% |
| price_outlier | Anomaly detection (not built) | 89 | 0 | 0% |
| quantity_outlier | Anomaly detection (not built) | 59 | 0 | 0% |

### Precision by rule

Every quarantine rule matched the answer key exactly: `bad_date_format`, `delivery_before_order`, `duplicate_po_id`, `invalid_currency`, `missing_currency` and `orphan_supplier` flagged 10 of 10, `missing_description` 6 of 6 and `missing_quantity` 4 of 4, with zero rows outside the log.

### Profiling findings

Before any rules existed, profiling already exposed most of the planted problems: 10 null currencies, 5 distinct currency values where 2 are valid, 2,010 distinct PO IDs in 2,020 header rows, a `supplier_id` of `S999` that is not in the supplier table, and dotted dates mixed in with ISO dates. It also showed why a single threshold cannot find outliers: unit price runs from about 12 to 162,953, with the 95th percentile near 1,269 and the 99th near 10,633. Prices differ by an order of magnitude between spend categories, so a high price is only suspicious relative to its supplier or category.

## Design decisions

- **Bronze is all text.** Rejecting a bad row on arrival loses information. Typing happens in staging, where failures become visible NULLs.
- **Synthetic data with an answer key.** Real data has no list of its own errors. Injecting and logging problems turns "it seems to work" into measured recall and precision.
- **Quarantine is one row per broken rule.** A record that breaks two rules appears twice, so failures can be counted and scored per rule.
- **Nothing disappears silently.** Lines whose parent PO is quarantined are logged as `parent_po_quarantined` instead of vanishing, so staging equals silver plus quarantine.
- **Duplicates keep their first copy.** An extra copy is evidence of a problem, but it is not a reason to distrust the PO itself.
- **Staging tests warn, silver tests fail.** The raw data is deliberately dirty, so warnings are the right level early on. The trusted layer must not accept bad data.
- **Failing rows are stored.** dbt saves the rows behind each test warning in `TEST_FAILURES`, so every warning can be inspected.
- **Credentials stay out of the repo.** dbt reads connection details from environment variables through a `profiles.yml` kept outside the project.

## How to run

Requirements: Python 3.10+, a Snowflake account, Git Bash or similar.

```bash
# 1. Environment
python -m venv .venv
source .venv/Scripts/activate        # Windows (Git Bash); on Mac/Linux: source .venv/bin/activate
pip install -r requirements.txt

# 2. Generate the data (seeded, so counts are reproducible)
python data_gen/generate_po_data.py --out data/raw
```

3. In Snowflake, run `sql/01_setup_and_bronze.sql` from the top down to and including `CREATE OR REPLACE STAGE PO_STAGE`. This creates the database, schemas, raw tables and stage.

```bash
# 4. Connection details (current terminal only; do not commit these)
export SNOWFLAKE_ACCOUNT="<org-account>"
export SNOWFLAKE_USER="<user>"
export SNOWFLAKE_PASSWORD='<password>'
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"

# 5. Upload the CSVs and load the bronze tables
python src/load_bronze.py
```

6. Optionally run `sql/02_profiling.sql` in Snowflake.

```bash
# 7. dbt
mkdir -p ~/.dbt && cp dbt/profiles.yml.example ~/.dbt/profiles.yml
cd dbt
dbt debug      # should end with "All checks passed!"
dbt build      # staging, quarantine, silver, evaluation, monitoring, and all tests
```

Then inspect the results:

```sql
SELECT * FROM PO_QUALITY.EVALUATION.DQ_ISSUE_RECALL;
SELECT * FROM PO_QUALITY.EVALUATION.DQ_RULE_PRECISION;
SELECT * FROM PO_QUALITY.MONITORING.DQ_MONITORING_LATEST;
```

Staging tests are expected to report 8 warnings, because the data contains planted problems.

## Project structure

```
.
├── data_gen/generate_po_data.py   synthetic data and corruption log
├── src/load_bronze.py             stage upload and COPY INTO
├── sql/
│   ├── 01_setup_and_bronze.sql    database, schemas, raw tables, stage
│   └── 02_profiling.sql           column profile, pattern checks, distributions
├── dbt/
│   ├── dbt_project.yml
│   ├── profiles.yml.example       connection template (no credentials)
│   ├── macros/generate_schema_name.sql
│   ├── models/{staging,quarantine,silver,evaluation,monitoring}/
│   └── tests/                     singular tests
├── data/raw/                      generated CSVs (git-ignored)
├── docs/  results/  notebooks/
└── requirements.txt
```

## Limitations

- The data is synthetic. Rule recall and precision are measured against problems I created, so they show correct behaviour, not real-world accuracy.
- Rules only catch problems someone anticipated. 70% of injected problems are outside their reach.
- Supplier name variants are not detected, so they still reach silver.
- The monitoring history grows with every run and has no retention policy.
- Credentials use a password in environment variables. A production setup would use key-pair authentication or a secrets manager.

## Roadmap

1. **Anomaly detection.** Train an Isolation Forest on silver features (price relative to the supplier's norm, quantity relative to typical, order frequency), track experiments, write scores back to Snowflake, and score it against the 148 injected outliers.
2. **LLM classification.** Classify free-text item descriptions into spend categories with schema-constrained output, confidence scores and a human-review queue for low-confidence rows, scored against `ground_truth_categories`.
3. **Gold layer.** Join silver with anomaly scores and categories into curated tables.
4. **Fuzzy matching** for near-duplicate POs and inconsistent supplier names.
5. **dbt docs and a lineage graph**, plus scheduling of the full run.

## How this would map to SAP Integration Suite and BTP

This project does not use SAP software. The mapping below is how its pieces correspond conceptually to an SAP integration landscape.

| This project | SAP Integration Suite / BTP concept |
|---|---|
| Generator and CSV extracts | Source system, such as S/4HANA exposing OData or IDoc messages |
| `load_bronze.py` and the stage | An integration flow landing payloads in a target system |
| Quarantine with a reason per record | Exception handling and error queues in an integration flow |
| Silver tests that fail the build | Validation steps that stop a message from reaching the receiver |
| Monitoring run history | Message monitoring and operational dashboards |
| `dbt build` on a schedule | Scheduled integration flows or jobs on BTP |

## Skills demonstrated

ELT design, data profiling, data validation and data quality testing, SQL transformation modelling with dbt, Snowflake loading and schema design, Python scripting, evaluation design, and documentation of design trade-offs.
