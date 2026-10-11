-- Note: this calculates promo lift PER STORE (grouped by Store).
-- Power BI's "Promo Lift Percentage" DAX measure computes the
-- CHAIN-WIDE lift separately - the two are different aggregations
-- of the same underlying concept, not duplicates.
-- Lift = how much higher average sales per open store-day were on promo days than on
-- non-promo days. It is an ASSOCIATION, not a causal estimate: promo days are not randomly
-- assigned. PromoDays / NonPromoDays show how much data each store's estimate rests on.

SELECT
    Store,
    SUM(Promo = 1) AS PromoDays,
    SUM(Promo = 0) AS NonPromoDays,
    ROUND(AVG(CASE WHEN Promo = 1 THEN Sales END), 2) AS PromoAvg,
    ROUND(AVG(CASE WHEN Promo = 0 THEN Sales END), 2) AS NonPromoAvg,
    ROUND(((AVG(CASE WHEN Promo = 1 THEN Sales END) - AVG(CASE WHEN Promo = 0 THEN Sales END))
          / NULLIF(AVG(CASE WHEN Promo = 0 THEN Sales END), 0)) * 100, 2) AS PromoLiftPercent
FROM train
WHERE Open = 1 AND Sales > 0
GROUP BY Store
ORDER BY Store;