--a) Процедура без параметров, формирующая список преподавателей, 
--   которые должны принимать экзамены в зимнюю сессию в соответствии с имеющимся учебным планом.
CREATE OR REPLACE PROCEDURE GetWinterExamTeachers()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD; -- Объявляем переменную для хранения строки результата
BEGIN
    -- Выводим список преподавателей, которые принимают экзамены в зимнюю сессию
    RAISE NOTICE 'Список преподавателей, принимающих экзамены в зимнюю сессию:';

    FOR rec IN
        SELECT DISTINCT t.FIO
        FROM teacher t
        JOIN canLead cl ON t.ID = cl.teacher_ID
        JOIN discipline d ON cl.discipline_code = d.code
        JOIN studyPlan sp ON d.code = sp.discipline_code
        JOIN Lead l ON t.ID = l.teacher_ID AND sp.contractNumber = l.studyPlan_contractNumber
        WHERE sp.semester % 2 = 1  -- Условие для зимней сессии (1-й, 3-й, 5-й, 7-й семестры)
          AND sp.typereporting = 1  -- Условие для экзаменов
    LOOP
        RAISE NOTICE '%', rec.FIO;
    END LOOP;
END;
$$;
CALL GetWinterExamTeachers();

select * from studyPlan;

-----б)
--Процедура, на входе получающая специальность, номер курса и семестра и формирующая список дисциплин, 
--по которым в данном семестре у этой специальности и курса стоят экзамен или зачет
CREATE OR REPLACE PROCEDURE GetDisciplinesForSemester(
    input_speciality_code INT,
    input_course INT,
    input_semester INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD; -- Объявляем переменную для хранения строки результата
BEGIN
    RAISE NOTICE 'Дисциплины для специальности % на курсе % в семестре %:', 
                 input_speciality_code, input_course, input_semester;

    FOR rec IN
        SELECT DISTINCT d.name AS discipline_name
        FROM studyPlan sp
        JOIN discipline d ON sp.discipline_code = d.code
        WHERE sp.speciality_code = input_speciality_code
          AND sp.course = input_course
          AND sp.semester = input_semester
          AND sp.typereporting = 1 or sp.typereporting = 2 -- Условие: экзамен или зачет
    LOOP
        RAISE NOTICE '%', rec.discipline_name;
    END LOOP;
END;
$$;

CALL GetDisciplinesForSemester(101, 1, 3);


--с)Процедура, на входе получающая ФИО преподавателя, выходной параметр – количество часов нагрузки за оба семестра
CREATE OR REPLACE PROCEDURE GetTeacherWorkload(
    input_teacher_fio VARCHAR(100) -- Входной параметр: ФИО преподавателя
)
LANGUAGE plpgsql
AS $$
DECLARE
    total_hours INT; -- Локальная переменная для хранения результата
BEGIN
    -- Подсчёт общего количества часов нагрузки
    SELECT COALESCE(SUM(sp.timeLecture + sp.timePractice), 0)
    INTO total_hours
    FROM teacher t
    JOIN Lead l ON t.ID = l.teacher_ID
    JOIN studyPlan sp ON l.studyPlan_contractNumber = sp.contractNumber
    WHERE t.FIO = input_teacher_fio;

    -- Выводим результат
    IF total_hours = 0 THEN
        RAISE NOTICE 'Преподаватель % не имеет нагрузки.', input_teacher_fio;
    ELSE
        RAISE NOTICE 'Преподаватель % имеет нагрузку: % часов.', input_teacher_fio, total_hours;
    END IF;
END;
$$;
CALL GetTeacherWorkload('Иванов Иван Иванович');

---------
-- d)Процедура, вызывающая вложенную процедуру, которая подсчитывает среднее количество часов в год по дисциплинам,
--   и выдающая список дисциплин с количеством часов в год меньше среднего
CREATE OR REPLACE PROCEDURE GetDisciplinesBelowAverage()
LANGUAGE plpgsql
AS $$
DECLARE
    avg_hours_per_year NUMERIC; -- Переменная для хранения среднего количества часов
	rec RECORD; -- Переменная для хранения строки в цикле
BEGIN
    -- Вызов вложенной процедуры для вычисления среднего количества часов
    CALL CalculateAverageHoursPerYear(avg_hours_per_year);

    RAISE NOTICE 'Среднее количество часов в год по всем дисциплинам: %', avg_hours_per_year;

    -- Список дисциплин с количеством часов в год меньше среднего
    FOR rec IN
        SELECT d.name AS discipline_name, (sp.timeLecture + sp.timePractice) * 2 AS total_hours
        FROM discipline d
        JOIN studyPlan sp ON d.code = sp.discipline_code
        GROUP BY d.name, sp.timeLecture, sp.timePractice
        HAVING (SUM(sp.timeLecture + sp.timePractice) * 2) < avg_hours_per_year
    LOOP
        RAISE NOTICE 'Дисциплина: %, Часы в год: %', rec.discipline_name, rec.total_hours;
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE CalculateAverageHoursPerYear(
    OUT avg_hours NUMERIC -- Выходной параметр для среднего количества часов
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Вычисление среднего количества часов в год по всем дисциплинам
    SELECT COALESCE(AVG((sp.timeLecture + sp.timePractice) * 2), 0)
    INTO avg_hours
    FROM studyPlan sp;
END;
$$;


CALL GetDisciplinesBelowAverage();




-- пользовательские ф-ции
-- а) Скалярная функция, на входе получающая ФИО преподавателя, на выходе выдающая количество наименований дисциплин,
--    которые он ведет в учебном году

