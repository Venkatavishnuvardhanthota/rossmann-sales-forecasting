# Rossmann Store Sales Forecasting Pipeline

Excel → MySQL → Python (Prophet, XGBoost) → Power BI, built on the Kaggle *Rossmann Store Sales* data: 1,115 drugstores, 1,017,209 store-day rows, 2013-01-01 to 2015-07-31.

**Question:** how much will the chain sell over the next 12 weeks (2015-08-01 to 2015-10-23), and which drivers (promotions, store type, season, weekday) explain the pattern, so staffing and stock can be planned?

## Results at a glance

| | |
|---|---|
| Production model | XGBoost, no Promo feature (no promo schedule exists for future dates), with each store's historical mean sales as a feature |
| Validated error, 84-day chronological holdout | **12.93% store-day MAPE** (MAE 839, RMSE 1,138); **6.72% chain-wide daily MAPE** |
| 12-week forecast, 93,660 store-day rows | **571.2M expected** (677.2M if every store is open) |
| Plausibility check | Same 931 normally-trading stores: 451.0M actual (Aug 1 – Oct 23, 2014) vs 480.2M expected, **+6.5%** |
| Prophet | Kept for its trend/seasonality decomposition, not accuracy (32.89% chain-wide daily MAPE) |

## Pipeline

| Stage | What it does | Files |
|---|---|---|
| Excel | Initial profiling and validation of `train.csv` / `store.csv`; used to cross-check later figures (average sales per open store-day: 6,955.51 in Excel vs 6,955.96 in Power BI; the gap is 54 open rows with zero sales that Excel includes and the cleaned data drops) | `excel/` |
| MySQL | Schema (composite PK on `train(Store, Date)`, FK to `store`), loading, six analytical queries and one dataset export | `sql/` |
| Python | Notebook 1: cleaning and EDA. Notebook 2: Prophet, XGBoost, ensemble test, production forecast | `notebooks/` |
| Power BI | Four-page dashboard | `dashboard/RossmannSalesDashboard.pbix` |

## Reproducing it

**Requirements:** MySQL 8.0+ (window functions and CTEs), Python with `pip install -r requirements.txt`, Power BI Desktop for the dashboard.

