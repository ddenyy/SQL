use nordwind


select *
from Categories

CREATE TABLE CategoriesG (
    CategoryID INT PRIMARY KEY,
    CategotyName NVARCHAR(15) NOT NULL
) AS NODE;

CREATE TABLE ProductsG (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(40) NOT NULL,
	UnitPrice money not null
) AS NODE;

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

DROP TABLE CustomersG

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


INSERT INTO CategoriesG(CategoryID,CategoryName)
SELECT CategoryID,CategoryName
FROM Categories

INSERT INTO ProductsG(ProductID,ProductName,UnitPrice)
SELECT ProductID,ProductName,UnitPrice
FROM Products

INSERT INTO EmployeesG(EmployeeID,LastName,FirstName)
SELECT EmployeeID,LastName,FirstName
FROM Employees

INSERT INTO SuppliersG(SupplierID,CompanyName,ContactName, Fax)
SELECT SupplierID,CompanyName,ContactName,Fax
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
(SELECT $node_id FROM SuppliersG WHERE  SuppliersG.SupplierID = sup.SupplierID),
(SELECT $node_id FROM CityG WHERE  CityG.City = sup.City 
and CityG.Country = sup.Country
and CityG.PostalCode = sup.PostalCode)
FROM Suppliers as sup

INSERT INTO LIVES($from_id, $to_id)
SELECT
(SELECT $node_id FROM CustomersG WHERE  CustomersG.CustomerID = cus.CustomerID),
(SELECT $node_id FROM CityG WHERE  CityG.City = cus.City 
and CityG.Country = cus.Country
and (ISNULL(CityG.PostalCode,'1') = ISNULL(cus.PostalCode,'1')) )
FROM Customers as cus

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
SELECT ord.OrderID
FROM CustomersG AS cus,
     Makes AS makes,
     OrdersG AS ord,
     CityG AS city,
     Shipped AS shipp
WHERE MATCH(cus-(makes)->ord-(shipp)->city)
  AND DATEDIFF(DAY, makes.OrderDate, shipp.ShippedDate) > 10;

--3 Какие покупатели до сих пор ждут отгрузки своих заказов?
-- в силу того что бд старая, не могу использовать ф-цию для получения текущей даты.
--R
DECLARE @curDate DATETIME = CAST('1998-05-29 00:00:00.000' AS DATETIME);

SELECT Orders.CustomerID
FROM Orders 
WHERE Orders.RequiredDate > @curDate
Order by Orders.CustomerID
--G
DECLARE @curDate DATETIME = CAST('1998-05-29 00:00:00.000' AS DATETIME);

SELECT cus.CustomerID
FROM CustomersG as cus,
Makes as makes,
OrdersG as ord
WHERE Match(cus-(makes)->ord) and makes.RequiredDate > @curDate
Order by cus.CustomerID

select * from Makes ORDER by Makes.RequiredDate;

--4. Скольких покупателей обслужил продавец, лидирующий по общему количеству заказов?

--R
SELECT TOP 1 WITH TIES emp.EmployeeID,COUNT(DISTINCT ord.CustomerID)
FROM Employees as emp join Orders as ord on ord.EmployeeID = emp.EmployeeID
GROUP BY emp.EmployeeID
ORDER BY count(*) DESC

--G

SELECT TOP 1 WITH TIES emp.EmployeeID,COUNT(DISTINCT cus.CustomerID)
FROM EmployeesG as emp,
Collects as collect,
OrdersG as ord,
Makes as makes,
CustomersG as cus
WHERE Match(emp-(collect)->ord<-(makes)-cus)
GROUP BY emp.EmployeeID
ORDER BY count(*) DESC

-- 5 Сколько французских городов обслужил продавец №1 в 1997-м?


--R
SELECT count(*)
FROM Employees as emp 
join Orders as ord on emp.EmployeeID = ord.EmployeeID
WHERE emp.EmployeeID = 1 
and ord.ShipCountry = 'France' 
and YEAR(ord.OrderDate) = 1997;

