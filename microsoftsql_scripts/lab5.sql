CREATE TABLE Hernas.DIM_MONTH (
    MonthID INT PRIMARY KEY,
    MonthName VARCHAR(20) NOT NULL
);

INSERT INTO Hernas.DIM_MONTH (MonthID, MonthName)
VALUES
    (1, 'January'),
    (2, 'February'),
    (3, 'March'),
    (4, 'April'),
    (5, 'May'),
    (6, 'June'),
    (7, 'July'),
    (8, 'August'),
    (9, 'September'),
    (10, 'October'),
    (11, 'November'),
    (12, 'December');

CREATE TABLE Hernas.DIM_DAY_OF_WEEK (
    DayOfWeekID INT,
    DayOfWeekName NVARCHAR(20) PRIMARY KEY
);

INSERT INTO Hernas.DIM_DAY_OF_WEEK (DayOfWeekID, DayOfWeekName)
VALUES
    (1, 'Monday'),
    (2, 'Tuesday'),
    (3, 'Wednesday'),
    (4, 'Thursday'),
    (5, 'Friday'),
    (6, 'Saturday'),
    (7, 'Sunday');

CREATE TABLE Hernas.DIM_TIME (
    PK_time INT PRIMARY KEY,
    Year INT,
    Quarter INT,
    Month INT,
    MonthName NVARCHAR(20),
    DayOfWeekName NVARCHAR(20),
    DayOfMonth INT
);

INSERT INTO Hernas.DIM_TIME (PK_time, Year, Quarter, Month, MonthName, DayOfWeekName, DayOfMonth)
SELECT DISTINCT
    CONVERT(INT,CONVERT(VARCHAR(8), OrderDate, 112)), 
    DATEPART(YEAR, OrderDate), 
    DATEPART(QUARTER, OrderDate), 
    DATEPART(MONTH, OrderDate), 
    mn.MonthName, 
    dn.DayOfWeekName, 
    DATEPART(DAY, OrderDate)
FROM 
    Sales.SalesOrderHeader
    JOIN Hernas.DIM_MONTH mn ON DATEPART(MONTH, OrderDate) = mn.MonthID
    JOIN Hernas.DIM_DAY_OF_WEEK dn ON DATEPART(WEEKDAY, OrderDate) = dn.DayOfWeekID;

ALTER TABLE Hernas.FACT_SALES
ADD CONSTRAINT FK_FACT_SALES_TIME FOREIGN KEY (OrderDate) REFERENCES Hernas.DIM_TIME (PK_TIME);

ALTER TABLE Hernas.FACT_SALES
ADD CONSTRAINT FK_FACT_SALES_SHIPTIME FOREIGN KEY (ShipDate) REFERENCES Hernas.DIM_TIME (PK_TIME);

ALTER TABLE Hernas.DIM_TIME
ADD CONSTRAINT FK_DIM_TIME_MONTH FOREIGN KEY (Month) REFERENCES Hernas.DIM_MONTH (MonthID);

ALTER TABLE Hernas.DIM_TIME
ADD CONSTRAINT FK_DIM_TIME_DAY_OF_WEEK FOREIGN KEY (DayOfWeekName) REFERENCES Hernas.DIM_DAY_OF_WEEK (DayOfWeekName);
