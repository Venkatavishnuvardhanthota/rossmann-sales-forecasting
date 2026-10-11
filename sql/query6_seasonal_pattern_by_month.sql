-- Average sales per open store-day by calendar month, pooled across years.
-- YearsObserved shows how many years each month's average rests on (Dec = 2, Jan-Jul = 3),
-- so the pattern is descriptive, not a proven seasonal effect.
SELECT
    MONTH(Date) AS Month,
    MONTHNAME(Date) AS MonthName,
    COUNT(DISTINCT YEAR(Date)) AS YearsObserved,
    SUM(Sales) AS TotalSales,
    ROUND(AVG(Sales), 2) AS AverageSales
FROM train
WHERE Open = 1 AND Sales > 0
GROUP BY MONTH(Date), MONTHNAME(Date)
ORDER BY Month;