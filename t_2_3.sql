-- 2 негативный тест
-- INSERT завершается ошибкой, потому что смена начинается раньше допустимой рамки
-- Кондитерская 1 работает с 08:00, допустимое начало не раньше 07:00

DELETE FROM work_schedule
WHERE employee_id = 3
  AND work_date = DATE '2026-06-03';

INSERT INTO work_schedule (
    employee_id, bakery_id, work_date, day_of_week,
    work_start_time, work_end_time, break_start_time, break_end_time
) VALUES (
    3, 1, DATE '2026-06-03', 3,
    '06:30', '09:00', NULL, NULL
);
