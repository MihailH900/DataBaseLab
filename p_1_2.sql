-- 1 негативный тест
-- CALL завершается ошибкой, потому что заказа 999999 нет

CALL proc_recalculate_order_total(999999);
