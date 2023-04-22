--zad 1 tabela i wstawianie danych do niej
CREATE TABLE Sprzedaz (
   pracID INT,
   prodID INT,
   "Nazwa produktu" VARCHAR(50),
   Rok INT,
   Liczba INT,
   PRIMARY KEY (pracID, prodID, Rok)
);

INSERT INTO Sprzedaz (pracID, prodID, "Nazwa produktu", Rok, Liczba)
SELECT prac.BusinessEntityID AS pracID, 
       prod.ProductID AS prodID,
       prod.Name AS "Nazwa produktu",
       YEAR(zamh.OrderDate) AS Rok,
       SUM(zamd.OrderQty) AS Liczba
FROM Sales.SalesOrderDetail zamd
JOIN Sales.SalesOrderHeader zamh ON zamd.SalesOrderID = zamh.SalesOrderID
JOIN Production.Product prod ON zamd.ProductID = prod.ProductID
JOIN Sales.SalesPerson sprzed ON zamh.SalesPersonID = sprzed.BusinessEntityID
JOIN HumanResources.Employee prac ON sprzed.BusinessEntityID = prac.BusinessEntityID
GROUP BY prac.BusinessEntityID, prod.ProductID, prod.Name, YEAR(zamh.OrderDate)
ORDER BY prac.BusinessEntityID, Rok, Liczba DESC;

SELECT * FROM Sprzedaz;

--zad 1 a
SELECT *
FROM (
  SELECT prac.BusinessEntityID AS pracID, 
         prod.ProductID AS prodID,
         prod.Name AS "Nazwa produktu",
         YEAR(zamh.OrderDate) AS Rok,
         SUM(zamd.OrderQty) AS Liczba
  FROM Sales.SalesOrderDetail zamd
  JOIN Sales.SalesOrderHeader zamh ON zamd.SalesOrderID = zamh.SalesOrderID
  JOIN Production.Product prod ON zamd.ProductID = prod.ProductID
  JOIN Sales.SalesPerson sprzed ON zamh.SalesPersonID = sprzed.BusinessEntityID
  JOIN HumanResources.Employee prac ON sprzed.BusinessEntityID = prac.BusinessEntityID
  GROUP BY prac.BusinessEntityID, prod.ProductID, prod.Name, YEAR(zamh.OrderDate)
) AS SourceTable
PIVOT (
  SUM(Liczba)
  FOR Rok IN ([2011], [2012], [2013], [2014])
) AS PivotTable;

--zad 1 b
SELECT *
FROM (
  SELECT prac.BusinessEntityID AS pracID, 
         prod.Name AS "Nazwa produktu",
		 rn = ROW_NUMBER() OVER (PARTITION BY prac.BusinessEntityID ORDER BY SUM(zamd.OrderQty) DESC)
  FROM Sales.SalesOrderDetail zamd
  JOIN Sales.SalesOrderHeader zamh ON zamd.SalesOrderID = zamh.SalesOrderID
  JOIN Production.Product prod ON zamd.ProductID = prod.ProductID
  JOIN Sales.SalesPerson sprzed ON zamh.SalesPersonID = sprzed.BusinessEntityID
  JOIN HumanResources.Employee prac ON sprzed.BusinessEntityID = prac.BusinessEntityID
  GROUP BY prac.BusinessEntityID, prod.Name
) AS SourceTable
PIVOT (
  MAX([Nazwa produktu])
  FOR rn IN ([1],[2],[3],[4],[5])
) AS PivotTable;

--zad 2 bez pivota
SELECT 
    YEAR(OrderDate) AS 'Year', 
    MONTH(OrderDate) AS 'Month',
    COUNT(DISTINCT CustomerID) AS 'Rozni klienci'
FROM 
    Sales.SalesOrderHeader
GROUP BY 
    YEAR(OrderDate), 
    MONTH(OrderDate)
ORDER BY 
    'Year', 
    'Month';

--zad 2 z pivotem
SELECT 
    *
