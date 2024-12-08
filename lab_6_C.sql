-- Создаём узел для студентов
CREATE TABLE Students (
    ID INT PRIMARY KEY,
    FIO NVARCHAR(100) NOT NULL,
    Course INT NOT NULL,
) AS NODE;

-- Создаём узел для групп
CREATE TABLE Groups (
    ID INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
) AS NODE;

-- Создаём узел для специальностей
CREATE TABLE Specialities (
    Code INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
) AS NODE;

-- Создаём узел для дисциплин
CREATE TABLE Disciplines (
    Code INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
) AS NODE;

-- Создаём узел для учебных планов
CREATE TABLE StudyPlans (
    ContractNumber INT PRIMARY KEY,
    Course INT NOT NULL,
    Semester INT NOT NULL,
    timeLecture INT NOT NULL, 
    timePractice INT NOT NULL, 
    typeReporting INT NOT NULL
) AS NODE;

-- Создаём узел для преподавателей
CREATE TABLE Teachers (
    ID INT PRIMARY KEY,
    FIO NVARCHAR(100) NOT NULL
) AS NODE;

-- Создаём узел для кафедр
CREATE TABLE Departments (
    ID INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
) AS NODE;


-- Связь STUDIES_IN: Студенты принадлежат группам
CREATE TABLE StudiesIn AS EDGE;

-- Связь HAS_SPECIALITY: Группы относятся к специальностям
CREATE TABLE HasSpeciality AS EDGE;

-- Связь HAS_DISCIPLINE: Учебные планы включают дисциплины
CREATE TABLE HasDiscipline AS EDGE;

-- Связь CanLead: Преподаватели ведут дисциплины
CREATE TABLE CanLead AS EDGE;


-- Связь WORKS_IN: Преподаватели работают в кафедрах
CREATE TABLE WorksIn AS EDGE;

-- Связь EVALUATED_BY: Студенты связаны с учебными планами и их оценками
CREATE TABLE EvaluatedBy (
    Mark NVARCHAR(10),
    TypeOfMark NVARCHAR(45)
) AS EDGE;

CREATE TABLE LeadsPlanGroup (
    TypeOfLesson NVARCHAR(255) NOT NULL  -- Тип занятия (например, лекция)
) AS EDGE;



-- 1) вывести список дисциплин изучаемых по специальности (введите название специальности)
SELECT DISTINCT d.Name AS DisciplineName
FROM Specialities s, HasSpeciality hs, Groups g, StudiesIn si, StudyPlans sp, HasDiscipline hd, Disciplines d
WHERE MATCH(s-(hs)->g-(si)->sp-(hd)->d)
  AND s.Name =  N'Системное программирование';


SELECT DISTINCT d.Name AS DisciplineName
FROM Specialities s, HasSpeciality hs, Groups g, StudiesIn si, StudyPlans sp, HasDiscipline hd, Disciplines d
WHERE MATCH(s-(hs)->g-(si)->sp-(hd)->d)
  AND s.Name =  N'Прикладная математика';


-- 2) Посчитать нагрузку для всех преподавателей по кафедрам (кафедра, ФИО, кол-во часов лекций, кол-во часов практики)
SELECT 
    d.Name AS DepartmentName,
    t.FIO AS TeacherFIO,
    SUM(CASE WHEN l.TypeOfLesson = N'Лекция' THEN sp.timeLecture ELSE 0 END) AS LectureHours,
    SUM(CASE WHEN l.TypeOfLesson = N'Практика' THEN sp.timePractice ELSE 0 END) AS PracticeHours
FROM dbo.Departments d,
     dbo.WorksIn w,
     dbo.Teachers t,
     dbo.LeadsPlanGroup l,
     dbo.StudyPlans sp
WHERE MATCH(t-(w)->d)
  AND MATCH(t-(l)->sp)
GROUP BY d.Name, t.FIO
ORDER BY d.Name, t.FIO;


--3) Найти дисциплины, наиболее и наименее успешно сданные студентами
SELECT d.Name AS DisciplineName,
       COUNT(*) AS PoorMarkCount
FROM Students st, EvaluatedBy eb, StudyPlans sp, HasDiscipline hd, Disciplines d
WHERE MATCH(st-(eb)->sp-(hd)->d)
  AND (eb.Mark = N'2' OR eb.Mark = N'незачет' OR eb.Mark IS NULL)
GROUP BY d.Name
ORDER BY PoorMarkCount ASC;


--4) Подготовить информацию для начисления стипендии (на стипендию претендуют студенты, не имеющие оценок «2», «3»,
-- «незачет» и сдавшие все экзамены/зачеты в соотв. с учебным планом) 
-- (вывести: группа, кол-во студентов без троек)

SELECT g.Name AS GroupName, COUNT(DISTINCT st.ID) AS StudentsCount
FROM Groups g,
     StudiesIn si,
     Students st,
     EvaluatedBy eb,
     StudyPlans sp,
     HasDiscipline hd,
     Disciplines d
WHERE MATCH(st-(si)->g) 
  AND MATCH(st-(eb)->sp-(hd)->d)
  AND eb.Mark NOT IN (N'2', N'3', N'незачет') 
  AND eb.Mark IS NOT NULL
GROUP BY g.Name, sp.$node_id
HAVING COUNT(DISTINCT d.Code) = (
    SELECT COUNT(*) 
    FROM Disciplines d2
    JOIN HasDiscipline hd2 ON d2.$node_id = hd2.$to_id
    WHERE hd2.$from_id = sp.$node_id
);

--5) Для каждой группы найти отличников и двоечников 
-- (вывести: группа, кол-во студентов с одними пятерками, кол-во студентов, 
-- имеющих хотя бы одну «2» или «незачет»)
WITH M AS (
    SELECT g.Name AS GroupName, st.ID,
           SUM(CASE WHEN eb.Mark = N'5' THEN 1 ELSE 0 END) AS Fives,
           SUM(CASE WHEN eb.Mark IN (N'2', N'незачет') THEN 1 ELSE 0 END) AS Poor,
           COUNT(*) AS Total
    FROM Groups g, StudiesIn si, Students st, EvaluatedBy eb, StudyPlans sp, HasDiscipline hd, Disciplines d
    WHERE MATCH(st-(si)->g) and MATCH(st-(eb)->sp-(hd)->d)
    GROUP BY g.Name, st.ID
)
SELECT GroupName,
       SUM(CASE WHEN Poor=0 AND Fives=Total AND Total>0 THEN 1 ELSE 0 END) AS ExcellentStudents,
       SUM(CASE WHEN Poor>0 THEN 1 ELSE 0 END) AS PoorStudents
FROM M
GROUP BY GroupName
ORDER BY GroupName;





--6) в моей версии sql DB нету поддержки shortest_path ибо она урезана. я проверил оф.доку.
-- но чтобы хоть как-то сделать задание которое было указано, я создал свой запрос только через match.
-- Microsoft Azure SQL Edge Developer (RTM) - 15.0.2000.1574 (ARM64)
SELECT DISTINCT 
    CONCAT(s.Name, ' -> ', g.Name, ' -> ', sp.ContractNumber, ' -> ', d.Name) AS Path
FROM 
    Specialities AS s, 
    HasSpeciality AS hs, 
    Groups AS g, 
    StudiesIn AS si, 
    StudyPlans AS sp, 
    HasDiscipline AS hd, 
    Disciplines AS d
WHERE 
    MATCH(s-(hs)->g-(si)->sp-(hd)->d)
    AND s.Name = N'Прикладная математика';

