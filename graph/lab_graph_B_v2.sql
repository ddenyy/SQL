use NorthWind


select *
from Categories

CREATE TABLE CategoriesG (
    CategoryID INT PRIMARY KEY,
    CategotyName NVARCHAR(15) NOT NULL,
) AS NODE;

CREATE TABLE ProductsG (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(40) NOT NULL,
	UnitPrice money not null
) AS NODE;

CREATE TABLE SuppliersG (
    SupplierID INT PRIMARY KEY,
    CompanyName NVARCHAR(40) NOT NULL,
	ContactName NVARCHAR(30) null
) AS NODE;

CREATE TABLE EmployeesG (
    EmployeeID INT PRIMARY KEY,
    LastName NVARCHAR(20) NOT NULL,
	FirstName NVARCHAR(10) not null
) AS NODE;

CREATE TABLE OrdersG (
    OrderID INT PRIMARY KEY,
) AS NODE;


CREATE TABLE CityG (
    City nvarchar(15) null,
	Region nvarchar(15) null,
	PostalCode nvarchar(10) null,
	Country nvarchar(15) null
) AS NODE;

CREATE TABLE CustomersG (
    CustomerID NVARCHAR(5) PRIMARY KEY,
	CompanyName NVARCHAR(40) NOT NULL,
	ContactName NVARCHAR(30) null,
    Phone NVARCHAR(24) NULL,
	Fax NVARCHAR(24) null
) AS NODE;


CREATE TABLE Relate  AS EDGE

CREATE TABLE Produces  AS EDGE

CREATE TABLE Placed  AS EDGE

CREATE TABLE Collects  AS EDGE

CREATE TABLE LIVES_emp  AS EDGE


CREATE TABLE Makes
(
	OrderDate datetime null,
	RequiredDate datetime null
) AS EDGE

CREATE TABLE LIVES  AS EDGE

CREATE TABLE Shipped(ShippedDate datetime null)  AS EDGE


CREATE TABLE [Contains](Quantity smallint null)  AS EDGE


INSERT INTO CategoriesG(CategoryID,CategotyName)
SELECT CategoryID,CategoryName
FROM Categories

INSERT INTO ProductsG(ProductID,ProductName,UnitPrice)
SELECT ProductID,ProductName,UnitPrice
FROM Products

INSERT INTO EmployeesG(EmployeeID,LastName,FirstName)
SELECT EmployeeID,LastName,FirstName
FROM Employees

INSERT INTO SuppliersG(SupplierID,CompanyName,ContactName)
SELECT SupplierID,CompanyName,ContactName
FROM Suppliers

INSERT INTO OrdersG(OrderID)
SELECT OrderID
FROM Orders

INSERT INTO CustomersG(CustomerID,CompanyName,ContactName,Phone,Fax)
SELECT CustomerID,CompanyName,ContactName,Phone,Fax
FROM Customers

INSERT INTO CityG(City,Region,PostalCode,Country)
(
SELECT Distinct City,Region,PostalCode,Country
FROM Employees
UNION
SELECT Distinct City,Region,PostalCode,Country
FROM Customers
Union 
SELECT Distinct City,Region,PostalCode,Country
FROM [Suppliers]
Union 
SELECT Distinct ShipCity,ShipRegion,ShipPostalCode,ShipCountry
FROM Orders)

INSERT INTO Relate($from_id, $to_id)
SELECT 
(SELECT $node_id FROM ProductsG WHERE  pr.ProductID = ProductsG.ProductID),
(SELECT $node_id FROM CategoriesG WHERE  CategoriesG.CategoryID = cat.CategoryID)
FROM Products as pr join Categories as cat on cat.CategoryID = pr.CategoryID

INSERT INTO Produces($from_id, $to_id)
SELECT 
(SELECT $node_id FROM SuppliersG WHERE  SuppliersG.SupplierID = sup.SupplierID),
(SELECT $node_id FROM ProductsG WHERE  pr.ProductID = ProductsG.ProductID)
FROM Suppliers as sup join Products as pr on pr.SupplierID = sup.SupplierID

