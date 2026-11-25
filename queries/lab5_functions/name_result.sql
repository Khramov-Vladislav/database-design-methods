\set ON_ERROR_STOP on
\pset 'null' 'NULL'

BEGIN;

-- Добавляем демонстрационные записи без отчества, пропуская уже добавленные.
INSERT INTO student (last_name, first_name, middle_name, passport_data)
SELECT sample.last_name, sample.first_name, NULL, sample.passport_data
FROM (
    VALUES
        ('Predovic', 'Anastasia', 'LAB5NO001'),
        ('Miller', 'Evelyn', 'LAB5NO002'),
        ('Brooks', 'Noah', 'LAB5NO003')
) AS sample(last_name, first_name, passport_data)
WHERE NOT EXISTS (
    SELECT 1
    FROM student AS s
    WHERE s.passport_data = sample.passport_data
);

-- В одном результате сравниваем форматирование с отчеством и без него.
WITH students_with_middle AS (
    SELECT student_id, last_name, first_name, middle_name
    FROM student
    WHERE NULLIF(btrim(middle_name), '') IS NOT NULL
    ORDER BY student_id
    LIMIT 3
),
sample AS (
    SELECT student_id, last_name, first_name, middle_name
    FROM students_with_middle

    UNION ALL

    SELECT student_id, last_name, first_name, middle_name
    FROM student
    WHERE passport_data IN ('LAB5NO001', 'LAB5NO002', 'LAB5NO003')
      AND middle_name IS NULL
)
SELECT
    student_id,
    last_name,
    first_name,
    middle_name,
    format_full_name(last_name, first_name, middle_name) AS formatted_name
FROM sample
ORDER BY last_name, first_name, middle_name NULLS LAST, student_id;

COMMIT;
