
SELECT COUNT(ProductID) AS "Ilosc produktow" FROM Production.Product; --zad 1 produkty
SELECT COUNT(ProductCategoryID) AS "Ilosc kategorii" FROM Production.ProductCategory; --zad 1 kategorie
SELECT COUNT(ProductSubcategoryID) AS "Ilosc podkategorii" FROM Production.ProductSubcategory;--zad 1 podkategorie

SELECT * FROM Production.Product WHERE Color IS NULL; -- zad2

--SELECT DISTINCT YEAR(OrderDate) FROM Sales.SalesOrderHeader; --informacyjnie ile jest lat do zadania 3

SELECT YEAR(OrderDate) AS Rok, ROUND(SUM(TotalDue), 2) AS "Kwota tranzakcji (w $)" FROM Sales.SalesOrderHeader GROUP BY YEAR(OrderDate) ORDER BY Rok DESC;  --zad3

--zad 4 ilosc klientow w sklepie adventure works
SELECT COUNT(*) AS "Liczba klientow"
FROM Sales.Customer

--zad 4 ilosc sprzedawcow w sklepie adventure works
SELECT COUNT(*) AS "Liczba sprzedawcow"
FROM Sales.SalesPerson

--zad 4 sprzedawcy i klienci w poszczegolnych regionach
SELECT ter.Name AS Region, COUNT(DISTINCT klient.CustomerID) AS "Liczba klientow", COUNT(DISTINCT sprzed.BusinessEntityID) AS "Liczba sprzedawcow"
FROM Sales.SalesTerritory ter LEFT JOIN Sales.SalesTerritoryHistory terhis ON ter.TerritoryID = terhis.TerritoryID
    LEFT JOIN Sales.SalesPerson sprzed ON terhis.BusinessEntityID = sprzed.BusinessEntityID
    LEFT JOIN Sales.Customer klient ON ter.TerritoryID = klient.TerritoryID
GROUP BY ter.Name
ORDER BY ter.Name;

--zad 5
SELECT YEAR(OrderDate) AS Rok, COUNT(SalesOrderID) FROM Sales.SalesOrderHeader GROUP BY YEAR(OrderDate) ORDER BY Rok DESC;

--zad 6
SELECT prodkat.Name AS Kategoria, prodsub.Name AS Podkategoria, prod.Name AS "Nazwa produktu"
FROM Production.Product prod JOIN Production.ProductSubcategory prodsub ON prod.ProductSubcategoryID = prodsub.ProductSubcategoryID
    JOIN Production.ProductCategory prodkat ON prodsub.ProductCategoryID = prodkat.ProductCategoryID
    LEFT JOIN Sales.SalesOrderDetail zam ON prod.ProductID = zam.ProductID
WHERE zam.SalesOrderDetailID IS NULL
ORDER BY Kategoria, Podkategoria;

--zad 7
SELECT 
    prodsub.Name AS "Nazwa podkategorii", 
    MIN(CASE WHEN zam.UnitPriceDiscount > 0 THEN zam.LineTotal * zam.UnitPriceDiscount ELSE NULL END) AS "Najnizsza kwota znizki", 
    MAX(CASE WHEN zam.UnitPriceDiscount > 0 THEN zam.LineTotal * zam.UnitPriceDiscount ELSE NULL END) AS "Najwyzsza kwota znizki"
FROM Production.Product prod JOIN Production.ProductSubcategory prodsub ON prod.ProductSubcategoryID = prodsub.ProductSubcategoryID
    JOIN Production.ProductCategory prodkat ON prodsub.ProductCategoryID = prodkat.ProductCategoryID
    JOIN Sales.SalesOrderDetail zam ON prod.ProductID = zam.ProductID
GROUP BY prodsub.Name
HAVING MIN(CASE WHEN zam.UnitPriceDiscount > 0 THEN zam.LineTotal * zam.UnitPriceDiscount ELSE NULL END) IS NOT NULL
    AND MAX(CASE WHEN zam.UnitPriceDiscount > 0 THEN zam.LineTotal * zam.UnitPriceDiscount ELSE NULL END) IS NOT NULL;

--zad 8
SELECT prod.Name AS "Nazwa produktu", prod.ListPrice AS "Cena produktu"
FROM Production.Product prod CROSS JOIN (SELECT AVG(ListPrice) AS AvgPrice FROM Production.Product) AS avg
WHERE prod.ListPrice > avg.AvgPrice
GROUP BY prod.Name, prod.ListPrice;

--zad 9
SELECT DATEPART(YEAR, zamh.OrderDate) AS "Rok sprzedazy",DATEPART(MONTH, zamh.OrderDate) AS "Miesiac sprzedazy",prodkat.Name AS Kategoria, AVG(zam.OrderQty) AS "Srednia ilosc sprzedanych produktow"
FROM Sales.SalesOrderHeader zamh JOIN Sales.SalesOrderDetail zam ON zamh.SalesOrderID = zam.SalesOrderID
JOIN Production.Product prod ON zam.ProductID = prod.ProductID
JOIN Production.ProductSubcategory prodsub ON prod.ProductSubcategoryID = prodsub.ProductSubcategoryID
JOIN Production.ProductCategory prodkat ON prodsub.ProductCategoryID = prodkat.ProductCategoryID
GROUP BY DATEPART(YEAR, zamh.OrderDate), DATEPART(MONTH, zamh.OrderDate),prodkat.Name
ORDER BY [Rok sprzedazy], [Miesiac sprzedazy], Kategoria;

--zad 10
SELECT ter.CountryRegionCode, AVG(DATEDIFF(day, zamh.OrderDate, zamh.DueDate)) AS "Srednia ilosc dni do otrzymania zamowienia"
FROM Sales.SalesOrderHeader AS zamh
JOIN Sales.SalesTerritory AS ter ON zamh.TerritoryID = ter.TerritoryID
GROUP BY ter.CountryRegionCode
ORDER BY [Srednia ilosc dni do otrzymania zamowienia];

