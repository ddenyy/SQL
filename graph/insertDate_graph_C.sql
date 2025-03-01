
-- Вставляем тестовые данные для студентов
INSERT INTO Students (ID, FIO, Course)
VALUES
(1, N'Иванов Иван Иванович', 1),
(2, N'Петров Петр Петрович', 2),
(3, N'Сидорова Анна Сергеевна', 3);

-- Вставляем тестовые данные для групп
INSERT INTO Groups (ID, Name)
VALUES
(1, N'Группа ИТ-101'),
(2, N'Группа ИТ-202');

-- Вставляем тестовые данные для специальностей
INSERT INTO Specialities (Code, Name)
VALUES
(101, N'Информационные технологии'),
(102, N'Прикладная математика');

-- Вставляем тестовые данные для дисциплин
INSERT INTO Disciplines (Code, Name)
VALUES
(201, N'Программирование'),
(202, N'Математический анализ'),
(203, N'Базы данных');

-- Вставляем тестовые данные для учебных планов
INSERT INTO StudyPlans (ContractNumber, Course, Semester, timeLecture, timePractice, typeReporting)
VALUES
(1001, 1, 1, 40, 20, 1),
(1002, 2, 1, 30, 30, 2);

-- Вставляем тестовые данные для преподавателей
INSERT INTO Teachers (ID, FIO)
VALUES
(1, N'Кузнецов Олег Иванович'),
(2, N'Васильева Ольга Николаевна');

-- Вставляем тестовые данные для кафедр
INSERT INTO Departments (ID, Name)
VALUES
(1, N'Кафедра программирования'),
(2, N'Кафедра математики');

-- Связи: STUDIES_IN
-- Связи: STUDIES_IN
INSERT INTO StudiesIn
VALUES
((SELECT $node_id FROM Students WHERE ID = 1), (SELECT $node_id FROM Groups WHERE ID = 1)), -- Иванов в группе ИТ-101
((SELECT $node_id FROM Students WHERE ID = 2), (SELECT $node_id FROM Groups WHERE ID = 1)), -- Петров в группе ИТ-101
((SELECT $node_id FROM Students WHERE ID = 3), (SELECT $node_id FROM Groups WHERE ID = 2)); -- Сидорова в группе ИТ-202

-- Связи: HAS_SPECIALITY
-- Связи: HAS_SPECIALITY
INSERT INTO HasSpeciality
VALUES
((SELECT $node_id FROM Groups WHERE ID = 1), (SELECT $node_id FROM Specialities WHERE Code = 101)), -- Группа ИТ-101 связана со специальностью Информационные технологии
((SELECT $node_id FROM Groups WHERE ID = 2), (SELECT $node_id FROM Specialities WHERE Code = 102)); -- Группа ИТ-202 связана со специальностью Прикладная математика

-- Связи: HAS_DISCIPLINE
-- Связи: HAS_DISCIPLINE
INSERT INTO HasDiscipline
VALUES
((SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1001), (SELECT $node_id FROM Disciplines WHERE Code = 201)), -- Учебный план 1001 включает дисциплину Программирование
((SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1001), (SELECT $node_id FROM Disciplines WHERE Code = 202)), -- Учебный план 1001 включает дисциплину Математический анализ
((SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1002), (SELECT $node_id FROM Disciplines WHERE Code = 203)); -- Учебный план 1002 включает дисциплину Базы данных

-- Связи: CanLead
-- Связи: CAN_LEAD
INSERT INTO CanLead
VALUES
((SELECT $node_id FROM Teachers WHERE ID = 1), (SELECT $node_id FROM Disciplines WHERE Code = 201)), -- Кузнецов ведет Программирование
((SELECT $node_id FROM Teachers WHERE ID = 2), (SELECT $node_id FROM Disciplines WHERE Code = 202)), -- Васильева ведет Математический анализ
((SELECT $node_id FROM Teachers WHERE ID = 2), (SELECT $node_id FROM Disciplines WHERE Code = 203)); -- Васильева ведет Базы данных

-- Связи: WORKS_IN
-- Связи: WORKS_IN
INSERT INTO WorksIn
VALUES
((SELECT $node_id FROM Teachers WHERE ID = 1), (SELECT $node_id FROM Departments WHERE ID = 1)), -- Кузнецов работает в Кафедре программирования
((SELECT $node_id FROM Teachers WHERE ID = 2), (SELECT $node_id FROM Departments WHERE ID = 2)); -- Васильева работает в Кафедре математики

