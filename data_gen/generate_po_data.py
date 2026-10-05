"""
Synthetic SAP-style purchase order data generator.

Produces CSVs modelled loosely on SAP procurement tables:
  suppliers.csv             (like LFA1)
  po_headers.csv            (like EKKO)
  po_items.csv              (like EKPO)
  ground_truth_categories.csv  true spend category per item (keep OUT of the pipeline;
                               use it only to score the LLM classification step)
  corruption_log.csv        every injected problem, so you can measure how many
                            your validation rules / anomaly model actually catch

Usage:
  pip install faker pandas numpy
  python data_gen/generate_po_data.py --suppliers 20 --pos 2000 --seed 42 --out data/raw
"""
import argparse
import random
from pathlib import Path

import numpy as np
import pandas as pd
from faker import Faker

# category -> (description templates, typical unit price)
CATEGORIES = {
    "IT Hardware": (
        ["Dell Latitude laptop 14in", "27 inch monitor", "Logitech wireless mouse",
         "USB-C docking station", "HP LaserJet printer", "Cisco network switch 24 port",
         "Mechanical keyboard", "Webcam 1080p"], 350.0),
    "Office Supplies": (
        ["A4 copy paper 500 sheets", "Ballpoint pens box of 50", "Stapler heavy duty",
         "Ring binders pack of 10", "Whiteboard markers set", "Sticky notes assorted",
         "Desk organizer", "Toner cartridge black"], 25.0),
    "Logistics Services": (
        ["Pallet freight Prague to Brno", "Express courier parcel", "Warehouse storage monthly fee",
         "Customs clearance service", "Container shipping 20ft", "Last mile delivery batch",
         "Cold chain transport", "Freight forwarding fee"], 600.0),
    "Maintenance & Spare Parts": (
        ["Hydraulic pump seal kit", "Bearing 6205 2RS", "Conveyor belt 10m",
         "Industrial lubricant 20L", "Pressure sensor replacement", "Heat exchanger gasket set",
         "V-belt B52", "Electric motor 5.5kW"], 180.0),
    "Software & Licenses": (
        ["Annual SaaS licence per seat", "Database server subscription", "Antivirus licence 100 users",
         "Cloud storage 10TB annual", "BI tool licence per seat", "Support contract renewal",
         "CAD software licence", "API gateway subscription"], 900.0),
    "Professional Services": (
        ["Consulting day rate", "External audit services", "Legal advisory hours",
         "Training workshop 2 days", "Penetration test engagement", "Translation services",
         "Recruitment agency fee", "Project management support"], 1200.0),
}
CURRENCIES = ["EUR", "USD"]


def noisy(text: str, rng: random.Random) -> str:
    """Make free text look like real-world messy ERP descriptions."""
    r = rng.random()
    if r < 0.15:
        text = text.upper()
    elif r < 0.30:
        text = text.lower()
    if rng.random() < 0.2:
        text += rng.choice([" - rush", " (urgent)", f" ref {rng.randint(1000, 9999)}", " / bulk order"])
    return text


