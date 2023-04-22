--zad 1 rollup
SELECT CONCAT(os.FirstName,' ', os.LastName) Klient, YEAR(zamh.OrderDate) Rok, SUM(zam.UnitPrice * zam.OrderQty) Koszt
FROM Person.Person os JOIN Sales.Customer kli ON os.BusinessEntityID = kli.PersonID
JOIN Sales.SalesOrderHeader zamh ON zamh.CustomerID = kli.CustomerID
JOIN Sales.SalesOrderDetail zam ON zamh.SalesOrderID = zam.SalesOrderID
GROUP BY ROLLUP(kli.CustomerID, YEAR(zamh.OrderDate)), os.LastName, os.FirstName;

--zad 1 cube
SELECT CONCAT(os.FirstName,' ', os.LastName) Klient, YEAR(zamh.OrderDate) Rok, SUM(zam.UnitPrice * zam.OrderQty) Koszt
FROM Person.Person os JOIN Sales.Customer kli ON os.BusinessEntityID = kli.PersonID
JOIN Sales.SalesOrderHeader zamh ON zamh.CustomerID = kli.CustomerID
JOIN Sales.SalesOrderDetail zam ON zamh.SalesOrderID = zam.SalesOrderID
GROUP BY CUBE(kli.CustomerID, YEAR(zamh.OrderDate)), os.LastName, os.FirstName;
--zad 1 grouping sets
SELECT CONCAT(os.FirstName,' ', os.LastName) Klient, YEAR(zamh.OrderDate) Rok, SUM(zam.UnitPrice * zam.OrderQty) Koszt
FROM Person.Person os JOIN Sales.Customer kli ON os.BusinessEntityID = kli.PersonID
JOIN Sales.SalesOrderHeader zamh ON zamh.CustomerID = kli.CustomerID
JOIN Sales.SalesOrderDetail zam ON zamh.SalesOrderID = zam.SalesOrderID
GROUP BY GROUPING SETS(
(),
(YEAR(zamh.OrderDate)),
(YEAR(zamh.OrderDate), kli.CustomerID), 
(kli.CustomerID))
, os.LastName, os.FirstName;
--zad 1 podpunkt 2
SELECT kat.Name Kategoria, prod.Name Produkt, YEAR(zamh.OrderDate) Rok, SUM(zam.UnitPriceDiscount * zam.OrderQty) Kwota
FROM Sales.SalesOrderHeader zamh JOIN Sales.SalesOrderDetail zam ON zamh.SalesOrderID = zam.SalesOrderID
JOIN Production.Product prod ON zam.ProductID = prod.ProductID
JOIN Production.ProductSubcategory sub ON prod.ProductSubcategoryID = sub.ProductSubcategoryID
JOIN Production.ProductCategory kat ON sub.ProductCategoryID = kat.ProductCategoryID
GROUP BY ROLLUP(kat.Name, prod.Name, YEAR(zamh.OrderDate))
ORDER BY 1,2

--zad 2.1
--bikes
SELECT DISTINCT kat.Name Kategoria,YEAR(zamh.OrderDate) Rok, (SUM(zamh.SubTotal) * 100.0) / SUM(SUM(zamh.SubTotal))
OVER (PARTITION BY kat.Name) Procent
FROM Production.ProductCategory kat JOIN Production.ProductSubcategory sub ON sub.ProductCategoryID = kat.ProductCategoryID
JOIN Production.Product prod ON prod.ProductSubcategoryID = sub.ProductSubcategoryID
JOIN Sales.SalesOrderDetail zam ON prod.ProductID = zam.ProductID
JOIN Sales.SalesOrderHeader zamh ON zamh.SalesOrderID = zam.SalesOrderID
WHERE kat.Name = 'Bikes'
GROUP BY YEAR(zamh.OrderDate), kat.Name
ORDER BY Rok
--components
WHERE kat.Name = 'Components'
--clothing
WHERE kat.Name = 'Clothing'
--accessories
WHERE kat.Name = 'Accessories'

--zad 2.2
SELECT Rok, IDklienta, Tranzakcje
FROM(
	SELECT YEAR(zamh.OrderDate) Rok, zamh.CustomerID IDklienta, COUNT(*) Tranzakcje, ROW_NUMBER()
		OVER(PARTITION BY YEAR(zamh.OrderDate)
		ORDER BY COUNT(*) DESC) Liczba
	FROM Sales.SalesOrderHeader zamh JOIN Sales.SalesOrderDetail zam ON zamh.SalesOrderID = zam.SalesOrderID
	GROUP BY zamh.CustomerID, YEAR(zamh.OrderDate)) helper
