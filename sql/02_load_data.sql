-- Load store.csv, converting blank text fields to true NULLs
LOAD DATA LOCAL INFILE 'D:/projects/Rossmann Store Sales/data/raw/store.csv'
INTO TABLE store
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Store, StoreType, Assortment, CompetitionDistance, @CSMonth, @CSYear, Promo2, @P2Week, @P2Year, @PInterval)
SET
  CompetitionOpenSinceMonth = NULLIF(@CSMonth, ''),
  CompetitionOpenSinceYear  = NULLIF(@CSYear, ''),
  Promo2SinceWeek = NULLIF(@P2Week, ''),
  Promo2SinceYear = NULLIF(@P2Year, ''),
  PromoInterval = NULLIF(@PInterval, '');

-- Fix: CompetitionDistance blanks loaded as fabricated 0 instead of NULL
UPDATE store SET CompetitionDistance = NULL WHERE CompetitionDistance = 0;

-- Load train.csv — dates are already in MySQL's native YYYY-MM-DD format, no conversion needed
LOAD DATA LOCAL INFILE 'D:/projects/Rossmann Store Sales/data/raw/train.csv'
INTO TABLE train
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Store, DayOfWeek, Date, Sales, Customers, Open, Promo, StateHoliday, SchoolHoliday);