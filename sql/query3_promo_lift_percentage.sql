-- Note: this calculates promo lift PER STORE (grouped by Store).
-- Power BI's "Promo Lift Percentage" DAX measure computes the
-- CHAIN-WIDE lift separately — the two are different aggregations
-- of the same underlying concept, not duplicates.

SELECT 
    Store,
    AVG(CASE WHEN Promo = 1 THEN Sales END) AS PromoAvg,
    AVG(CASE WHEN Promo = 0 THEN Sales END) AS NonPromoAvg,
    ((AVG(CASE WHEN Promo = 1 THEN Sales END) - AVG(CASE WHEN Promo = 0 THEN Sales END)) 
      / AVG(CASE WHEN Promo = 0 THEN Sales END)) * 100 AS PromoLiftPercent
FROM train
WHERE Open = 1 AND Sales > 0
GROUP BY Store
ORDER BY Store;