def pick(rng, pool, n):
    n = min(n, len(pool))
    chosen = rng.sample(sorted(pool), n)
    pool.difference_update(chosen)
    return chosen


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--suppliers", type=int, default=20)
    ap.add_argument("--pos", type=int, default=2000)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--out", default="data/raw")
    args = ap.parse_args()

    rng = random.Random(args.seed)
    nprng = np.random.default_rng(args.seed)
    fake = Faker()
    Faker.seed(args.seed)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    log = []  # corruption log rows

    # ---------------- suppliers ----------------
    suppliers = []
    for i in range(1, args.suppliers + 1):
        suppliers.append({
            "supplier_id": f"S{i:03d}",
            "name": fake.company(),
            "country": rng.choice(["CZ", "DE", "PL", "SK", "AT", "NL", "US"]),
            "payment_terms": rng.choice(["NET30", "NET45", "NET60"]),
            "created_date": fake.date_between("-8y", "-1y").isoformat(),
        })
    sup = pd.DataFrame(suppliers)
    # each supplier has a preferred category and currency (gives the anomaly model something to learn)
    cat_names = list(CATEGORIES)
    sup_cat = {s: rng.choice(cat_names) for s in sup["supplier_id"]}
    sup_cur = {s: rng.choice(CURRENCIES) for s in sup["supplier_id"]}

    # ---------------- headers and items (clean) ----------------
    headers, items, truth = [], [], []
    start = pd.Timestamp("2024-01-01")
    for n in range(1, args.pos + 1):
        po_id = f"PO{n:06d}"
        sid = rng.choice(sup["supplier_id"].tolist())
        order_date = start + pd.Timedelta(days=rng.randint(0, 729))
        headers.append({"po_id": po_id, "supplier_id": sid,
                        "order_date": order_date, "currency": sup_cur[sid]})
        for k in range(1, rng.randint(1, 5) + 1):
            # mostly the supplier's main category, sometimes another
            cat = sup_cat[sid] if rng.random() < 0.8 else rng.choice(cat_names)
            templates, base = CATEGORIES[cat]
            price = round(base * float(nprng.lognormal(0, 0.25)), 2)
            items.append({
                "po_id": po_id, "item_no": k * 10,
                "description": noisy(rng.choice(templates), rng),
                "quantity": rng.randint(1, 25),
                "unit_price": price,
                "delivery_date": order_date + pd.Timedelta(days=rng.randint(5, 45)),
            })
            truth.append({"po_id": po_id, "item_no": k * 10, "true_category": cat})

    hdr = pd.DataFrame(headers)
    itm = pd.DataFrame(items)
    gt = pd.DataFrame(truth)

    # ---------------- ML targets: price / quantity outliers (applied before totals) ----------------
    n_items = len(itm)
    price_idx = nprng.choice(n_items, size=int(n_items * 0.015), replace=False)
    rest = np.setdiff1d(np.arange(n_items), price_idx)
    qty_idx = nprng.choice(rest, size=int(n_items * 0.010), replace=False)
    for i in price_idx:
        factor = rng.choice([20, 50, 100])
        itm.at[i, "unit_price"] = round(itm.at[i, "unit_price"] * factor, 2)
        log.append({"table": "po_items", "record_id": f"{itm.at[i,'po_id']}|{itm.at[i,'item_no']}",
                    "issue_type": "price_outlier", "detail": f"unit_price x{factor}", "ml_target": True})
    for i in qty_idx:
        factor = rng.choice([20, 50, 100])
        itm.at[i, "quantity"] = int(itm.at[i, "quantity"] * factor)
        log.append({"table": "po_items", "record_id": f"{itm.at[i,'po_id']}|{itm.at[i,'item_no']}",
                    "issue_type": "quantity_outlier", "detail": f"quantity x{factor}", "ml_target": True})

    # totals after outliers, so outliers are statistical anomalies, not rule violations
    itm["line_value"] = (itm["quantity"] * itm["unit_price"]).round(2)
    hdr["total_amount"] = hdr["po_id"].map(itm.groupby("po_id")["line_value"].sum().round(2))
    itm = itm.drop(columns=["line_value"])

    # dates to ISO strings (so we can later inject bad formats)
    hdr["order_date"] = hdr["order_date"].dt.strftime("%Y-%m-%d")
    itm["delivery_date"] = itm["delivery_date"].dt.strftime("%Y-%m-%d")
    hdr = hdr.astype({"order_date": "object", "currency": "object", "supplier_id": "object"})
    itm = itm.astype({"description": "object", "quantity": "object"})

    # ---------------- rule-based problems (disjoint PO sets) ----------------
    pool = set(hdr["po_id"])
    per_type = max(1, round(len(hdr) * 0.005))  # 0.5% of POs per issue type, 8 types ~ 4%

    for po in pick(rng, pool, per_type):  # missing currency
        hdr.loc[hdr.po_id == po, "currency"] = None
        log.append({"table": "po_headers", "record_id": po, "issue_type": "missing_currency",
                    "detail": "currency set to NULL", "ml_target": False})

    for po in pick(rng, pool, per_type):  # invalid currency code
        bad = rng.choice(["EURO", "EU", "US$", "XXX"])
        hdr.loc[hdr.po_id == po, "currency"] = bad
        log.append({"table": "po_headers", "record_id": po, "issue_type": "invalid_currency",
                    "detail": f"currency = {bad}", "ml_target": False})

    for po in pick(rng, pool, per_type):  # wrong date format
        m = hdr.po_id == po
        d = pd.to_datetime(hdr.loc[m, "order_date"].iloc[0])
        hdr.loc[m, "order_date"] = d.strftime("%d.%m.%Y")
        log.append({"table": "po_headers", "record_id": po, "issue_type": "bad_date_format",
                    "detail": "order_date as DD.MM.YYYY", "ml_target": False})

    for po in pick(rng, pool, per_type):  # orphan supplier
        hdr.loc[hdr.po_id == po, "supplier_id"] = "S999"
        log.append({"table": "po_headers", "record_id": po, "issue_type": "orphan_supplier",
                    "detail": "supplier_id S999 does not exist", "ml_target": False})

    for po in pick(rng, pool, per_type):  # delivery before order
        order = pd.to_datetime(hdr.loc[hdr.po_id == po, "order_date"].iloc[0])
        m = (itm.po_id == po) & (itm.item_no == 10)
        itm.loc[m, "delivery_date"] = (order - pd.Timedelta(days=rng.randint(1, 30))).strftime("%Y-%m-%d")
        log.append({"table": "po_items", "record_id": f"{po}|10", "issue_type": "delivery_before_order",
                    "detail": "delivery_date earlier than order_date", "ml_target": False})

    for po in pick(rng, pool, per_type):  # missing item field
        m = (itm.po_id == po) & (itm.item_no == 10)
        col = rng.choice(["description", "quantity"])
        itm.loc[m, col] = None
        log.append({"table": "po_items", "record_id": f"{po}|10", "issue_type": "missing_item_field",
                    "detail": f"{col} set to NULL", "ml_target": False})

    dup_rows = []
    for po in pick(rng, pool, per_type):  # exact duplicate header
        dup_rows.append(hdr[hdr.po_id == po].iloc[0].to_dict())
        log.append({"table": "po_headers", "record_id": po, "issue_type": "exact_duplicate_header",
                    "detail": "header row duplicated", "ml_target": False})
    if dup_rows:
        hdr = pd.concat([hdr, pd.DataFrame(dup_rows)], ignore_index=True)

    new_h, new_i, new_t = [], [], []
    next_n = args.pos + 1
    for po in pick(rng, pool, per_type):  # near-duplicate PO (new id, +1 day)
        new_id = f"PO{next_n:06d}"
        next_n += 1
        h = hdr[hdr.po_id == po].iloc[0].to_dict()
        h["po_id"] = new_id
        h["order_date"] = (pd.to_datetime(h["order_date"], errors="coerce") + pd.Timedelta(days=1)).strftime("%Y-%m-%d")
        new_h.append(h)
        for _, r in itm[itm.po_id == po].iterrows():
            d = r.to_dict()
            d["po_id"] = new_id
            new_i.append(d)
        for _, r in gt[gt.po_id == po].iterrows():
            d = r.to_dict()
            d["po_id"] = new_id
            new_t.append(d)
        log.append({"table": "po_headers", "record_id": new_id, "issue_type": "near_duplicate_po",
                    "detail": f"copy of {po}, order_date +1 day", "ml_target": False})
    if new_h:
        hdr = pd.concat([hdr, pd.DataFrame(new_h)], ignore_index=True)
        itm = pd.concat([itm, pd.DataFrame(new_i)], ignore_index=True)
        gt = pd.concat([gt, pd.DataFrame(new_t)], ignore_index=True)

    # ---------------- inconsistent supplier names ----------------
    variants = []
    for k, base in enumerate(rng.sample(sup.to_dict("records"), 3)):
        v = dict(base)
        v["supplier_id"] = f"S{args.suppliers + 1 + k:03d}"
        v["name"] = base["name"].upper().replace(",", "") + " Gmbh."
        variants.append(v)
        log.append({"table": "suppliers", "record_id": v["supplier_id"],
                    "issue_type": "inconsistent_supplier_name",
                    "detail": f"variant of {base['supplier_id']} ({base['name']})", "ml_target": False})
    sup = pd.concat([sup, pd.DataFrame(variants)], ignore_index=True)

    # ---------------- write ----------------
    sup.to_csv(out / "suppliers.csv", index=False)
    hdr.to_csv(out / "po_headers.csv", index=False)
    itm.to_csv(out / "po_items.csv", index=False)
    gt.to_csv(out / "ground_truth_categories.csv", index=False)
    pd.DataFrame(log).to_csv(out / "corruption_log.csv", index=False)

    print(f"suppliers: {len(sup)}  po_headers: {len(hdr)}  po_items: {len(itm)}")
    print(pd.DataFrame(log)["issue_type"].value_counts().to_string())


if __name__ == "__main__":
    main()
