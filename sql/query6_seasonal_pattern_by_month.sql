SELECT 
    MONTH(Date) AS Month,
    MONTHNAME(Date) AS MonthName,
    SUM(Sales) AS TotalSales,
    AVG(Sales) AS AverageSales
FROM train
WHERE Open = 1 AND Sales > 0
GROUP BY MONTH(Date), MONTHNAME(Date)
ORDER BY Month;