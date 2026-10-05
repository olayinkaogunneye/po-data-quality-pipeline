"""
Upload the generated CSVs to the Snowflake stage and load the BRONZE tables.

Run AFTER the setup SQL (sql/01_setup_and_bronze.sql, down to CREATE STAGE) has been executed.
Run from the project root:   python src/load_bronze.py

Connection details come from environment variables:
  SNOWFLAKE_ACCOUNT   e.g. myorg-myaccount
  SNOWFLAKE_USER
  SNOWFLAKE_PASSWORD  (not needed if SNOWFLAKE_AUTHENTICATOR is set)
  SNOWFLAKE_AUTHENTICATOR optional, e.g. externalbrowser for SSO / Google sign-in
  SNOWFLAKE_WAREHOUSE e.g. COMPUTE_WH
  SNOWFLAKE_ROLE      optional, defaults to ACCOUNTADMIN
"""
import os
from pathlib import Path

import snowflake.connector

RAW_DIR = Path("data/raw").resolve()

# csv file stem -> bronze table
TABLES = {
    "suppliers": "SUPPLIERS_RAW",
    "po_headers": "PO_HEADERS_RAW",
    "po_items": "PO_ITEMS_RAW",
    "ground_truth_categories": "GROUND_TRUTH_CATEGORIES",
    "corruption_log": "CORRUPTION_LOG",
}


def main():
    missing = [f"{stem}.csv" for stem in TABLES if not (RAW_DIR / f"{stem}.csv").exists()]
    if missing:
        raise SystemExit(f"Missing files in {RAW_DIR}: {missing}. Run the data generator first.")

    params = dict(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        role=os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database="PO_QUALITY",
        schema="BRONZE",
    )
    authenticator = os.environ.get("SNOWFLAKE_AUTHENTICATOR")
    if authenticator:
        # e.g. "externalbrowser" for SSO / Google sign-in: a browser window opens to log in
        params["authenticator"] = authenticator
    else:
        params["password"] = os.environ["SNOWFLAKE_PASSWORD"]
    conn = snowflake.connector.connect(**params)
    cur = conn.cursor()
    try:
        for stem, table in TABLES.items():
            path = (RAW_DIR / f"{stem}.csv").as_posix()
            print(f"Uploading {stem}.csv ...")
            cur.execute(f"PUT 'file://{path}' @PO_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE")

            # truncate first so the script can be re-run without duplicating rows
            cur.execute(f"TRUNCATE TABLE {table}")
            cur.execute(
                f"COPY INTO {table} FROM @PO_STAGE "
                f"PATTERN='.*{stem}\\\\.csv.*' FORCE=TRUE"
            )
            cur.execute(f"SELECT COUNT(*) FROM {table}")
            print(f"  loaded {cur.fetchone()[0]} rows into {table}")

        print("\nFiles on the stage:")
        for row in cur.execute("LIST @PO_STAGE").fetchall():
            print("  ", row[0], row[1], "bytes")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