INSERT INTO LIVES_emp($from_id, $to_id)
SELECT
(SELECT $node_id FROM EmployeesG WHERE  EmployeesG.EmployeeID = emp.EmployeeID),
(SELECT $node_id FROM CityG WHERE  CityG.City = emp.City 
and CityG.Country = emp.Country
and CityG.PostalCode = emp.PostalCode)
FROM Employees as emp


INSERT INTO Placed($from_id, $to_id)
SELECT
(SELECT $node_id FROM SuppliersG WHERE  SuppliersG.SupplierID = emp.SupplierID),
(SELECT $node_id FROM CityG WHERE  CityG.City = emp.City 
and CityG.Country = emp.Country
and CityG.PostalCode = emp.PostalCode)
FROM Suppliers as emp

INSERT INTO LIVES($from_id, $to_id)
SELECT
(SELECT $node_id FROM CustomersG WHERE  CustomersG.CustomerID = emp.CustomerID),
(SELECT $node_id FROM CityG WHERE  CityG.City = emp.City 
and CityG.Country = emp.Country
and (ISNULL(CityG.PostalCode,1) = ISNULL(emp.PostalCode,1)) )
FROM Customers as emp

INSERT INTO Collects($from_id, $to_id)
SELECT
(SELECT $node_id FROM EmployeesG WHERE  EmployeesG.EmployeeID = ord.EmployeeID),
(SELECT $node_id FROM OrdersG WHERE  OrdersG.OrderID = ord.OrderID)
FROM Orders as ord

INSERT INTO [Contains](Quantity,$from_id, $to_id)
SELECT ord.Quantity,
(SELECT $node_id FROM OrdersG WHERE  OrdersG.OrderID = ord.OrderID),
(SELECT $node_id FROM ProductsG WHERE  ProductsG.ProductID = ord.ProductID)
FROM [Order Details] as ord

INSERT INTO Shipped(ShippedDate,$from_id, $to_id)
SELECT rd.ShippedDate,
(SELECT $node_id FROM OrdersG WHERE  OrdersG.OrderID = rd.OrderID),
(SELECT $node_id FROM CityG WHERE  CityG.City = rd.ShipCity 
and CityG.Country = rd.ShipCountry
and (ISNULL(CityG.PostalCode,1) = ISNULL(rd.ShipPostalCode,1)) )
FROM  Orders as rd 

INSERT INTO Makes(OrderDate,RequiredDate,$from_id, $to_id)
SELECT ord.OrderDate,ord.RequiredDate,
(SELECT $node_id FROM CustomersG WHERE  CustomersG.CustomerID = cut.CustomerID),
(SELECT $node_id FROM OrdersG WHERE  OrdersG.OrderID = ord.OrderID)
FROM Customers as cut join Orders as ord on ord.CustomerID = cut.CustomerID





--1 Как называется самый дорогой товар из товарной категории №1?

--R
SELECT TOP 1 WITH TIES ProductName
FROM Products join Categories on Categories.CategoryID = Products.CategoryID
WHERE Categories.CategoryID = 1
ORDER BY Products.UnitPrice DESC

--G
SELECT TOP 1 WITH TIES ProductName
FROM ProductsG as A,CategoriesG as B,Relate as V
WHERE match(A-(V)->B) and B.[CategoryID] = 1
ORDER BY A.UnitPrice DESC

--2 В какие города заказы комплектовались более десяти дней?

--R
SELECT Orders.OrderID
FROM Orders
WHERE DATEDIFF(DAY,Orders.OrderDate,Orders.ShippedDate) > 10

--G
SELECT A.OrderID
FROM CustomersG as O,Makes as V1,OrdersG as A,CityG as B,Shipped as V2
WHERE Match(O-(V1)->A-(V2)->B) and DATEDIFF(DAY,V1.OrderDate,V2.ShippedDate) > 10

--3 Какие покупатели до сих пор ждут отгрузки своих заказов?

--R
SELECT Orders.CustomerID
FROM Orders 
WHERE Orders.RequiredDate > '1998-05-29 00:00:00.000'
Order by Orders.CustomerID
--G

SELECT A.CustomerID
FROM CustomersG as A,Makes as V,OrdersG as B
WHERE Match(A-(V)->B) and V.RequiredDate > '1998-05-29 00:00:00.000'
Order by A.CustomerID

--4. Скольких покупателей обслужил продавец, лидирующий по общему количеству заказов?

