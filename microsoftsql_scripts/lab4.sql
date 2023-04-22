--zad 1
CREATE SCHEMA Hernas;

--zad2
-- Tworzenie tabeli wymiaru klienta
CREATE TABLE Hernas.DIM_CUSTOMER (
    CustomerID INT NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Title NVARCHAR(8) NULL,
    City NVARCHAR(30) NOT NULL,
    TerritoryName NVARCHAR(50) NOT NULL,
    CountryRegionCode NVARCHAR(3) NOT NULL,
    [Group] NVARCHAR(50) NOT NULL
);

-- Tworzenie tabeli wymiaru produktu
CREATE TABLE Hernas.DIM_PRODUCT (
    ProductID INT NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    ListPrice MONEY NOT NULL,
    Color VARCHAR(15) NULL,
    SubCategoryName NVARCHAR(50) NOT NULL,
    CategoryName NVARCHAR(50) NOT NULL,
    Weight DECIMAL(8,2) NULL,
    Size NVARCHAR(5) NULL,
    IsPurchased BIT NOT NULL
);

-- Tworzenie tabeli wymiaru sprzedawcy
CREATE TABLE Hernas.DIM_SALESPERSON (
    SalesPersonID INT NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Title NVARCHAR(8) NULL,
    Gender NVARCHAR(8) NULL,
    CountryRegionCode NVARCHAR(3) NOT NULL,
    [Group] NVARCHAR(50) NOT NULL
);

-- Tworzenie tabeli faktów sprzedaży
CREATE TABLE Hernas.FACT_SALES (
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    SalesPersonID INT NULL,
    OrderDate INT NOT NULL,
    ShipDate INT NULL,
    OrderQty SMALLINT NOT NULL,
    UnitPrice MONEY NOT NULL,
    UnitPriceDiscount MONEY NOT NULL,
    LineTotal MONEY NOT NULL,
);

--zad 3
-- Wypełnienie tabeli DIM_CUSTOMER
INSERT INTO Hernas.DIM_CUSTOMER (CustomerID, FirstName, LastName, Title, City, TerritoryName, CountryRegionCode, [Group])
SELECT sub.CustomerID, sub.FirstName, sub.LastName, sub.Title, sub.City, sub.Name, sub.CountryRegionCode, sub.[Group]
FROM (
    SELECT c.CustomerID, p.FirstName, p.LastName, p.Title, a.City, t.Name, t.CountryRegionCode, t.[Group], 
           ROW_NUMBER() OVER (PARTITION BY c.CustomerID ORDER BY a.City) AS rn
    FROM Sales.Customer c
    JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    JOIN Person.BusinessEntityAddress ba ON ba.BusinessEntityID = p.BusinessEntityID
    JOIN Person.Address a ON a.AddressID = ba.AddressID
    JOIN Sales.SalesTerritory t ON c.TerritoryID = t.TerritoryID
) AS sub
WHERE rn = 1;

-- Wypełnienie tabeli DIM_PRODUCT
INSERT INTO Hernas.DIM_PRODUCT (ProductID, Name, ListPrice, Color, SubCategoryName, CategoryName, Weight, Size, IsPurchased)
SELECT p.ProductID, p.Name, p.ListPrice, p.Color, sc.Name as SubCategoryName, c.Name as CategoryName, p.Weight, p.Size, CAST(0 as bit) as IsPurchased
FROM Production.Product p
LEFT JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c ON sc.ProductCategoryID = c.ProductCategoryID;

-- Wypełnienie tabeli DIM_SALESPERSON
INSERT INTO Hernas.DIM_SALESPERSON (SalesPersonID, FirstName, LastName, Title, Gender, CountryRegionCode, [Group])
SELECT s.BusinessEntityID AS SalesPersonID, p.FirstName, p.LastName, p.Title, 
       CASE WHEN p.Title LIKE 'Mr.' THEN 'M' WHEN p.Title IS NULL THEN NULL ELSE 'F' END AS Gender,
       t.CountryRegionCode, t.[Group]
FROM Sales.SalesPerson s
JOIN Person.Person p ON s.BusinessEntityID = p.BusinessEntityID
JOIN Sales.SalesTerritory t ON s.TerritoryID = t.TerritoryID;



-- Wypełnienie tabeli FACT_SALES
INSERT INTO Hernas.FACT_SALES (ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, OrderQty, UnitPrice, UnitPriceDiscount, LineTotal)
SELECT DISTINCT
    zam.ProductID, 
    kli.CustomerID, 
    sprzed.BusinessEntityID, 
    CONVERT(INT,CONVERT(VARCHAR(10), zamh.OrderDate, 112)), 
    CONVERT(INT,CONVERT(VARCHAR(10), zamh.ShipDate, 112)), 
    zam.OrderQty, 
    zam.UnitPrice, 
    zam.UnitPriceDiscount, 
    zam.LineTotal
FROM 
    Sales.SalesOrderHeader zamh 
    JOIN Sales.SalesOrderDetail zam ON zamh.SalesOrderID = zam.SalesOrderID 
    JOIN Sales.Customer kli ON zamh.CustomerID = kli.CustomerID 
    LEFT JOIN Sales.SalesPerson sprzed ON zamh.SalesPersonID = sprzed.BusinessEntityID;


--zad 4
--DIM_CUSTOMER
ALTER TABLE Hernas.DIM_CUSTOMER 
ADD CONSTRAINT PK_DIM_CUSTOMER PRIMARY KEY (CustomerID);

--DIM_PRODUCT
ALTER TABLE Hernas.DIM_PRODUCT
ADD CONSTRAINT PK_DIM_PRODUCT PRIMARY KEY (ProductID);

--DIM_SALESPERSON
ALTER TABLE Hernas.DIM_SALESPERSON
ADD CONSTRAINT PK_DIM_SALESPERSON PRIMARY KEY (SalesPersonID);

--FACT_SALES
ALTER TABLE Hernas.FACT_SALES
ADD CONSTRAINT FK_FACT_SALES_PRODUCT FOREIGN KEY (ProductID) REFERENCES Hernas.DIM_PRODUCT (ProductID),
ADD CONSTRAINT FK_FACT_SALES_CUSTOMER FOREIGN KEY (CustomerID) REFERENCES Hernas.DIM_CUSTOMER (CustomerID),
ADD CONSTRAINT FK_FACT_SALES_SALESPERSON FOREIGN KEY (SalesPersonID) REFERENCES Hernas.DIM_SALESPERSON (SalesPersonID);

ALTER TABLE Hernas.FACT_SALES
ADD CONSTRAINT FK_FACT_SALES_SALESPERSON FOREIGN KEY (SalesPersonID) REFERENCES Hernas.DIM_SALESPERSON (SalesPersonID);