WITH DaneSprzedazy AS (
SELECT DATEPART(YEAR, zamh.OrderDate) AS "Rok sprzedazy", DATEPART(MONTH, zamh.OrderDate) AS "Miesiac sprzedazy", prodkat.Name AS Kategoria, SUM(zam.OrderQty) AS "Suma ilosc sprzedanych produktow"
FROM Sales.SalesOrderHeader zamh 
JOIN Sales.SalesOrderDetail zam ON zamh.SalesOrderID = zam.SalesOrderID
JOIN Production.Product prod ON zam.ProductID = prod.ProductID
JOIN Production.ProductSubcategory prodsub ON prod.ProductSubcategoryID = prodsub.ProductSubcategoryID
JOIN Production.ProductCategory prodkat ON prodsub.ProductCategoryID = prodkat.ProductCategoryID
GROUP BY DATEPART(YEAR, zamh.OrderDate), DATEPART(MONTH, zamh.OrderDate), prodkat.Name
)

SELECT Kategoria, "Miesiac sprzedazy", AVG(CAST("Suma ilosc sprzedanych produktow" AS FLOAT)) AS "Srednia ilosc sprzedanych produktow"
FROM DaneSprzedazy
GROUP BY Kategoria, "Miesiac sprzedazy"
ORDER BY Kategoria, "Miesiac sprzedazy";

USE SklepLab1;

CREATE TABLE Klienci (
   id_klienta INT PRIMARY KEY,
   imie_nazwisko VARCHAR(50) NOT NULL,
   nr_telefonu VARCHAR(9) NOT NULL CHECK (nr_telefonu LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
   email VARCHAR(50) CHECK (email LIKE '%@%.%')
);

CREATE TABLE Sklepy (
   id_sklepu INT PRIMARY KEY,
   nazwa VARCHAR(50) NOT NULL,
   adres VARCHAR(100) NOT NULL
);

CREATE TABLE Zakupy (
   id_zakupow INT PRIMARY KEY,
   id_klienta INT,
   id_sklepu INT,
   data DATE NOT NULL,
   czas TIME NOT NULL,
   FOREIGN KEY (id_klienta) REFERENCES Klienci(id_klienta),
   FOREIGN KEY (id_sklepu) REFERENCES Sklepy(id_sklepu)
);

CREATE TABLE Produkty (
   id_produktu INT PRIMARY KEY,
   nazwa_produktu VARCHAR(50) NOT NULL,
   cena DECIMAL(10,2) NOT NULL CHECK (cena > 0)
);

CREATE TABLE SzczegolyZakupow (
   id_szczegolu INT PRIMARY KEY,
   id_zakupow INT,
   id_produktu INT,
   ilosc INT NOT NULL CHECK (ilosc > 0),
   FOREIGN KEY (id_zakupow) REFERENCES Zakupy(id_zakupow),
   FOREIGN KEY (id_produktu) REFERENCES Produkty(id_produktu)
);

CREATE TABLE Produkty_W_Sklepie (
   id_sklepu INT,
   produkt INT,
   PRIMARY KEY (id_sklepu, produkt),
   FOREIGN KEY (id_sklepu) REFERENCES Sklepy(id_sklepu),
   FOREIGN KEY (produkt) REFERENCES Produkty(id_produktu)
);

INSERT INTO Klienci (id_klienta, imie_nazwisko, nr_telefonu, email)
VALUES (1, 'Jan Hernas', '444333222', 'jan.hernas@gmail.com'),
       (2, 'Adam Nowak', '987654321', 'adam.nowak@wp.pl');

INSERT INTO Sklepy (id_sklepu, nazwa, adres)
VALUES (1, 'Sklep na rogu', 'ul. Powstancow Slaskich 12, Wroclaw'),
       (2, 'Monopolowy u Zenka', 'ul. Krakowska 21, Krakow');

INSERT INTO Produkty (id_produktu, nazwa_produktu, cena)
VALUES (1, 'Ser gouda 300g', 9.50),
       (2, 'Chleb tostowy', 5.20);

INSERT INTO Zakupy (id_zakupow, id_klienta, id_sklepu, data, czas)
VALUES (1, 1, 1, '2023-03-13', '12:25:50'),
       (2, 2, 2, '2023-03-14', '22:33:22');

INSERT INTO SzczegolyZakupow (id_szczegolu, id_zakupow, id_produktu, ilosc)
VALUES (1, 1, 1, 2),
       (2, 2, 2, 1);

INSERT INTO Produkty_W_Sklepie (id_sklepu, produkt)
VALUES (1, 1),
       (2, 2);

--niepoprawny numer telefonu
INSERT INTO Klienci (id_klienta, imie_nazwisko, nr_telefonu, email)
VALUES (3, 'Jan Kowalski', 'aaabbbccc', 'jan.kowalski@onet.pl');

--ilosc produktow mniejsza od 0
INSERT INTO SzczegolyZakupow (id_szczegolu, id_zakupow, id_produktu, ilosc)
VALUES (3, 1, 1, -10);
--niepoprawny email
INSERT INTO Klienci (id_klienta, imie_nazwisko, nr_telefonu, email)
VALUES (4, 'Abc Xyz', '444333222', 'nie mam');
--wstawienie nulla
INSERT INTO Produkty (id_produktu, nazwa_produktu, cena)
VALUES (5, 'Ketchup', NULL);
--cena mniejsza od 0
INSERT INTO Produkty (id_produktu, nazwa_produktu, cena)
VALUES (5, 'Nic', -1.23);