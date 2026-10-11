-- Load the Rossmann raw CSVs into MySQL (run after 01_create_tables.sql).

LOAD DATA LOCAL INFILE 'D:/projects/Rossmann Store Sales/data/raw/store.csv'
INTO TABLE store
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Store, StoreType, Assortment, @CD, @CSMonth, @CSYear, Promo2, @P2Week, @P2Year, @PInterval)
SET
  CompetitionDistance       = NULLIF(@CD, ''),
  CompetitionOpenSinceMonth = NULLIF(@CSMonth, ''),
  CompetitionOpenSinceYear  = NULLIF(@CSYear, ''),
  Promo2SinceWeek           = NULLIF(@P2Week, ''),
  Promo2SinceYear           = NULLIF(@P2Year, ''),
  PromoInterval             = NULLIF(@PInterval, '');

LOAD DATA LOCAL INFILE 'D:/projects/Rossmann Store Sales/data/raw/train.csv'
INTO TABLE train
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Store, DayOfWeek, Date, Sales, Customers, Open, Promo, StateHoliday, SchoolHoliday);