WHERE Liczba <= 10
ORDER BY Rok

--zad 2.3
SELECT *, SUM(helper.[W miesiacu]) OVER(PARTITION BY helper.[Imie i nazwisko], helper.Rok ORDER BY helper.[Imie i nazwisko], helper.Rok, helper.Miesiac ASC) 'W roku narastajaco',
	SUM(helper.[W miesiacu]) OVER(PARTITION BY helper.[Imie i nazwisko], helper.Rok ORDER BY helper.Miesiac ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) 'Obecny i poprzedni miesiac'
FROM(
	SELECT DISTINCT CONCAT(os.FirstName,' ',os.LastName) 'Imie i nazwisko', YEAR(zamh.OrderDate) Rok, MONTH(zamh.OrderDate) Miesiac,
	COUNT(*) OVER(PARTITION BY CONCAT(os.FirstName,' ',os.LastName), YEAR(zamh.OrderDate), MONTH(zamh.OrderDate)) 'W miesiacu',
	COUNT(*) OVER(PARTITION BY CONCAT(os.FirstName,' ',os.LastName), YEAR(zamh.OrderDate)) 'W roku'
	FROM Sales.SalesOrderHeader zamh JOIN Sales.SalesPerson sprzed ON zamh.SalesPersonID = sprzed.BusinessEntityID
	JOIN HumanResources.Employee prac ON sprzed.BusinessEntityID = prac.BusinessEntityID
	JOIN Person.Person os ON prac.BusinessEntityID = os.BusinessEntityID ) helper;

--zad 2.4
SELECT DISTINCT helper.Kategoria, SUM(helper.[Koszt produktu]) OVER(PARTITION BY helper.Kategoria) Suma
FROM(
	SELECT DISTINCT kat.Name Kategoria, sub.Name Podkategoria, MAX(prod.StandardCost) 'Koszt produktu'
	FROM Sales.SalesOrderHeader zamh JOIN Sales.SalesOrderDetail zam ON zamh.SalesOrderID = zam.SalesOrderID
	JOIN Production.Product prod ON zam.ProductID = prod.ProductID
	JOIN Production.ProductSubcategory sub ON prod.ProductSubcategoryID = sub.ProductSubcategoryID
	JOIN Production.ProductCategory kat ON sub.ProductCategoryID = kat.ProductCategoryID
	GROUP BY kat.Name, sub.Name) helper;

--zad 2.5 rank
SELECT CONCAT(os.FirstName,' ',os.LastName) Klient, COUNT(zam.ProductID) 'Liczba zakupionych produktow',
	RANK() OVER(PARTITION BY YEAR(kli.CustomerID) ORDER BY COUNT(zam.ProductID) DESC) Pozycja
FROM Sales.Customer kli JOIN Sales.SalesOrderHeader zamh ON kli.CustomerID = zamh.CustomerID
JOIN Sales.SalesOrderDetail zam ON zam.SalesOrderID  = zamh.SalesOrderID
JOIN Person.Person os ON kli.CustomerID = os.BusinessEntityID
GROUP BY os.LastName, os.FirstName, kli.CustomerID

--zad 2.5 dense rank
DENSE_RANK() OVER(PARTITION BY YEAR(kli.CustomerID) ORDER BY COUNT(zam.ProductID) DESC) Pozycja

--zad 2.6
SELECT helper.[ID produktu], helper.[Nazwa produktu], helper.Sprzedaz,
	CASE NTILE(3) OVER (ORDER BY helper.Sprzedaz)
	WHEN 1 THEN 'najlepiej sprzedajacy'
	WHEN 2 THEN 'srednio sprzedajacy'
	WHEN 3 THEN 'najslabiej sprzedajacy' END
FROM(
	SELECT prod.ProductID 'ID produktu', prod.Name 'Nazwa produktu',
		AVG(CAST(zam.OrderQty AS DECIMAL(10,2))) OVER (PARTITION BY prod.ProductID) Sprzedaz
	FROM Sales.SalesOrderDetail zam JOIN Production.Product prod ON prod.ProductID = zam.ProductID)helper
	GROUP BY helper.[ID produktu], helper.[Nazwa produktu], helper.Sprzedaz
