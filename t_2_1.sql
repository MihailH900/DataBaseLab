-- 2 позитивный тест
-- две непересекающиеся смены одного сотрудника в один день добавляются

DELETE FROM work_schedule
WHERE employee_id = 3
  AND work_date = DATE '2026-06-01';

INSERT INTO work_schedule (
    employee_id, bakery_id, work_date, day_of_week,
    work_start_time, work_end_time, break_start_time, break_end_time
) VALUES (
    3, 1, DATE '2026-06-01', 1,
    '07:00', '10:00', NULL, NULL
);

INSERT INTO work_schedule (
    employee_id, bakery_id, work_date, day_of_week,
    work_start_time, work_end_time, break_start_time, break_end_time
) VALUES (
    3, 1, DATE '2026-06-01', 1,
    '10:00', '12:00', NULL, NULL
);

SELECT 'Ожидалось 2 графика' AS check_name, COUNT(*) AS actual_count
FROM work_schedule
WHERE employee_id = 3
  AND work_date = DATE '2026-06-01';
