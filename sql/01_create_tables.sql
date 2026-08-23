CREATE TABLE store(
    Store INT PRIMARY KEY,
    StoreType CHAR(1),
    Assortment CHAR(1),
    CompetitionDistance INT,
    CompetitionOpenSinceMonth INT,
    CompetitionOpenSinceYear INT,
    Promo2 BOOL,
    Promo2SinceWeek INT,
    Promo2SinceYear INT,
    PromoInterval VARCHAR(30)
);

CREATE TABLE train(
    Store INT,
    DayOfWeek INT,
    Date DATE,
    Sales INT,
    Customers INT,
    Open BOOL,
    Promo BOOL,
    StateHoliday CHAR(1),
    SchoolHoliday INT,
    PRIMARY KEY (Store, Date),
    FOREIGN KEY (Store) REFERENCES store(Store)
);