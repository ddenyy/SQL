-- Создаем узлы (Nodes)
CREATE TABLE Square (
    SquareID INT PRIMARY KEY,
    Name NVARCHAR(50)
) AS NODE;

CREATE TABLE Balloon (
    BalloonID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Color CHAR(1)
) AS NODE;

CREATE TABLE Connection (
    ConnectionID INT IDENTITY PRIMARY KEY,
    EventTime DATETIME,
    Volume TINYINT
) AS NODE;

-- Создаем ребра (Edges)
CREATE TABLE HasConnection AS EDGE;

CREATE TABLE InvolvesBalloon AS EDGE;

-- Вставляем данные в узлы
INSERT INTO Square (SquareID, Name)
SELECT Q_ID, Q_NAME FROM utQ;

INSERT INTO Balloon (BalloonID, Name, Color)
SELECT V_ID, V_NAME, V_COLOR FROM utV;

INSERT INTO Connection (EventTime, Volume)
SELECT DISTINCT B_DATETIME, B_VOL FROM utB;

-- Вставляем связи (Edges)
-- Вставляем связи (Edges) между Square и Connection
INSERT INTO HasConnection
SELECT s.$node_id, c.$node_id
FROM utB b
JOIN Square s ON s.SquareID = b.B_Q_ID
JOIN Connection c ON c.EventTime = b.B_DATETIME AND c.Volume = b.B_VOL;

-- Вставляем ребра InvolvesBalloon (из Connection в Balloon)
INSERT INTO InvolvesBalloon
SELECT c.$node_id, bl.$node_id
FROM utB u
JOIN Connection c ON c.EventTime = u.B_DATETIME AND c.Volume = u.B_VOL
JOIN Balloon bl ON bl.BalloonID = u.B_V_ID;


--1.Найти квадраты, которые окрашивались красной краской. Вывести идентификатор квадрата и объем красной краски
SELECT square.SquareID AS SquareID, cconnection.Volume AS RedPaintVolume
FROM Square square, Connection cconnection, Balloon ballon, HasConnection hasconnection, InvolvesBalloon involvesballon
WHERE MATCH (square-(hasconnection)->cconnection-(involvesballon)->ballon)
  AND ballon.Color = 'R';

-- тоже самое но реляционный вид.
SELECT q.Q_ID AS SquareID, b.B_VOL AS RedPaintVolume
FROM utQ q
JOIN utB b ON q.Q_ID = b.B_Q_ID
JOIN utV v ON b.B_V_ID = v.V_ID
WHERE v.V_COLOR = 'R';


--2.Найти квадраты, которые окрашивались как красной, так и синей краской. Вывести: название квадрата.
SELECT DISTINCT square.Name AS SquareName
FROM Square square, Connection cconnection, Balloon ballon, HasConnection hasconnection, InvolvesBalloon involvesballon
WHERE MATCH (square-(hasconnection)->cconnection-(involvesballon)->ballon)
  AND ballon.Color IN ('R', 'B')
GROUP BY square.Name
HAVING COUNT(DISTINCT ballon.Color) = 2;

--3.Найти квадраты, которые окрашивались всеми тремя цветами
SELECT DISTINCT square.Name AS SquareName
FROM Square square, Connection cconnection, Balloon ballon, HasConnection hasconnection, InvolvesBalloon involvesballon
WHERE MATCH (square-(hasconnection)->cconnection-(involvesballon)->ballon)
  AND ballon.Color IN ('R', 'G', 'B')
GROUP BY square.Name
HAVING COUNT(DISTINCT ballon.Color) = 3;

--4.	Найти баллончики, которыми окрашивали более одного квадрата
SELECT DISTINCT ballon.BalloonID, ballon.Name AS BalloonName
FROM Square square, Connection cconnection, Balloon ballon, HasConnection hasconnection, InvolvesBalloon involvesballon
WHERE MATCH (square-(hasconnection)->cconnection-(involvesballon)->ballon)
GROUP BY ballon.BalloonID, ballon.Name
HAVING COUNT(DISTINCT square.SquareID) > 1;


--Найти квадраты, окрашенные зелёными балонами (Color = 'G'), и суммарный объём краски, использованный для квадрата.
SELECT square.Name AS SquareName, SUM(cconnection.Volume) AS TotalGreenVolume
FROM Square square, Connection cconnection, Balloon ballon, HasConnection hasconnection, InvolvesBalloon involvesballon
WHERE MATCH (square-(hasconnection)->cconnection-(involvesballon)->ballon)
  AND ballon.Color = 'G'
GROUP BY square.Name
ORDER BY TotalGreenVolume DESC;


--Найти баллоны, которые использовались только для окраски квадратов при котором использовали объём краски более 200.
--SELECT DISTINCT ballon.BalloonID, ballon.Name AS BalloonName
--FROM Balloon ballon, Connection cconnection, Square square, HasConnection hasconnection, InvolvesBalloon involvesballon
--WHERE MATCH (square-(hasconnection)->cconnection-(involvesballon)->ballon)
--  AND cconnection.Volume > 200
--  AND NOT EXISTS (
--    SELECT 1
--    FROM Square sq, Connection cc, HasConnection hc, InvolvesBalloon ib
--    WHERE MATCH (sq-(hc)->cc-(ib)->ballon)
--      AND cc.Volume <= 200
--  );