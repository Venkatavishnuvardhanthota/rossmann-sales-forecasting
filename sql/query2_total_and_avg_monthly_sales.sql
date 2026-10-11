-- Total and average sales by StoreType for each calendar month (month-of-year, pooled across
-- years), ordered Jan..Dec. Dec has 2 years of data, Jan-Jul have 3, so compare AVERAGES
-- across months, not totals. Chain-wide version: Query 6.
WITH monthly_sales AS (
    SELECT
        s.StoreType,
        MONTH(t.Date)     AS MonthNum,
        MONTHNAME(t.Date) AS SalesMonth,
        t.Sales
    FROM train t
    INNER JOIN store s
        ON t.Store = s.Store
    WHERE t.Open = 1 AND t.Sales > 0
)
SELECT
    StoreType,
    MonthNum,
    SalesMonth,
    SUM(Sales) AS TotalSales,
    ROUND(AVG(Sales), 2) AS AvgSalesPerOpenStoreDay
FROM monthly_sales
GROUP BY StoreType, MonthNum, SalesMonth
ORDER BY StoreType, MonthNum;