-- 2 негативный тест
-- CALL завершается ошибкой, потому что позиции прайса 999999 нет

CALL proc_make_order(
    NULL,
    1,
    1,
    4,
    'TEST_PROC_RUN',
    'BAD_PRICE_ITEM',
    999999,
    1,
    NULL
);
