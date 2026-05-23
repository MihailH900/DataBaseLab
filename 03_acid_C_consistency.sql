/*
согласованность
Транзакция переводит базу из одного корректного состояния в другое корректное состояние
Корректность поддерживается ограничениями схемы: CHECK, FOREIGN KEY, UNIQUE, NOT NULL и т.д.
*/

UPDATE bakery_ingredient_stock bis
SET stock_qty_g = 1000
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

BEGIN;

-- ошибка: нарушается CHECK (stock_qty_g >= 0)
UPDATE bakery_ingredient_stock bis
SET stock_qty_g = -500
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

-- делаем откат после ошибки
ROLLBACK;

-- проверка: отрицательное значение не попало в таблицу
SELECT bis.stock_qty_g AS stock_after_check_violation
FROM bakery_ingredient_stock bis
JOIN bakery b ON b.bakery_id = bis.bakery_id
JOIN ingredient i ON i.ingredient_id = bis.ingredient_id
WHERE b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

BEGIN;

-- ошибка: bakery_id = -999999 не существует в таблице bakery
INSERT INTO bakery_ingredient_stock (
    bakery_id,
    ingredient_id,
    stock_qty_g,
    stock_qty_pcs,
    avg_daily_consumption_g,
    avg_daily_consumption_pcs
)
SELECT
    -999999,
    i.ingredient_id,
    100,
    0,
    0,
    0
FROM ingredient i
WHERE i.name = 'ACID_TEST_STOCK_MAIN';

ROLLBACK;

-- проверка: строки с несуществующей кондитерской нет
SELECT COUNT(*) AS invalid_fk_rows
FROM bakery_ingredient_stock
WHERE bakery_id = -999999;

/*
Согласованность обеспечивается не самой транзакцией, а правилами схемы
Если команда нарушает CHECK или FOREIGN KEY, PostgreSQL не даёт базе перейти
в некорректное состояние
*/