--R
SELECT TOP 1 WITH TIES emp.EmployeeID,COUNT(DISTINCT ord.CustomerID)
FROM Employees as emp join Orders as ord on ord.EmployeeID = emp.EmployeeID
GROUP BY emp.EmployeeID
ORDER BY count(*) DESC

--G
SELECT TOP 1 WITH TIES A.EmployeeID,COUNT(DISTINCT C.CustomerID)
FROM EmployeesG as A,Collects as V1,OrdersG as B,Makes as V2,CustomersG as C
WHERE Match(A-(V1)->B<-(V2)-C)
GROUP BY A.EmployeeID
ORDER BY count(*) DESC

-- 5 Сколько французских городов обслужил продавец №1 в 1997-м?

-- Очистка всех данных из всех таблиц
EXEC sp_MSforeachtable 'TRUNCATE TABLE ?';
--R
SELECT count(*)
FROM Employees as emp join Orders as ord on emp.EmployeeID = ord.EmployeeID
WHERE emp.EmployeeID = 1 and ord.ShipCountry = 'France' and YEAR(ord.OrderDate) = 1997;
-- Удалить базу данных
DROP DATABASE [nordwind2];
--G

SELECT *
FROM EmployeesG as A,Collects as V1,OrdersG as B,Shipped as V2,CityG as C,CustomersG as D,Makes as V3
WHERE Match(A-(V1)->B-(V2)->C) and match(D-(V3)->B) and A.EmployeeID = 1 and C.Country = 'France' and YEAR(V3.OrderDate) = 1997

--6 В каких странах есть города, в которые было отправлено больше двух заказов?

--R
SELECT Distinct Orders.ShipCountry
FROM Orders
GROUP BY Orders.ShipCity,Orders.ShipCountry
HAVING count(*) > 2

--G

SELECT Distinct C.Country
From OrdersG as B,Shipped as V2,CityG as C
WHERE Match(B-(V2)->C)
GROUP BY C.City,C.Country
HAVING count(*) > 2


--7 Перечислите названия товаров, которые были проданы в количестве менее 1000 штук (quantity)?

--R
SELECT pr.ProductName
FROM [Order Details] as ordd join Products as pr on pr.ProductID = ordd.ProductID
group by ordd.ProductID,pr.ProductName
having sum(ordd.Quantity) > 1000

--G
SELECT B.ProductName
FROM OrdersG as A,[Contains] as V,ProductsG as B
WHERE match(A-(V)->B)
group by B.ProductID,B.ProductName
having sum(V.Quantity) > 1000


--8. Как зовут покупателей, которые делали заказы с доставкой в другой город (не в тот, в котором они прописаны)?

--R
SELECT Distinct cut.ContactName
FROM Orders join Customers as cut on Orders.CustomerID = cut.CustomerID
WHERE Orders.ShipCity <> cut.City

--G
SELECT Distinct A.ContactName
FROM CustomersG as A,LIVES as V1 ,OrdersG as B,Shipped	V2,CityG as C1,CityG as C2,Makes as V3
WHERE match(B-(V2)->C1) and match(A-(V1)->C2) and match(A-(V3)->B) and C1.City <> C2.City

--9. Товарами из какой категории в 1997-м году заинтересовалось больше всего компаний, имеющих факс?
SELECT count(*) from Suppliers
--R
SELECT TOP 1 WITH TIES cat.CategoryName,count(*)
FROM Suppliers as sup join Products as pr on sup.SupplierID = pr.SupplierID
join Categories as cat on cat.CategoryID = pr.CategoryID join 
[Order Details] as ordd on ordd.ProductID = pr.ProductID join
Orders as ord on ordd.OrderID = ord.OrderID
where YEAR(ord.OrderDate) = 1997-- and sup.Fax IS NOT NULL
Group By cat.CategoryID,cat.CategoryName
Order BY Count(*) DESC

--G
SELECT TOP 1 WITH TIES C.CategotyName,count(*)
FROM SuppliersG as A,Produces as V,ProductsG as B,Relate as V2,CategoriesG as C,
CustomersG as D,OrdersG as F,Makes as V3,[Contains] as V4  
where match(A-(V)->B-(V2)->C) and match(D-(V3)->F-(V4)->B) and YEAR(V3.OrderDate) = 1997
Group By C.CategoryID,C.CategotyName
Order BY Count(*) DESC