CREATE OR REPLACE FUNCTION get_disciplines_count_by_teacher(
    teacher_fio VARCHAR
)
RETURNS INT AS $$
DECLARE
    discipline_count INT;
BEGIN
    SELECT 
        COUNT(DISTINCT d.name) -- Подсчет уникальных наименований дисциплин
    INTO 
        discipline_count
    FROM 
        teacher t
    INNER JOIN 
        canlead cl ON t.id = cl.teacher_id
    INNER JOIN 
        discipline d ON cl.discipline_code = d.code
    WHERE 
        t.fio = teacher_fio; -- Фильтр по ФИО преподавателя

    RETURN discipline_count; -- Возвращаемое значение
END;
$$ LANGUAGE plpgsql;

-- Пример вызова функции:
SELECT get_disciplines_count_by_teacher('Иванов Иван Иванович');




-- б)Inline-функция, возвращающая количество оценок «2» за экзамены зимней сессии по каждому курсу и специальности

CREATE OR REPLACE FUNCTION get_fail_grades_winter()
RETURNS TABLE (
    course INT,
    speciality_name VARCHAR,
    fail_count INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sp.course,
        s.name AS speciality_name,
        COUNT(shs.mark)::INT AS fail_count -- Приведение COUNT() к INT
    FROM 
        student_has_studyplan shs
     JOIN 
        studyplan sp ON shs.studyplan_contractnumber = sp.contractnumber
     JOIN 
        speciality s ON sp.speciality_code = s.code
    WHERE 
        sp.semester % 2 = 1 -- Зимний семестр (нечетные)
        AND shs.mark = '2' -- Оценка "2"
        AND sp.typereporting = 1 -- Только экзамены
    GROUP BY 
        sp.course, s.name
    ORDER BY 
        sp.course, s.name;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова:
SELECT * FROM get_fail_grades_winter();
-- код для добавления студентов которые на 2 сдали.
-- DO $$
-- DECLARE
--     max_id INT;
--     new_student_id INT;
-- BEGIN
--     -- Получаем максимальный ID из таблицы student
--     SELECT COALESCE(MAX(ID), 0) + 1 INTO max_id FROM student;

--     -- Добавляем студента с новым ID
--     INSERT INTO student (ID, FIO, course, group_ID)
--     VALUES (max_id, 'Иванов Иван Иванович23421134', 1, 1)
--     RETURNING ID INTO new_student_id;

--     -- Добавляем запись в student_has_studyPlan
--     INSERT INTO student_has_studyPlan (student_ID, studyPlan_contractNumber, mark, typeOfMark)
--     VALUES (new_student_id, 1006, '2', 'exam');
-- END;
-- $$;


--- в)Multi-statement-функция, на входе получающая название специальности, 
--номер курса и выдающая результаты экзаменов зимней сессии в виде:
--дисциплина|кол-во «5»|кол-во «4»|кол-во «2»|кол-во неявок


CREATE OR REPLACE FUNCTION get_exam_results_winter(
    speciality_name VARCHAR,
    course_number INT
)
RETURNS TABLE (
    discipline_name VARCHAR,
    count_5 INT,
    count_4 INT,
    count_2 INT,
    count_absent INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.name AS discipline_name,
        COUNT(CASE WHEN shs.mark = '5' THEN 1 END)::INT AS count_5, -- Приведение к INT
        COUNT(CASE WHEN shs.mark = '4' THEN 1 END)::INT AS count_4, -- Приведение к INT
        COUNT(CASE WHEN shs.mark = '2' THEN 1 END)::INT AS count_2, -- Приведение к INT
        COUNT(CASE WHEN shs.mark IS NULL THEN 1 END)::INT AS count_absent -- Приведение к INT
    FROM 
        student_has_studyplan shs
    RIGHT JOIN 
        studyplan sp ON shs.studyplan_contractnumber = sp.contractnumber
    LEFT JOIN 
        discipline d ON sp.discipline_code = d.code
    LEFT JOIN 
        speciality s ON sp.speciality_code = s.code
    WHERE 
        s.name = speciality_name -- Указанная специальность
        AND sp.course = course_number -- Указанный курс
        AND sp.semester % 2 = 1 -- Зимний семестр (нечетные)
        AND sp.typereporting = 1 -- Только экзамены
    GROUP BY 
        d.name
    ORDER BY 
        d.name;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова функции:
SELECT * FROM get_exam_results_winter('Информатика', 1);





