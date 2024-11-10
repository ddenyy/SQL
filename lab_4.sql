--a) Процедура без параметров, формирующая список преподавателей, 
--   которые должны принимать экзамены в зимнюю сессию в соответствии с имеющимся учебным планом.
CREATE OR REPLACE FUNCTION get_winter_exam_teachers()
RETURNS TABLE (
    teacher_id INT,
    teacher_name VARCHAR(100),
    discipline_name VARCHAR(100),
    group_name VARCHAR(100),
    speciality_name VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS teacher_id,
        t.fio AS teacher_name,
        d.name AS discipline_name,
        g.name AS group_name,
        sp.name AS speciality_name
    FROM 
        teacher t
    INNER JOIN 
        canlead cl ON t.id = cl.teacher_id
    INNER JOIN 
        discipline d ON cl.discipline_code = d.code
    INNER JOIN 
        studyplan s ON s.discipline_code = d.code
    INNER JOIN 
        lead l ON l.teacher_id = t.id AND l.studyplan_contractnumber = s.contractnumber
    INNER JOIN 
        "group" g ON l.group_id = g.id
    INNER JOIN 
        speciality sp ON g.speciality_code = sp.code
    WHERE 
        s.semester % 2 = 1 -- Зимний семестр
        AND s.typereporting = 1; -- Тип отчетности: экзамен (предположительно)
END;
$$ LANGUAGE plpgsql;

-- Вызов функции
SELECT * FROM get_winter_exam_teachers();



-----
--Процедура, на входе получающая специальность, номер курса и семестра и формирующая список дисциплин, 
--по которым в данном семестре у этой специальности и курса стоят экзамен или зачет
CREATE OR REPLACE FUNCTION get_disciplines_by_speciality(
    function_speciality_code INT,
    function_course_number INT,
    function_semester_number INT
)
RETURNS TABLE (
    discipline_name VARCHAR,
    type_of_reporting VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.name AS discipline_name,
        CASE 
            WHEN sp.typereporting = 1 THEN 'Экзамен'::VARCHAR
            WHEN sp.typereporting = 2 THEN 'Зачет'::VARCHAR
            ELSE 'Неизвестно'::VARCHAR
        END AS type_of_reporting
    FROM 
        studyplan sp
    JOIN 
        discipline d ON sp.discipline_code = d.code
    WHERE 
        sp.speciality_code = function_speciality_code
        AND sp.course = function_course_number
        AND sp.semester = function_semester_number
        AND sp.typereporting IN (1, 2); -- 1 = Экзамен, 2 = Зачет
END;
$$ LANGUAGE plpgsql;

-- Пример вызова функции:
SELECT * FROM get_disciplines_by_speciality(1, 1, 1);

select * from public.speciality


-----------

CREATE OR REPLACE FUNCTION get_teacher_workload(
    teacher_fio VARCHAR
)
RETURNS INT AS $$
DECLARE
    total_hours INT := 0;
BEGIN
    SELECT 
        COALESCE(SUM(sp.timelecture + sp.timepractice), 0) 
    INTO 
        total_hours
    FROM 
        lead l
    INNER JOIN 
        teacher t ON l.teacher_id = t.id
    INNER JOIN 
        studyplan sp ON l.studyplan_contractnumber = sp.contractnumber
    WHERE 
        t.fio = teacher_fio;

    RETURN total_hours;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова функции:
SELECT get_teacher_workload('Иванов Иван Иванович');




---------
-- d)

CREATE OR REPLACE FUNCTION calculate_average_hours_per_year()
RETURNS NUMERIC AS $$
DECLARE
    avg_hours NUMERIC;
BEGIN
    SELECT AVG(sp.timelecture + sp.timepractice) * 2
    INTO avg_hours
    FROM studyplan sp;

    RETURN avg_hours;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_disciplines_below_average()
RETURNS TABLE (
    discipline_name VARCHAR,
    total_hours_per_year INT
) AS $$
DECLARE
    avg_hours NUMERIC;
BEGIN
    -- Вызов вложенной процедуры для получения среднего количества часов
    avg_hours := calculate_average_hours_per_year();

    -- Возвращение дисциплин с количеством часов ниже среднего
    RETURN QUERY
    SELECT 
        d.name AS discipline_name,
        (sp.timelecture + sp.timepractice) * 2 AS total_hours_per_year
    FROM 
        studyplan sp
    INNER JOIN 
        discipline d ON sp.discipline_code = d.code
    WHERE 
        (sp.timelecture + sp.timepractice) * 2 < avg_hours;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова основной процедуры:
SELECT * FROM get_disciplines_below_average();




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




-- б)

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
    INNER JOIN 
        studyplan sp ON shs.studyplan_contractnumber = sp.contractnumber
    INNER JOIN 
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


--- в)


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