-- Связи: EVALUATED_BY
-- Связи: EVALUATED_BY
-- Вставка данных в EvaluatedBy с использованием графовых узлов
INSERT INTO EvaluatedBy ( $from_id, $to_id, Mark, TypeOfMark )
VALUES
(
    (SELECT $node_id FROM Students WHERE ID = 1), 
    (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1001), 
    N'5', 
    N'Экзамен'
),
(
    (SELECT $node_id FROM Students WHERE ID = 2), 
    (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1001), 
    N'зачет', 
    N'зачет'
),
(
    (SELECT $node_id FROM Students WHERE ID = 3), 
    (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1002), 
    N'2', 
    N'Экзамен'
);
-- Связи: LeadsPlanGroup
-- Связи: LeadsPlanGroup
INSERT INTO LeadsPlanGroup ($from_id, $to_id, TypeOfLesson)
VALUES
((SELECT $node_id FROM Teachers WHERE ID = 1), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1001), N'Лекция'), -- Кузнецов ведет лекции по плану 1001
((SELECT $node_id FROM Teachers WHERE ID = 2), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1002), N'Практика'); -- Васильева ведет практику по плану 1002











INSERT INTO Students (ID, FIO, Course)
VALUES
(4, N'Александров Александр Игоревич', 1),
(5, N'Егорова Елизавета Дмитриевна', 2),
(6, N'Никитин Никита Алексеевич', 3);

INSERT INTO Groups (ID, Name)
VALUES
(3, N'Группа ИТ-303'),
(4, N'Группа ПМ-404');

INSERT INTO Specialities (Code, Name)
VALUES
(103, N'Системное программирование'),
(104, N'Инженерный анализ');

INSERT INTO Disciplines (Code, Name)
VALUES
(204, N'Алгоритмы и структуры данных'),
(205, N'Численные методы'),
(206, N'Машинное обучение');

INSERT INTO StudyPlans (ContractNumber, Course, Semester, timeLecture, timePractice, typeReporting)
VALUES
(1003, 3, 2, 50, 30, 1),
(1004, 1, 2, 40, 40, 2);

INSERT INTO Teachers (ID, FIO)
VALUES
(3, N'Семенова Наталья Алексеевна'),
(4, N'Дмитриев Виктор Павлович');

INSERT INTO Departments (ID, Name)
VALUES
(3, N'Кафедра прикладной математики'),
(4, N'Кафедра искусственного интеллекта');

INSERT INTO StudiesIn
VALUES
((SELECT $node_id FROM Students WHERE ID = 4), (SELECT $node_id FROM Groups WHERE ID = 3)), -- Александров в группе ИТ-303
((SELECT $node_id FROM Students WHERE ID = 5), (SELECT $node_id FROM Groups WHERE ID = 4)), -- Егорова в группе ПМ-404
((SELECT $node_id FROM Students WHERE ID = 6), (SELECT $node_id FROM Groups WHERE ID = 3)); -- Никитин в группе ИТ-303


INSERT INTO HasSpeciality
VALUES
((SELECT $node_id FROM Groups WHERE ID = 3), (SELECT $node_id FROM Specialities WHERE Code = 103)), -- Группа ИТ-303 связана со специальностью Системное программирование
((SELECT $node_id FROM Groups WHERE ID = 4), (SELECT $node_id FROM Specialities WHERE Code = 104)); -- Группа ПМ-404 связана со специальностью Инженерный анализ



INSERT INTO HasDiscipline
VALUES
((SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1003), (SELECT $node_id FROM Disciplines WHERE Code = 204)), -- Учебный план 1003 включает Алгоритмы и структуры данных
((SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1003), (SELECT $node_id FROM Disciplines WHERE Code = 205)), -- Учебный план 1003 включает Численные методы
((SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1004), (SELECT $node_id FROM Disciplines WHERE Code = 206)); -- Учебный план 1004 включает Машинное обучение


INSERT INTO CanLead
VALUES
((SELECT $node_id FROM Teachers WHERE ID = 3), (SELECT $node_id FROM Disciplines WHERE Code = 204)), -- Семенова ведет Алгоритмы и структуры данных
((SELECT $node_id FROM Teachers WHERE ID = 4), (SELECT $node_id FROM Disciplines WHERE Code = 205)), -- Дмитриев ведет Численные методы
((SELECT $node_id FROM Teachers WHERE ID = 4), (SELECT $node_id FROM Disciplines WHERE Code = 206)); -- Дмитриев ведет Машинное обучение

INSERT INTO WorksIn
VALUES
((SELECT $node_id FROM Teachers WHERE ID = 3), (SELECT $node_id FROM Departments WHERE ID = 3)), -- Семенова работает в Кафедре прикладной математики
((SELECT $node_id FROM Teachers WHERE ID = 4), (SELECT $node_id FROM Departments WHERE ID = 4)); -- Дмитриев работает в Кафедре искусственного интеллекта


