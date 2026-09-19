-- Uses RANK(), which can return more than 10 rows if a tie occurs at
-- the boundary. Verified tie-free on this dataset (exactly 20 rows
-- returned). Use ROW_NUMBER() instead if a guaranteed-exact-10 result
-- is required regardless of ties.

WITH store_revenue AS (
    SELECT 
        Store,
        SUM(Sales) AS TotalRevenue,
        RANK() OVER (ORDER BY SUM(Sales) DESC) AS TopRank,
        RANK() OVER (ORDER BY SUM(Sales) ASC) AS BottomRank
    FROM train
    WHERE Open = 1 AND Sales > 0
    GROUP BY Store
)
SELECT Store, TotalRevenue, TopRank, BottomRank
FROM store_revenue
WHERE TopRank <= 10 OR BottomRank <= 10
ORDER BY TopRank;