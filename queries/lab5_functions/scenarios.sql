-- Сценарии лабораторной работы №5.
-- Каждый вызов и его результат проверяются в транзакции, которая затем отменяется.
\set ON_ERROR_STOP on
\pset pager off

BEGIN;
\echo 'Сценарий 1. Все связанные сущности создаются заново'
CALL register_settlement(
    'Predovic', 'Anastasia', 'Christiana', '9999999999',
    'Lind', 'Nolan', 'Simone', '9999999998', 'Agent',
    '500 Codex Way, Sampleton, Maine 00001', 'suite', 2,
    DATE '2025-09-01', NULL,
    'card', 1500.00, DATE '2025-09-01'
);
SELECT student_id, last_name, first_name, middle_name,
       settlement_count, payment_count
FROM student_settlement_payment_counts
WHERE last_name = 'Predovic' AND first_name = 'Anastasia'
  AND middle_name = 'Christiana'
  AND student_id = (SELECT student_id FROM student WHERE passport_data = '9999999999')
ORDER BY student_id DESC LIMIT 1;

\echo 'Сценарий 2. Все связанные сущности уже существуют'
SELECT student_id, settlement_count, payment_count
FROM student_settlement_payment_counts
WHERE student_id = 2;
CALL register_settlement(
    'Predovic', 'Anastasia', 'Christiana', '4618268510',
    'Lind', 'Nolan', 'Simone', '2506250516', 'Agent',
    '38713 East Cliffsberg, Durham, Delaware 25965', 'квартирный', 3,
    DATE '2025-09-01', NULL,
    'карта', 1500.00, DATE '2025-09-01'
);
SELECT student_id, settlement_count, payment_count
FROM student_settlement_payment_counts
WHERE student_id = 2;

\echo 'Сценарий 3. Новый студент при существующих справочных сущностях'
CALL register_settlement(
    'Predovic', 'Anastasia', 'Christiana', '9999999997',
    'Lind', 'Nolan', 'Simone', '2506250516', 'Agent',
    '38713 East Cliffsberg, Durham, Delaware 25965', 'квартирный', 3,
    DATE '2025-09-01', NULL,
    'карта', 1500.00, DATE '2025-09-01'
);
SELECT student_id, last_name, first_name, middle_name,
       settlement_count, payment_count
FROM student_settlement_payment_counts
WHERE last_name = 'Predovic' AND first_name = 'Anastasia'
  AND middle_name = 'Christiana'
  AND student_id = (SELECT student_id FROM student WHERE passport_data = '9999999997')
ORDER BY student_id DESC LIMIT 1;
ROLLBACK;
