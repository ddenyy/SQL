create TABLE CategoriesG (
    CategoryID INT PRIMARY KEY,
    CategotyName NVARCHAR(15) NOT NULL,
) AS NODE;
 
CREATE TABLE ProductsG (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(40) NOT NULL,
	UnitPrice money not null
) AS NODE;

select * from SuppliersG
CREATE TABLE SuppliersG (
    SupplierID INT PRIMARY KEY,
    CompanyName NVARCHAR(40) NOT NULL,
	ContactName NVARCHAR(30) null,
    Fax NVARCHAR(24) null
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
select * from SuppliersG
INSERT INTO SuppliersG(SupplierID,CompanyName,ContactName, Fax)
SELECT SupplierID,CompanyName,ContactName, Fax
FROM Suppliers
select * from OrdersG
INSERT INTO OrdersG(OrderID)
SELECT OrderID
FROM Orders
select * from CustomersG
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

select * from Produces

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
select * from LIVES_emp
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
select * from Shipped
INSERT INTO Shipped(ShippedDate,$from_id, $to_id)
SELECT rd.ShippedDate,
(SELECT $node_id FROM OrdersG WHERE  OrdersG.OrderID = rd.OrderID),
(SELECT $node_id FROM CityG WHERE  CityG.City = rd.ShipCity 
and CityG.Country = rd.ShipCountry
and (ISNULL(CityG.PostalCode,1) = ISNULL(rd.ShipPostalCode,1)) )
FROM  Orders as rd 
select * from Makes
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
FROM ProductsG AS Products,
    CategoriesG AS Categories,
    Relate AS ProductCategoryRelation
WHERE MATCH(Products-(ProductCategoryRelation)->Categories)
AND Categories.[CategoryID] = 1
ORDER BY Products.UnitPrice DESC;

--2 В какие города заказы комплектовались более десяти дней?

--R
SELECT Orders.OrderID
FROM Orders
WHERE DATEDIFF(DAY,Orders.OrderDate,Orders.ShippedDate) > 10

--G
SELECT Orders.OrderID
FROM CustomersG AS Customers,
     Makes AS CustomerOrderRelation,
     OrdersG AS Orders,
     CityG AS Cities,
     Shipped AS OrderShippingRelation
WHERE MATCH(Customers-(CustomerOrderRelation)->Orders-(OrderShippingRelation)->Cities)
  AND DATEDIFF(DAY, CustomerOrderRelation.OrderDate, OrderShippingRelation.ShippedDate) > 10;

--3 Какие покупатели до сих пор ждут отгрузки своих заказов?

--R
SELECT Orders.CustomerID
FROM Orders 
WHERE Orders.RequiredDate > '1998-05-29 00:00:00.000'
Order by Orders.CustomerID
--G
SELECT Customers.CustomerID
FROM CustomersG AS Customers,
     Makes AS CustomerOrderRelation,
     OrdersG AS Orders
WHERE MATCH(Customers-(CustomerOrderRelation)->Orders)
  AND CustomerOrderRelation.RequiredDate > '1998-05-29 00:00:00.000'
ORDER BY Customers.CustomerID;

--4. Скольких покупателей обслужил продавец, лидирующий по общему количеству заказов?

--R
SELECT TOP 1 WITH TIES emp.EmployeeID,COUNT(DISTINCT ord.CustomerID)
FROM Employees as emp join Orders as ord on ord.EmployeeID = emp.EmployeeID
GROUP BY emp.EmployeeID
ORDER BY count(*) DESC

--G
SELECT TOP 1 WITH TIES Employees.EmployeeID, COUNT(DISTINCT Customers.CustomerID) AS UniqueCustomersCount
FROM EmployeesG AS Employees,
     Collects AS EmployeeOrderRelation,
     OrdersG AS Orders,
     Makes AS CustomerOrderRelation,
     CustomersG AS Customers
WHERE MATCH(Employees-(EmployeeOrderRelation)->Orders<-(CustomerOrderRelation)-Customers)
GROUP BY Employees.EmployeeID
ORDER BY COUNT(*) DESC;

-- 5 Сколько французских городов обслужил продавец №1 в 1997-м?


--R
SELECT count(*)
FROM Employees as emp join Orders as ord on emp.EmployeeID = ord.EmployeeID
WHERE emp.EmployeeID = 1 and ord.ShipCountry = 'France' and YEAR(ord.OrderDate) = 1997

--G
SELECT COUNT(*)
FROM EmployeesG AS Employees,
     Collects AS EmployeeOrderRelation,
     OrdersG AS Orders,
     Shipped AS OrderShippingRelation,
     CityG AS Cities,
     CustomersG AS Customers,
     Makes AS CustomerOrderRelation
WHERE MATCH(
    Employees-(EmployeeOrderRelation)->Orders-(OrderShippingRelation)->Cities
)
AND MATCH(
    Customers-(CustomerOrderRelation)->Orders
)
AND Employees.EmployeeID = 1
AND Cities.Country = 'France'
AND YEAR(CustomerOrderRelation.OrderDate) = 1997;

--6 В каких странах есть города, в которые было отправлено больше двух заказов?

--R
SELECT Distinct Orders.ShipCountry
FROM Orders
GROUP BY Orders.ShipCity,Orders.ShipCountry
HAVING count(*) > 2

--G

SELECT DISTINCT Cities.Country
FROM OrdersG AS Orders,
     Shipped AS OrderShippingRelation,
     CityG AS Cities
WHERE MATCH(Orders-(OrderShippingRelation)->Cities)
GROUP BY Cities.City, Cities.Country
HAVING COUNT(*) > 2;


--7 Перечислите названия товаров, которые были проданы в количестве менее 1000 штук (quantity)?

--R
SELECT pr.ProductName
FROM [Order Details] as ordd join Products as pr on pr.ProductID = ordd.ProductID
group by ordd.ProductID,pr.ProductName
having sum(ordd.Quantity) < 1000

--G
SELECT Products.ProductName
FROM OrdersG AS Orders,
     [Contains] AS OrderProductRelation,
     ProductsG AS Products
WHERE MATCH(Orders-(OrderProductRelation)->Products)
GROUP BY Products.ProductID, Products.ProductName
HAVING SUM(OrderProductRelation.Quantity) < 1000;


--8. Как зовут покупателей, которые делали заказы с доставкой в другой город (не в тот, в котором они прописаны)?

--R
SELECT Distinct cut.ContactName
FROM Orders join Customers as cut on Orders.CustomerID = cut.CustomerID
WHERE Orders.ShipCity <> cut.City

--G
SELECT DISTINCT Customers.ContactName
FROM CustomersG AS Customers,
     LIVES AS CustomerCityRelation,
     OrdersG AS Orders,
     Shipped AS OrderShippingRelation,
     CityG AS ShippingCity,
     CityG AS CustomerCity,
     Makes AS CustomerOrderRelation
WHERE MATCH(Orders-(OrderShippingRelation)->ShippingCity) 
and MATCH (Customers-(CustomerCityRelation)->CustomerCity) 
and MATCH(Customers-(CustomerOrderRelation)->Orders)
and ShippingCity.City <> CustomerCity.City;

--9. Товарами из какой категории в 1997-м году заинтересовалось больше всего компаний, имеющих факс?

--R
SELECT TOP 1 WITH TIES cat.CategoryName,count(*)
FROM Suppliers as sup join Products as pr on sup.SupplierID = pr.SupplierID
join Categories as cat on cat.CategoryID = pr.CategoryID join 
[Order Details] as ordd on ordd.ProductID = pr.ProductID join
Orders as ord on ordd.OrderID = ord.OrderID
where YEAR(ord.OrderDate) = 1997  and sup.Fax IS NOT NULL
Group By cat.CategoryID,cat.CategoryName
Order BY Count(*) DESC

--G
SELECT TOP 1 WITH TIES
    Categories.CategotyName,
    COUNT(*) AS TotalCount
FROM SuppliersG AS Suppliers,
    Produces AS SupplierProductRelation,
    ProductsG AS Products,
    Relate AS ProductCategoryRelation,
    CategoriesG AS Categories,
    CustomersG AS Customers,
    OrdersG AS Orders,
    Makes AS CustomerOrderRelation,
    [Contains] AS OrderProductRelation
WHERE MATCH( Suppliers-(SupplierProductRelation)->Products-(ProductCategoryRelation)->Categories )
AND MATCH( Customers-(CustomerOrderRelation)->Orders-(OrderProductRelation)->Products )
AND YEAR(CustomerOrderRelation.OrderDate) = 1997
AND Suppliers.Fax IS NOT NULL
GROUP BY Categories.CategoryID, Categories.CategotyName
ORDER BY COUNT(*) DESC;

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
SELECT Products.ProductName,
    SupplierCity.Country,
    SUM(OrderProductRelation.Quantity) AS TotalQuantity
FROM OrdersG AS Orders,
    [Contains] AS OrderProductRelation,
    ProductsG AS Products,
    SuppliersG AS Suppliers,
    Produces AS SupplierProductRelation,
    Shipped AS OrderShippingRelation,
    CityG AS OrderCity,
    CityG AS SupplierCity,
    Placed AS SupplierCityRelation
WHERE MATCH(OrderCity <-(OrderShippingRelation)- Orders -(OrderProductRelation)-> Products <-(SupplierProductRelation)- Suppliers -(SupplierCityRelation)-> SupplierCity)
AND SupplierCity.Country = OrderCity.Country
GROUP BY Products.ProductID, Products.ProductName, SupplierCity.Country
HAVING SUM(OrderProductRelation.Quantity) < 1000
ORDER BY Products.ProductName;

--11 Как зовут покупателей, которые делали заказы с доставкой в город продавца

--R

SELECT cut.ContactName
FROM Customers as cut join Orders as ord on ord.CustomerID = cut.CustomerID
join Employees as emp on emp.EmployeeID = ord.EmployeeID
WHERE emp.City = ord.ShipCity

--G

SELECT Customers.ContactName
FROM CustomersG AS Customers,
     Makes AS CustomerOrderRelation,
     OrdersG AS Orders,
     Shipped AS OrderShippingRelation,
     CityG AS OrderCity,
     CityG AS EmployeeCity,
     EmployeesG AS Employees,
     Collects AS EmployeeOrderRelation,
     LIVES_emp AS EmployeeCityRelation
WHERE MATCH(
    Customers-(CustomerOrderRelation)->Orders-(OrderShippingRelation)->OrderCity
)
AND MATCH(
    EmployeeCity<-(EmployeeCityRelation)-Employees-(EmployeeOrderRelation)->Orders
)
AND EmployeeCity.City = OrderCity.City;

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
WITH RankedTable AS (
    SELECT 
        Customers.ContactName,
        Categories.CategoryID,
        Products.ProductName,
        ROW_NUMBER() OVER (
            PARTITION BY Customers.CustomerID, Categories.CategoryID
            ORDER BY SUM(OrderProductRelation.Quantity) DESC
        ) AS ranked
    FROM CustomersG AS Customers,
         OrdersG AS Orders,
         Makes AS CustomerOrderRelation,
         ProductsG AS Products,
         [Contains] AS OrderProductRelation,
         CategoriesG AS Categories,
         Relate AS ProductCategoryRelation
    WHERE MATCH(Customers-(CustomerOrderRelation)->Orders-(OrderProductRelation)->Products-(ProductCategoryRelation)->Categories)
    GROUP BY 
        Customers.CustomerID,
        Customers.ContactName,
        Categories.CategoryID,
        Products.ProductName,
        Products.ProductID
)
SELECT 
    ContactName,
    CategoryID,
    ProductName
FROM RankedTable
WHERE ranked = 1
ORDER BY ContactName, CategoryID;



--13 Сколько всего единиц товаров (то есть, штук – Quantity) продал каждый продавец (имя, фамилия) осенью 1996 года?

--R 
SELECT emp.EmployeeID,count(*)
FROM Employees as emp join Orders as ord on ord.EmployeeID = emp.EmployeeID
Where YEAR(ord.OrderDate) = 1996 
Group By emp.EmployeeID
order by emp.EmployeeID
--G
SELECT Employees.EmployeeID,
       COUNT(*) AS TotalCount
FROM EmployeesG AS Employees,
     Collects AS EmployeeOrderRelation,
     OrdersG AS Orders,
     Makes AS CustomerOrderRelation,
     CustomersG AS Customers
WHERE MATCH(
    Employees-(EmployeeOrderRelation)->Orders<-(CustomerOrderRelation)-Customers
)
AND YEAR(CustomerOrderRelation.OrderDate) = 1996
GROUP BY Employees.EmployeeID
ORDER BY Employees.EmployeeID;

