# AI-Assisted Data Quality Pipeline (Snowflake)

> One-line summary: a medallion-style ELT pipeline that profiles and validates SAP-style
> purchase order data, quarantines bad records, and uses ML to flag anomalies.

## Business problem
_TODO: why messy enterprise data between systems is costly, and why rules alone are not enough._

## Architecture
_TODO: data flow diagram (docs/architecture.png)_

Bronze (raw, all VARCHAR) -> Profiling -> Validation -> Silver (typed, valid) + Quarantine (rejects with reason) -> Anomaly detection -> Gold

## Data
Synthetic SAP-style procurement data (suppliers ~ LFA1, PO headers ~ EKKO, PO items ~ EKPO)
with known injected problems and a corruption log used as ground truth for evaluation.

## How to run
1. `pip install -r requirements.txt`
2. `python data_gen/generate_po_data.py --out data/raw`
3. Run `sql/01_setup_and_bronze.sql` in Snowsight, upload CSVs to the stage, load bronze.
4. Configure dbt: copy `dbt/profiles.yml.example` to `~/.dbt/profiles.yml`, set the SNOWFLAKE_* environment variables, then `cd dbt && dbt debug`
5. `dbt build` (staging, quarantine, silver, tests), then run the anomaly notebook
6. _TODO: remaining steps_

## Validation vs ML
_TODO: which problems are caught by deterministic rules, which by the model, and why._

## Results
_TODO: validation recall vs corruption log; anomaly model precision/recall._

## Limitations and next steps
_TODO_

## How this maps to SAP Integration Suite / BTP
_TODO_