**Data:** the raw Kaggle files are not in this repo. Download `train.csv` and `store.csv` from the [Rossmann Store Sales competition](https://www.kaggle.com/c/rossmann-store-sales/data) into `data/raw/`.

### MySQL setup

1. **Enable `LOAD DATA LOCAL INFILE`.** It must be on at both ends, otherwise MySQL returns error 3948.
   - Server: `SET GLOBAL local_infile = 1;`
   - Client (Workbench): edit the connection, Advanced → Others, add `OPT_LOCAL_INFILE=1`.
2. **Edit the two file paths** in `sql/02_load_data.sql`. `LOAD DATA` needs a literal path, so they are hardcoded to `D:/projects/Rossmann Store Sales/data/raw/`.
3. **Run `01_create_tables.sql`, then `02_load_data.sql`.**
4. **Check the load:**

   | Check | Expected |
   |---|---|
   | rows in `store` | 1115 |
   | rows in `train` | 1017209 |
   | stores with `CompetitionDistance IS NULL` | 3 |
   | stores with `CompetitionDistance = 0` | 0 |

   Blank numeric fields in `store.csv` are converted to NULL with `NULLIF`; without it MySQL loads them as 0, which would fabricate a competitor at distance 0.
5. **Reloading:** `TRUNCATE` fails because of the foreign key, and a second load fails on the primary key. Clear the tables with
   `DELETE FROM train WHERE Store > 0;` then `DELETE FROM store WHERE Store > 0;`
   If safe-update mode blocks it (error 1175), run `SET SQL_SAFE_UPDATES = 0;` first.

### Run order

1. SQL setup above, then `query1` … `query7` (each saves a CSV to `data/processed/`). `query7` exports the full merged dataset, `train_store_merged.csv`, which is the input to Notebook 1.
2. `notebooks/01_eda_and_cleaning.ipynb` → writes `rossmann_cleaned.csv` and charts to `outputs/charts/`.
3. `notebooks/02_forecasting_models.ipynb` → writes the forecast and validation CSVs and the models in `model/`.
4. Open the `.pbix` and refresh from `data/processed/`.

## SQL queries

| File | Purpose |
|---|---|
| `query1_train_store_joined.sql` | Open, positive-sales days joined to store attributes (844,338 rows) |
| `query2_total_and_avg_monthly_sales.sql` | Total and average sales per open store-day, by StoreType and calendar month (48 rows) |
| `query3_promo_lift_percentage.sql` | Per-store promo vs non-promo average, with the number of days behind each |
| `query4_top_and_bottom_stores_by_revenue.sql` | Top and bottom 10 stores by revenue (`RANK()`; no ties here, 20 rows) |
| `query5_month_over_month_growth.sql` | Monthly revenue with `LAG()` growth |
| `query6_seasonal_pattern_by_month.sql` | Average sales by calendar month, with the number of years observed |
| `query7_export_full_merged_dataset.sql` | Unfiltered export for Python (not an analytical query) |

## What the data shows

- **December is the strongest month** (8,609 average sales per open store-day vs 7,189 in November and 6,564 in January), but only two Decembers are observed.
- **StoreType B is structurally different:** highest sales per open day, only 17 stores, the only type carrying Assortment B, and open on about 98% of days vs about 83% for the others.
- **Promo days are higher in 1,114 of 1,115 stores**, ranging from −6.95% (Store 274) to +144.93% (Store 198); about 38.8% higher chain-wide. This is an association: promo days are not randomly assigned, and each store's estimate rests on a different number of days.
- **Saturday is the weakest day** among open stores; Sunday sales look strong per open store but few stores open (chain-wide Sunday sales collapse).
- **No "recurring March/July uptick":** an earlier reading of month-over-month totals did not survive per-day averages (March 2014 +7.9%, July 2014 −8.5%).
- Competitor distance does not guarantee higher sales; the pattern is more consistent with dense, high-traffic locations having both more competitors and more customers.

## Modelling

**Setup.** Chronological split: train through 2015-05-08, validate on the last 84 days (2015-05-09 to 2015-07-31), matching the 12-week horizon. No shuffling. `Customers` is excluded (it is only known after the fact).

| Model | Grain | MAPE | MAE | RMSE |
|---|---|---|---|---|
| Prophet, baseline | chain-wide daily | 63.76% | 857,491 | 1,418,151 |
| Prophet, holiday-aware (final Prophet) | chain-wide daily | 32.89% | 607,088 | 920,710 |
| Prophet, tuned (not selected) | chain-wide daily | 22.48% | 662,991 | 968,381 |
| XGBoost with Promo | chain-wide daily | 6.72% | 455,598 | 612,485 |
| XGBoost no Promo (production config) | chain-wide daily | 6.72% | 409,790 | 617,347 |
| XGBoost, default | store-day | 21.00% | 1,347 | 1,868 |
| XGBoost, manual tuning | store-day | 17.92% | 1,094 | 1,521 |
| XGBoost with Promo, tuned + StoreMeanSales | store-day | 12.64% | 808 | 1,097 |
| XGBoost no Promo, production config | store-day | 12.93% | 839 | 1,138 |

Only rows with the same grain are comparable. Aggregating store predictions to chain-wide totals cancels store-level errors, so store-day MAPE is always higher.

**Decisions and what they were based on**
- **Prophet's 63.76% baseline** came from two near-total shutdown days (2015-05-14 and 2015-05-25, about 99% of stores closed). Adding Germany's holiday calendar cut it to 32.89%.
- **The tuned Prophet has a lower MAPE but worse MAE and RMSE.** MAPE is distorted by near-zero Sundays, so the holiday-aware model was kept. The tuned model changed three things at once, so its gain cannot be attributed to any one of them.
- **`StoreMeanSales`** (each store's mean sales over the training window only) took store-day MAPE from 17.92% to 12.64% by letting the model tell apart stores with identical attributes. Hyperparameters were chosen with a randomized search over date-grouped expanding-window folds.
- **An `IsHoliday` feature made XGBoost slightly worse** (21.00% → 21.98%) and was dropped.
- **Ensembling does not help.** Blend weights swept from 0% to 100% XGBoost: every weight given to Prophet increased chain-wide error (50/50: 17.99%, 80/20: 10.20%, XGBoost alone: 6.72%).

**Production forecast**
- Refit on all history without Promo, because no promo schedule exists for future dates. Its error is estimated separately on the same holdout (12.93% / 6.72%).
- The model learns from open, positive-sales days only, so `PredictedSales` means "sales if the store is open". `ExpectedSales = PredictedSales × OpenRate`, where OpenRate is each store's historical open share for that weekday.
- A weekday-encoding bug (pandas 0–6 vs the training data's 1–7) once produced identical predictions on adjacent days; it is fixed and asserted in Notebook 2, Cell 34.

## Power BI dashboard

Four pages at 1920×1080, on a star schema (`Dim_Date` related to three fact tables: `train_store_merged`, `xgboost_validation_predictions`, `xgboost_future_forecast`). The fact table holds the cleaned 844,338 rows.

1. **Executive Overview:** revenue, customers, stores, average sales per open store-day, monthly trend by year, StoreType comparison; slicers for year, StoreType and promo.
2. **Store Performance:** top and bottom stores, a store table, and a competitor-distance vs sales scatter.
3. **Promotions & Seasonality:** promo lift (38.8%), promo vs non-promo by StoreType, average sales by month and weekday.
4. **12-Week Forecast:** expected forecast revenue, validation MAPE / MAE / RMSE, actual vs predicted for the holdout window, and the forecast line.

Measures include YTD, MoM and YoY (with blank guards), Top 10 average revenue, promo lift and the validation metrics.

## Limitations

- **Point forecasts only.** XGBoost gives no prediction intervals; Prophet provides intervals but is not the production model.
- **Public-holiday and long store closures are not modelled** in the forecast. `OpenRate` is a weekday-level historical average, which is a heuristic, not a forecast of closures.
- **No future promo information**, so the production model cannot use Promo; it is slightly less accurate than the with-Promo model (12.93% vs 12.64%).
- **The 84-day holdout was also used to choose between variants** (holiday flag, capacity, blend weights), so the reported error is mildly optimistic. The cross-validation scores are also slightly optimistic because `StoreMeanSales` uses all training rows.
- **The year-over-year check is a plausibility check, not a validation.**
- **Seasonality evidence is limited:** about 2.6 years of data, so December appears only twice.

## Repository layout

```
data/raw/            Kaggle files (not tracked)
data/processed/      query outputs, cleaned data, forecast and validation CSVs
excel/               profiling workbook
sql/                 schema, load script, queries 1-7
notebooks/           01_eda_and_cleaning, 02_forecasting_models
model/               XGBoost models, Prophet model (JSON), store_mean_sales.csv
dashboard/           Power BI file
outputs/charts/      chart images from the notebooks
```
Pickled XGBoost models load reliably only with the library versions pinned in `requirements.txt`.

## License
MIT. Data © Rossmann via Kaggle, used under the competition's terms.

# Contact

**Thota Venkata Vishnu Vardhan**

📧 Email: [venkatavishnuvardhanthota@gmail.com](mailto:venkatavishnuvardhanthota@gmail.com)

💻 GitHub: https://github.com/Venkatavishnuvardhanthota

🔗 LinkedIn: https://www.linkedin.com/in/venkata-vishnu-vardhan-thota/