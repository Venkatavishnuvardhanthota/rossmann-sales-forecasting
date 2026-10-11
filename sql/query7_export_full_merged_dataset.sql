-- DATASET EXPORT (not an analytical query): saved as data/processed/train_store_merged.csv, the input to Notebook 1.
-- Full, unfiltered train-store join for Python EDA/modeling.
-- Unlike Query 1 (filtered to Open=1, Sales>0, limited columns for a specific business question), this exports every row and every relevant column so Python can make its own filtering decisions (see Notebook 1, Cell 5).

SELECT t.*, s.StoreType, s.Assortment, s.CompetitionDistance, 
       s.CompetitionOpenSinceMonth, s.CompetitionOpenSinceYear,
       s.Promo2, s.Promo2SinceWeek, s.Promo2SinceYear, s.PromoInterval
FROM train t
INNER JOIN store s ON t.Store = s.Store;