INSERT INTO EvaluatedBy ( $from_id, $to_id, Mark, TypeOfMark )
VALUES
((SELECT $node_id FROM Students WHERE ID = 4), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1003), N'4', N'Экзамен'), -- Александров получил 4 на экзамене
((SELECT $node_id FROM Students WHERE ID = 5), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1004), N'5', N'Зачет'), -- Егорова получила 5 на зачете
((SELECT $node_id FROM Students WHERE ID = 6), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1003), N'3', N'Экзамен'); -- Никитин получил 3 на экзамене

INSERT INTO LeadsPlanGroup ( $from_id, $to_id, TypeOfLesson )
VALUES
((SELECT $node_id FROM Teachers WHERE ID = 3), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1003), N'Лекция'), -- Семенова ведет лекции по плану 1003
((SELECT $node_id FROM Teachers WHERE ID = 4), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1004), N'Практика'); -- Дмитриев ведет практику по плану 1004


-- Добавляем студентов
INSERT INTO Students (ID, FIO, Course)
VALUES
(7, N'Ковалев Константин Андреевич', 3),
(8, N'Маркова Мария Владимировна', 3),
(9, N'Гаврилов Андрей Сергеевич', 3),
(10, N'Смирнова Светлана Олеговна', 3),
(11, N'Тарасов Тимофей Николаевич', 1),
(12, N'Федоров Дмитрий Павлович', 1),
(13, N'Лебедева Наталья Игоревна', 1),
(14, N'Григорьев Василий Алексеевич', 2),
(15, N'Морозова Екатерина Сергеевна', 2);


-- Студенты в группе ИТ-303
INSERT INTO StudiesIn
VALUES
((SELECT $node_id FROM Students WHERE ID = 7), (SELECT $node_id FROM Groups WHERE ID = 3)), -- Ковалев в группе ИТ-303
((SELECT $node_id FROM Students WHERE ID = 8), (SELECT $node_id FROM Groups WHERE ID = 3)), -- Маркова в группе ИТ-303
((SELECT $node_id FROM Students WHERE ID = 9), (SELECT $node_id FROM Groups WHERE ID = 3)), -- Гаврилов в группе ИТ-303
((SELECT $node_id FROM Students WHERE ID = 10), (SELECT $node_id FROM Groups WHERE ID = 3)); -- Смирнова в группе ИТ-303

-- Студенты в группе ПМ-404
INSERT INTO StudiesIn
VALUES
((SELECT $node_id FROM Students WHERE ID = 11), (SELECT $node_id FROM Groups WHERE ID = 4)), -- Тарасов в группе ПМ-404
((SELECT $node_id FROM Students WHERE ID = 12), (SELECT $node_id FROM Groups WHERE ID = 4)), -- Федоров в группе ПМ-404
((SELECT $node_id FROM Students WHERE ID = 13), (SELECT $node_id FROM Groups WHERE ID = 4)), -- Лебедева в группе ПМ-404
((SELECT $node_id FROM Students WHERE ID = 14), (SELECT $node_id FROM Groups WHERE ID = 4)), -- Григорьев в группе ПМ-404
((SELECT $node_id FROM Students WHERE ID = 15), (SELECT $node_id FROM Groups WHERE ID = 4)); -- Морозова в группе ПМ-404


-- Оценки студентов из группы ИТ-303
INSERT INTO EvaluatedBy ( $from_id, $to_id, Mark, TypeOfMark )
VALUES
((SELECT $node_id FROM Students WHERE ID = 7), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1003), N'4', N'Экзамен'), -- Ковалев получил 4 на экзамене
((SELECT $node_id FROM Students WHERE ID = 8), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1003), N'зачет', N'Зачет'), -- Маркова получила 5 на зачете
((SELECT $node_id FROM Students WHERE ID = 9), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1003), N'незачет', N'Зачет'), -- Гаврилов получил 3 на тесте
((SELECT $node_id FROM Students WHERE ID = 10), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1003), N'2', N'Экзамен'); -- Смирнова получила 2 на экзамене

-- Оценки студентов из группы ПМ-404
INSERT INTO EvaluatedBy ( $from_id, $to_id, Mark, TypeOfMark )
VALUES
((SELECT $node_id FROM Students WHERE ID = 11), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1004), N'5', N'Экзамен'), -- Тарасов получил 5 на практике
((SELECT $node_id FROM Students WHERE ID = 12), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1004), N'4', N'Экзамен'), -- Федоров получил 4 на практике
((SELECT $node_id FROM Students WHERE ID = 13), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1004), N'незачет', N'Зачет'), -- Лебедева получила 3 на тесте
((SELECT $node_id FROM Students WHERE ID = 14), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1004), N'4', N'Экзамен'), -- Григорьев получил 4 на экзамене
((SELECT $node_id FROM Students WHERE ID = 15), (SELECT $node_id FROM StudyPlans WHERE ContractNumber = 1004), N'незачет', N'Зачет'); -- Морозова получила 5 на зачете

