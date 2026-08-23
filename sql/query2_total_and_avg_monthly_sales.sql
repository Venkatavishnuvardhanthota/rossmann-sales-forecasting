WITH  monthly_sales AS (
	SELECT 
		s.StoreType,	
        DATE_FORMAT(Date, '%Y-%M') AS SalesMonth,
        t.Sales
	FROM train t
    INNER JOIN store s
    ON t.store = s.store
    WHERE t.Open = 1 AND t.Sales > 0
)
SELECT 
    StoreType,
    SalesMonth,
    SUM(Sales) AS TotalSales,
    AVG(Sales) AS AvgSales
FROM monthly_sales
GROUP BY StoreType, SalesMonth
ORDER BY StoreType, SalesMonth;    
		   