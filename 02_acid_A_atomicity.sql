/*
атомарность
Транзакция выполняется как единое целое: либо фиксируются все её успешные действия
либо не фиксируется ничего
*/

-- RESET перед сценарием.
UPDATE bakery_ingredient_stock bis
SET stock_qty_g = 1000
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

DELETE FROM activity_log
WHERE info LIKE 'ACID_TEST_ATOMICITY%';

BEGIN;

-- Успешное изменение остатка внутри транзакции
UPDATE bakery_ingredient_stock bis
SET stock_qty_g = stock_qty_g - 100
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

-- Ещё одно успешное действие внутри той же транзакции.
INSERT INTO activity_log (employee_id, action_type, info)
SELECT e.employee_id, 'ACID_TEST', 'ACID_TEST_ATOMICITY: списали 100 г'
FROM employee e
WHERE e.login = 'ACID_TEST_cashier_1';

-- ERROR: new row for relation "bakery_ingredient_stock" violates check constraint ...
UPDATE bakery_ingredient_stock bis
SET stock_qty_g = -1
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

-- неуспешная транзакция, откатываемся
ROLLBACK;

-- остаток снова будет 1000, а записей ACID_TEST_ATOMICITY нет
SELECT bis.stock_qty_g AS stock_after_rollback
FROM bakery_ingredient_stock bis
JOIN bakery b ON b.bakery_id = bis.bakery_id
JOIN ingredient i ON i.ingredient_id = bis.ingredient_id
WHERE b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

SELECT COUNT(*) AS log_rows_after_rollback
FROM activity_log
WHERE info LIKE 'ACID_TEST_ATOMICITY%';

/*
Атомарность означает, что частичный результат транзакции не должен попасть в базу
Даже если первые команды были успешны, после ROLLBACK база вернулась к состоянию до BEGIN
*/