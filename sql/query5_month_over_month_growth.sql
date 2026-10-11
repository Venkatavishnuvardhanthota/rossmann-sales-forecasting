-- Observed month-over-month change in TOTAL monthly sales. Totals also reflect the number of
-- days and open stores in each month, so this is descriptive and NOT a test of seasonality
-- (see Query 6 for per-open-store-day averages by calendar month).

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m') AS SalesMonth,
        SUM(Sales) AS Revenue
    FROM train
    WHERE Open = 1
      AND Sales > 0
    GROUP BY DATE_FORMAT(Date, '%Y-%m')
),
revenue_with_growth AS (
    SELECT
        SalesMonth,
        Revenue,
        LAG(Revenue) OVER (ORDER BY SalesMonth) AS PrevMonthRevenue
    FROM monthly_revenue
)
SELECT
    SalesMonth,
    Revenue,
    PrevMonthRevenue,
    ((Revenue - PrevMonthRevenue) / PrevMonthRevenue) * 100 AS MoMGrowthPercent
FROM revenue_with_growth
ORDER BY SalesMonth;