FROM (
    SELECT 
        YEAR(OrderDate) AS 'Rok', 
        MONTH(OrderDate) AS 'Miesiac',
        COUNT(DISTINCT CustomerID) AS 'Rozni klienci'
    FROM 
        Sales.SalesOrderHeader
    GROUP BY 
        YEAR(OrderDate), 
        MONTH(OrderDate)
) AS SourceTable
PIVOT (
    MAX([Rozni klienci])
    FOR [Miesiac] IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS PivotTable;
--zad 3
SELECT 
    CONCAT(os.FirstName, ' ', os.LastName) AS EmployeeName,
    COUNT(CASE WHEN YEAR(zamh.OrderDate) = 2011 THEN 1 ELSE NULL END) AS '2011',
    COUNT(CASE WHEN YEAR(zamh.OrderDate) = 2012 THEN 1 ELSE NULL END) AS '2012',
    COUNT(CASE WHEN YEAR(zamh.OrderDate) = 2013 THEN 1 ELSE NULL END) AS '2013',
    COUNT(CASE WHEN YEAR(zamh.OrderDate) = 2014 THEN 1 ELSE NULL END) AS '2014'
FROM 
    Sales.SalesPerson sprzed
    JOIN Person.Person os ON sprzed.BusinessEntityID = os.BusinessEntityID
	JOIN HumanResources.Employee prac ON sprzed.BusinessEntityID = prac.BusinessEntityID
    LEFT JOIN Sales.SalesOrderHeader zamh ON sprzed.BusinessEntityID = zamh.SalesPersonID
WHERE 
    YEAR(prac.HireDate) >= 2011
GROUP BY 
    CONCAT(os.FirstName, ' ', os.LastName)

--zad 4
SELECT 
    YEAR(OrderDate) AS 'Rok',
    MONTH(OrderDate) AS 'Miesiac',
    DAY(OrderDate) AS 'Dzien',
    SUM(TotalDue) AS 'Suma',
    COUNT(DISTINCT ProductID) AS 'Liczba roznych produktow'
FROM 
    Sales.SalesOrderDetail
    JOIN Sales.SalesOrderHeader ON SalesOrderDetail.SalesOrderID = SalesOrderHeader.SalesOrderID
GROUP BY 
    YEAR(OrderDate), 
    MONTH(OrderDate), 
    DAY(OrderDate)
ORDER BY 
    YEAR(OrderDate), 
    MONTH(OrderDate), 
    DAY(OrderDate)

--zad 5 miesiace
SELECT 
    CASE 
        WHEN MONTH(OrderDate) = 1 THEN 'Styczeń'
        WHEN MONTH(OrderDate) = 2 THEN 'Luty'
        WHEN MONTH(OrderDate) = 3 THEN 'Marzec'
        WHEN MONTH(OrderDate) = 4 THEN 'Kwiecień'
        WHEN MONTH(OrderDate) = 5 THEN 'Maj'
        WHEN MONTH(OrderDate) = 6 THEN 'Czerwiec'
        WHEN MONTH(OrderDate) = 7 THEN 'Lipiec'
        WHEN MONTH(OrderDate) = 8 THEN 'Sierpień'
        WHEN MONTH(OrderDate) = 9 THEN 'Wrzesień'
        WHEN MONTH(OrderDate) = 10 THEN 'Październik'
        WHEN MONTH(OrderDate) = 11 THEN 'Listopad'
        WHEN MONTH(OrderDate) = 12 THEN 'Grudzień'
    END AS 'Miesiac',
    SUM(TotalDue) AS 'Suma',
    COUNT(DISTINCT ProductID) AS 'Liczba roznych produktow'
FROM 
    Sales.SalesOrderDetail
    JOIN Sales.SalesOrderHeader ON SalesOrderDetail.SalesOrderID = SalesOrderHeader.SalesOrderID
GROUP BY 
    MONTH(OrderDate)
ORDER BY 
    MONTH(OrderDate)

--zad 5 dni tygodnia
SELECT 
    CASE 
        WHEN DATEPART(dw, OrderDate) = 1 THEN 'Poniedziałek' 
        WHEN DATEPART(dw, OrderDate) = 2 THEN 'Wtorek' 
        WHEN DATEPART(dw, OrderDate) = 3 THEN 'Środa' 
        WHEN DATEPART(dw, OrderDate) = 4 THEN 'Czwartek' 
        WHEN DATEPART(dw, OrderDate) = 5 THEN 'Piątek' 
        WHEN DATEPART(dw, OrderDate) = 6 THEN 'Sobota' 
		WHEN DATEPART(dw, OrderDate) = 7 THEN 'Niedziela' 
    END AS 'Dzien tygodnia',
    SUM(TotalDue) AS 'Suma kwot',
    COUNT(DISTINCT ProductID) AS 'Liczba roznych produktow'
FROM 
    Sales.SalesOrderDetail
    JOIN Sales.SalesOrderHeader ON SalesOrderDetail.SalesOrderID = SalesOrderHeader.SalesOrderID
GROUP BY 
    DATEPART(dw, OrderDate)
ORDER BY 
    DATEPART(dw, OrderDate)

--zad 6

SELECT 
    os.FirstName AS 'Imie', 
    os.LastName AS 'Nazwisko', 
    COUNT(DISTINCT zamh.SalesOrderID) AS 'Liczba', 
    SUM(zamh.TotalDue) AS 'Kwota', 
    CASE 
        WHEN COUNT(DISTINCT zamh.SalesOrderID) >= 5 THEN 'srebrna' 
        WHEN COUNT(DISTINCT CASE WHEN zamh.TotalDue > 1.5 * srednie.TotalDue THEN zamh.SalesOrderID END) >= 2 AND 
             SUM(CASE WHEN zamh.TotalDue > 1.5 * srednie.TotalDue THEN zamh.TotalDue ELSE 0 END) > 3 * srednie.TotalDue THEN 'złota' 
        WHEN COUNT(DISTINCT YEAR(zamh.OrderDate)) >= 3 THEN 'platynowa' 
        ELSE 'brak' 
    END AS 'Karta'
FROM 
    sales.Customer klient
    JOIN person.Person os ON klient.PersonID = os.BusinessEntityID
    JOIN sales.SalesOrderHeader zamh ON klient.CustomerID = zamh.CustomerID
    CROSS JOIN (
        SELECT AVG(TotalDue) AS 'TotalDue' 
        FROM sales.SalesOrderHeader
    ) AS srednie
GROUP BY 
    os.FirstName, 
    os.LastName, 
    srednie.TotalDue
HAVING 
    CASE 
        WHEN COUNT(DISTINCT zamh.SalesOrderID) >= 5 THEN 'srebrna' 
        WHEN COUNT(DISTINCT CASE WHEN zamh.TotalDue > 1.5 * srednie.TotalDue THEN zamh.SalesOrderID END) >= 2 AND 
             SUM(CASE WHEN zamh.TotalDue > 1.5 * srednie.TotalDue THEN zamh.TotalDue ELSE 0 END) > 3 * srednie.TotalDue THEN 'złota' 
        WHEN COUNT(DISTINCT YEAR(zamh.OrderDate)) >= 3 THEN 'platynowa' 
        ELSE 'brak' 
    END <> 'brak'