--G
SELECT count(*)
FROM EmployeesG as emp,
Collects as collect,
OrdersG as ord,
Shipped as shipp,
CityG as city,
CustomersG as cus,
Makes as makes
WHERE Match(emp-(collect)->ord-(shipp)->city) 
and match(cus-(makes)->ord) 
and emp.EmployeeID = 1 
and city.Country = 'France' 
and YEAR(makes.OrderDate) = 1997


--6 В каких странах есть города, в которые было отправлено больше двух заказов?

--R
SELECT Distinct Orders.ShipCountry
FROM Orders
GROUP BY Orders.ShipCity,Orders.ShipCountry
HAVING count(*) > 2

--G

SELECT Distinct city.Country
From OrdersG as ord,
Shipped as ship,
CityG as city
WHERE Match(ord-(ship)->city)
GROUP BY city.City,city.Country
HAVING count(*) > 2


--7 Перечислите названия товаров, которые были проданы в количестве менее 1000 штук (quantity)?

--R
SELECT pr.ProductName
FROM [Order Details] as ordd 
join Products as pr on pr.ProductID = ordd.ProductID
group by ordd.ProductID, pr.ProductName
having sum(ordd.Quantity) < 1000

--G
SELECT pr.ProductName
FROM OrdersG as ord,
[Contains] as cont,
ProductsG as pr
WHERE match(ord-(cont)->pr)
group by pr.ProductID, pr.ProductName
having sum(cont.Quantity) < 1000


--8. Как зовут покупателей, которые делали заказы с доставкой в другой город (не в тот, в котором они прописаны)?

--R
SELECT Distinct cus.ContactName
FROM Orders join Customers as cus on Orders.CustomerID = cus.CustomerID
WHERE  Orders.ShipCity <> cus.City

--G
SELECT Distinct cus.ContactName
FROM CustomersG as cus,
LIVES as lives,
OrdersG as ord,
Shipped ship,
CityG as city1,
CityG as city2,
Makes as makes
WHERE match(ord-(ship)->city1) 
and match(cus-(lives)->city2) 
and match(cus-(makes)->ord) 
and city1.City <> city2.City

--9. Товарами из какой категории в 1997-м году заинтересовалось больше всего компаний, имеющих факс?

--R
SELECT TOP 1 WITH TIES 
    cat.CategoryName, 
    COUNT(DISTINCT sup.SupplierID) AS InterestedCompaniesCount
FROM Suppliers AS sup
JOIN Products AS pr ON sup.SupplierID = pr.SupplierID
JOIN Categories AS cat ON cat.CategoryID = pr.CategoryID
JOIN [Order Details] AS ordd ON ordd.ProductID = pr.ProductID
JOIN Orders AS ord ON ordd.OrderID = ord.OrderID
WHERE YEAR(ord.OrderDate) = 1997
  AND sup.Fax IS NOT NULL
GROUP BY cat.CategoryID, cat.CategoryName
ORDER BY COUNT(DISTINCT sup.SupplierID) DESC;

--G
SELECT TOP 1 WITH TIES 
    cat.CategoryName,
    COUNT(DISTINCT sup.SupplierID) AS InterestedCompaniesCount
FROM SuppliersG as sup,
Produces as produce,
ProductsG as pr,
Relate as relate,
CategoriesG as cat,
CustomersG as cus,
OrdersG as ord,
Makes as makes,
[Contains] as containns  
where match(sup-(produce)->pr-(relate)->cat) 
and match(cus-(makes)->ord-(containns)->pr) 
and YEAR(makes.OrderDate) = 1997 
and sup.Fax IS NOT NULL
Group By cat.CategoryID, cat.CategoryName
Order BY Count(DISTINCT sup.SupplierID) DESC

--10. Перечислите названия товаров, которые были проданы в количестве менее 1000 штук в регион, где они производились ?

--R
SELECT pr.ProductName,sup.Country,sum(ordd.Quantity)
FROM [Order Details] as ordd
join Products as pr on pr.ProductID = ordd.ProductID 
join Suppliers as sup on sup.SupplierID = pr.SupplierID
join Orders as ord on ord.OrderID = ordd.OrderID
where ord.ShipCountry = sup.Country
group by ordd.ProductID, pr.ProductName, sup.Country
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

