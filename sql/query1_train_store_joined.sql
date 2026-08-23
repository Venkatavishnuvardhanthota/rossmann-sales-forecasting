SELECT t.Store, t.Date, t.Sales, t.Customers, t.Promo, s.StoreType, s.Assortment, s.CompetitionDistance
FROM train t
INNER JOIN store s ON t.Store = s.Store
WHERE t.Open = 1 AND t.Sales > 0;
