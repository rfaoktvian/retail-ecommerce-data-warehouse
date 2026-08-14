# Data Quality Findings & Preprocessing Decisions — Bronze → Silver

**Source:** `data_quality_check.py` run on bronze-layer data (Olist retail e-commerce dataset)
**Purpose:** Translate DQ profiling results into concrete silver-layer transformation decisions before writing dbt models.

---

## 1. customers

| Finding | Decision | Rationale |
|---|---|---|
| No missing values, no duplicates on `customer_id` | Pass through with type casting only | Data is clean; no cleaning logic needed |
| `customer_state` has exactly 27 unique values | Optionally add `accepted_values` dbt test on `customer_state` | Confirms this is a bounded domain (Brazilian states) — good candidate for a validity test, not a transformation |
| `customer_city` has 4,119 unique values, likely free-text with casing/typo variance | Standardize: lowercase + trim whitespace | Prevents the same city being split into multiple values downstream (e.g. in `dim_customers` or geography rollups) |

---

## 2. orders

| Finding | Decision | Rationale |
|---|---|---|
| Nulls in `order_approved_at` (0.16%), `order_delivered_carrier_date` (1.79%), `order_delivered_customer_date` (2.98%) | **Keep as null** — do not impute | These are legitimate business states (order hasn't reached that stage yet), not data errors. Consider adding a derived boolean flag instead, e.g. `is_delivered` |
| **166 rows where `order_delivered_carrier_date` < `order_purchase_timestamp`** | Flag with `dwh_is_date_anomaly = true`, do **not** silently drop | Logically impossible (shipped before purchased) — a genuine source data issue. Flagging preserves auditability; excluding without a record would hide the anomaly from stakeholders |
| `order_status` has 8 categories (`delivered`, `shipped`, `canceled`, etc.) | Add `accepted_values` dbt test | Bounded domain — worth enforcing as a test rather than a transformation |
| 0 orphan `customer_id` vs. `customers` | No action needed | Referential integrity holds |

---

## 3. products

| Finding | Decision | Rationale |
|---|---|---|
| 610 rows (1.85%) null across `product_category_name`, `product_name_lenght`, `product_description_lenght`, `product_photos_qty` simultaneously | Investigate first: confirm these are the *same* 610 rows. If so, treat as "incomplete listings" — keep the rows but set `product_category_name` to `'unknown'` rather than leaving null (since gold-layer joins/group-bys on category will otherwise silently drop these products) | A category-less product still generated real sales — dropping it would understate revenue in `fact_sales`. An explicit `'unknown'` bucket keeps it visible |
| 2 rows null in weight/dimension columns | Keep as null or exclude only from weight/dimension-specific analyses | Too small a sample (0.01%) to materially affect logistics-related metrics either way — but shouldn't be imputed with fabricated values |
| **4 products with `product_weight_g = 0`** | Flag with `dwh_is_weight_anomaly = true` | Physical products can't legitimately weigh 0g — likely a data entry error, not a valid business case |
| Note: original column names are `product_name_lenght` / `product_description_lenght` (typo in source dataset) | Rename to correct spelling (`_length`) in the silver model | Source typos shouldn't propagate into your warehouse's naming convention — this is exactly the kind of standardization silver is for |

---

## 4. order_items

| Finding | Decision | Rationale |
|---|---|---|
| No nulls, no duplicates, no orphans on `order_id`/`product_id`/`seller_id` | Pass through with type casting only | Clean, referentially sound |
| **383 rows with `freight_value = 0`** | Investigate pattern first (e.g. cross-check `order_status` or seller/pickup type). If confirmed legitimate (free shipping promo), keep as-is; if not, flag | Zero freight is plausible in e-commerce (promotions, self-pickup) but should be verified rather than assumed before it feeds into logistics-cost metrics |

---

## 5. order_payments

| Finding | Decision | Rationale |
|---|---|---|
| `payment_type` includes `'not_defined'` (3 rows) | Treat as a known "unknown" category, not a null — keep visible in `dim_payment_type` or equivalent | Silently dropping or nulling would lose traceability for a genuinely small edge case |
| **9 rows with `payment_value = 0`** and **2 rows with `payment_installments = 0`** | Cross-check against `order_id`: verify whether these are orders paid via a different payment row (e.g. voucher fully covering the order) or canceled orders. Flag if unexplained | `payment_value = 0` combined with `installments = 0` is unusual for a real transaction — needs to be understood before being treated as valid or excluded |
| 0 orphan `order_id` vs. `orders` | No action needed | Referential integrity holds |

---

## 6. order_reviews

| Finding | Decision | Rationale |
|---|---|---|
| **814 duplicate rows on `review_id`** | **Deduplicate** — keep the most recent record per `review_id`, ranked by `review_answer_timestamp` (or `dwh_extracted_at` if timestamp ties) | Duplicates would inflate review counts and skew average review-score metrics in `fact_reviews` |
| `review_comment_title` null 88.3%, `review_comment_message` null 58.7% | Keep as null | These are optional fields at review submission — null is the correct, expected state, not a data quality problem |
| `review_score` always within [1,5], 0 invalid date logic, 0 orphans | No action needed | Clean on all other dimensions |

---

## 7. sellers

| Finding | Decision | Rationale |
|---|---|---|
| No nulls, no duplicates on `seller_id` | Pass through with type casting only | Clean |
| `seller_city` (611 unique) / `seller_state` (23 unique) | Standardize: lowercase + trim `seller_city`; add `accepted_values` test on `seller_state` | Same rationale as `customers` — consistency for joins/rollups, bounded-domain test for state |

---

## 8. geolocation

| Finding | Decision | Rationale |
|---|---|---|
| 261,831 duplicate full rows out of ~1,000,163 total | **Aggregate to one row per `geolocation_zip_code_prefix`** (e.g. average `lat`/`lng`, or take the most frequent city/state per zip) | Multiple lat/lng pairs exist per zip because the raw data captures many individual delivery points — aggregating gives a single usable geography dimension for joins |
| 19,015 unique zip prefixes | This becomes the grain of the silver/gold geography table | Matches the intended use as a `dim_geography` lookup |

---

## Cross-cutting decisions for silver models

1. **Staging models (`stg_<source>_<entity>`)** should stay thin: type casting, renaming, trimming/lowercasing text — no business logic or flagging here.
2. **Silver models** carry the actual cleaning logic from the table above: deduplication, anomaly flags, category standardization.
3. **Anomaly flags over silent drops** — for the date-logic and weight anomalies found above, prefer `dwh_is_*_anomaly` boolean columns over deleting rows. This keeps the pipeline auditable and lets gold-layer models decide whether to exclude flagged rows per use case.
4. **Encode findings as dbt tests**, not just one-off checks: `unique`/`not_null` on primary keys, `relationships` for the referential integrity checks that already passed (protects against regression as data refreshes), and `accepted_values` for the bounded-domain columns identified above (`order_status`, `payment_type`, `customer_state`, `seller_state`, `review_score`).
