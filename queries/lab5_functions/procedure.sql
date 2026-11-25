-- Функция форматирует ФИО: Фамилия И. О.
CREATE OR REPLACE FUNCTION format_full_name(
    p_last_name TEXT,
    p_first_name TEXT,
    p_middle_name TEXT
)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT concat_ws(
        ' ',
        NULLIF(btrim(p_last_name), ''),
        CASE
            WHEN NULLIF(btrim(p_first_name), '') IS NOT NULL
            THEN upper(left(btrim(p_first_name), 1)) || '.'
        END,
        CASE
            WHEN NULLIF(btrim(p_middle_name), '') IS NOT NULL
            THEN upper(left(btrim(p_middle_name), 1)) || '.'
        END
    );
$$;

-- Процедура добавляет запись о заселении и связанном платеже.
-- Справочные сущности переиспользуются, если найдены по всем переданным атрибутам.
CREATE OR REPLACE PROCEDURE register_settlement(
    p_student_last_name TEXT,
    p_student_first_name TEXT,
    p_student_middle_name TEXT,
    p_student_passport_data TEXT,
    p_employee_last_name TEXT,
    p_employee_first_name TEXT,
    p_employee_middle_name TEXT,
    p_employee_passport_data TEXT,
    p_employee_position TEXT,
    p_building_address TEXT,
    p_room_type_name TEXT,
    p_place_level INTEGER,
    p_move_in_date DATE,
    p_move_out_date DATE,
    p_payment_method_name TEXT,
    p_payment_amount NUMERIC(10, 2),
    p_payment_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_student_id INTEGER;
    v_employee_id INTEGER;
    v_building_id INTEGER;
    v_room_type_id INTEGER;
    v_room_id INTEGER;
    v_place_id INTEGER;
    v_payment_method_id INTEGER;
    v_settlement_id INTEGER;
BEGIN
    SELECT student_id INTO v_student_id
    FROM student
    WHERE last_name IS NOT DISTINCT FROM p_student_last_name
      AND first_name IS NOT DISTINCT FROM p_student_first_name
      AND middle_name IS NOT DISTINCT FROM p_student_middle_name
      AND passport_data IS NOT DISTINCT FROM p_student_passport_data
    ORDER BY student_id LIMIT 1;
    IF v_student_id IS NULL THEN
        INSERT INTO student (last_name, first_name, middle_name, passport_data)
        VALUES (p_student_last_name, p_student_first_name, p_student_middle_name, p_student_passport_data)
        RETURNING student_id INTO v_student_id;
    END IF;

    -- Сводная таблица из лабораторной №2 не имеет триггера на вставку студента.
    -- Добавляем начальную строку, чтобы последующие триггеры обновили счетчики.
    INSERT INTO student_settlement_payment_counts
        (student_id, last_name, first_name, middle_name, settlement_count, payment_count)
    SELECT v_student_id, p_student_last_name, p_student_first_name,
           p_student_middle_name, 0, 0
    ON CONFLICT (student_id) DO NOTHING;

    SELECT employee_id INTO v_employee_id
    FROM employee
    WHERE last_name IS NOT DISTINCT FROM p_employee_last_name
      AND first_name IS NOT DISTINCT FROM p_employee_first_name
      AND middle_name IS NOT DISTINCT FROM p_employee_middle_name
      AND passport_data IS NOT DISTINCT FROM p_employee_passport_data
      AND position IS NOT DISTINCT FROM p_employee_position
    ORDER BY employee_id LIMIT 1;
    IF v_employee_id IS NULL THEN
        INSERT INTO employee (last_name, first_name, middle_name, passport_data, position)
        VALUES (p_employee_last_name, p_employee_first_name, p_employee_middle_name,
                p_employee_passport_data, p_employee_position)
        RETURNING employee_id INTO v_employee_id;
    END IF;

    SELECT building_id INTO v_building_id
    FROM building WHERE building_address IS NOT DISTINCT FROM p_building_address
    ORDER BY building_id LIMIT 1;
    IF v_building_id IS NULL THEN
        INSERT INTO building (building_address) VALUES (p_building_address)
        RETURNING building_id INTO v_building_id;
    END IF;

    SELECT room_type_id INTO v_room_type_id
    FROM room_type WHERE type_name IS NOT DISTINCT FROM p_room_type_name
    ORDER BY room_type_id LIMIT 1;
    IF v_room_type_id IS NULL THEN
        INSERT INTO room_type (type_name) VALUES (p_room_type_name)
        RETURNING room_type_id INTO v_room_type_id;
    END IF;

    SELECT room_id INTO v_room_id FROM room
    WHERE building_id = v_building_id AND room_type_id = v_room_type_id
    ORDER BY room_id LIMIT 1;
    IF v_room_id IS NULL THEN
        INSERT INTO room (building_id, room_type_id)
        VALUES (v_building_id, v_room_type_id)
        RETURNING room_id INTO v_room_id;
    END IF;

    SELECT place_id INTO v_place_id FROM place
    WHERE room_id = v_room_id AND level = p_place_level
    ORDER BY place_id LIMIT 1;
    IF v_place_id IS NULL THEN
        INSERT INTO place (room_id, level) VALUES (v_room_id, p_place_level)
        RETURNING place_id INTO v_place_id;
    END IF;

    SELECT payment_method_id INTO v_payment_method_id
    FROM payment_method WHERE method_name IS NOT DISTINCT FROM p_payment_method_name
    ORDER BY payment_method_id LIMIT 1;
    IF v_payment_method_id IS NULL THEN
        INSERT INTO payment_method (method_name) VALUES (p_payment_method_name)
        RETURNING payment_method_id INTO v_payment_method_id;
    END IF;

    INSERT INTO settlement (student_id, employee_id, place_id, move_in_date, move_out_date)
    VALUES (v_student_id, v_employee_id, v_place_id, p_move_in_date, p_move_out_date)
    RETURNING settlement_id INTO v_settlement_id;

    INSERT INTO payment (settlement_id, payment_method_id, payment_amount, payment_date)
    VALUES (v_settlement_id, v_payment_method_id, p_payment_amount, p_payment_date);
END;
$$;