--10. Перечислите названия товаров, которые были проданы в количестве менее 1000 штук в регион, где они производились ?

--R
SELECT pr.ProductName,sup.Country,sum(ordd.Quantity)
FROM [Order Details] as ordd join Products as pr on pr.ProductID = ordd.ProductID join Suppliers as sup
on sup.SupplierID = pr.SupplierID join Orders as ord on ord.OrderID = ordd.OrderID
where ord.ShipCountry = sup.Country
group by ordd.ProductID,pr.ProductName,sup.Country
having sum(ordd.Quantity) < 1000
order by pr.ProductName

--G
SELECT B.ProductName,D2.Country,sum(V.Quantity)
FROM OrdersG as A,[Contains] as V,ProductsG as B,SuppliersG as C,Produces as V2,
Shipped as V3,CityG as D1,CityG as D2,Placed as V4
WHERE match(D1<-(V3)-A-(V)->B<-(V2)-C-(V4)->D2) and D2.Country = D1.Country
group by B.ProductID,B.ProductName,D2.Country
having sum(V.Quantity) < 1000
order by B.ProductName

--11 Как зовут покупателей, которые делали заказы с доставкой в город продавца

--R

SELECT cut.ContactName
FROM Customers as cut join Orders as ord on ord.CustomerID = cut.CustomerID
join Employees as emp on emp.EmployeeID = ord.EmployeeID
WHERE emp.City = ord.ShipCity

--G

SELECT A.ContactName
FROM CustomersG as A,Makes as V1,OrdersG as B,Shipped as V2,
CityG as D1,CityG as D2, EmployeesG as C,Collects as V3,LIVES_emp as V4
where match(A-(V1)->B-(V2)->D1) and match(D2<-(V4)-C-(V3)->B) and
D2.City = D1.City

--12.  Для каждого покупателя (имя, фамилия) показать название его любимого товара в каждой категории. Любимый товар – это тот, которого покупатель купил больше всего штук (столбец Quantity).

--R

WITH RankedTable as (
SELECT cut.ContactName,pr.CategoryID,pr.ProductName,ROW_NUMBER() OVER (PARTITION BY cut.CustomerID, pr.CategoryID ORDER BY sum(ordd.Quantity) DESC) as ranked
FROM Customers as cut join Orders as ord on ord.CustomerID = cut.CustomerID join [Order Details] as ordd on ordd.OrderID = ord.OrderID
join Products as pr on pr.ProductID = ordd.ProductID
group by cut.CustomerID,cut.ContactName,pr.CategoryID,pr.ProductName,pr.ProductID
)

Select ContactName,CategoryID,ProductName
FROM RankedTable
WHERE ranked = 1
order by ContactName,CategoryID

--G

WITH RankedTable as (
SELECT A.ContactName,D.CategoryID,C.ProductName,
ROW_NUMBER() OVER (PARTITION BY A.CustomerID, D.CategoryID ORDER BY sum(V2.Quantity) DESC) as ranked
FROM CustomersG as A,OrdersG as B,Makes as V1,
ProductsG as C,[Contains] as V2,CategoriesG as D,
Relate as V3
WHERE match(A-(V1)->B-(V2)->C-(V3)->D)
Group by A.CustomerID,A.ContactName,D.CategoryID,C.ProductName,C.ProductID
)

Select ContactName,CategoryID,ProductName
FROM RankedTable
WHERE ranked = 1
order by ContactName,CategoryID

--13 Сколько всего единиц товаров (то есть, штук – Quantity) продал каждый продавец (имя, фамилия) осенью 1996 года?

--R 
SELECT emp.EmployeeID,count(*)
FROM Employees as emp join Orders as ord on ord.EmployeeID = emp.EmployeeID
Where YEAR(ord.OrderDate) = 1996 
Group By emp.EmployeeID
order by emp.EmployeeID
--G

SELECT A.EmployeeID,count(*)
FROM EmployeesG as A,Collects as V,OrdersG as B,Makes as V2,CustomersG as C
WHERE match(A-(V)->B<-(V2)-C) and YEAR(V2.OrderDate) = 1996 
Group BY A.EmployeeID
order by A.EmployeeID

