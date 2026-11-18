SELECT
    student_id,
    last_name,
    first_name,
    middle_name,
    format_full_name(last_name, first_name, middle_name) AS formatted_name
FROM student
ORDER BY student_id
LIMIT 15;

-- Проверка результата, если отчество отсутствует.
SELECT format_full_name('Predovic', 'Anastasia', NULL) AS name_without_middle;
