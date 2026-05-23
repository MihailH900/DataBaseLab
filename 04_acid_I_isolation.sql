/*
изолированность
Параллельные транзакции не должны неконтролируемо мешать друг другу
Степень изолированности зависит от выбранного уровня изоляции
READ COMMITTED, REPEATABLE READ, SERIALIZABLE

нужны две SQL-сессии
*/

UPDATE bakery_ingredient_stock bis
SET stock_qty_g = 1000
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

--- READ COMMITTED

-- сессия 1
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT current_setting('transaction_isolation') AS isolation_level;
SELECT bis.stock_qty_g AS session_1_first_read
FROM bakery_ingredient_stock bis
JOIN bakery b ON b.bakery_id = bis.bakery_id
JOIN ingredient i ON i.ingredient_id = bis.ingredient_id
WHERE b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

-- сессия 2
BEGIN;
UPDATE bakery_ingredient_stock bis
SET stock_qty_g = 777
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';
COMMIT;

-- сессия 1
-- второй SELECT увидит 777
SELECT bis.stock_qty_g AS session_1_second_read
FROM bakery_ingredient_stock bis
JOIN bakery b ON b.bakery_id = bis.bakery_id
JOIN ingredient i ON i.ingredient_id = bis.ingredient_id
WHERE b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';
ROLLBACK;

--- REPEATABLE READ

-- RESET
UPDATE bakery_ingredient_stock bis
SET stock_qty_g = 1000
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

-- сессия 1
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT current_setting('transaction_isolation') AS isolation_level;
SELECT bis.stock_qty_g AS session_1_first_read
FROM bakery_ingredient_stock bis
JOIN bakery b ON b.bakery_id = bis.bakery_id
JOIN ingredient i ON i.ingredient_id = bis.ingredient_id
WHERE b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

-- сессия 2
BEGIN;
UPDATE bakery_ingredient_stock bis
SET stock_qty_g = 777
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';
COMMIT;

-- сессия 1
-- второй SELECT всё ещё увидит 1000
SELECT bis.stock_qty_g AS session_1_second_read
FROM bakery_ingredient_stock bis
JOIN bakery b ON b.bakery_id = bis.bakery_id
JOIN ingredient i ON i.ingredient_id = bis.ingredient_id
WHERE b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';
ROLLBACK;

/*
Изолированность не означает, что транзакции вообще не видят друг друга
Она означает, что СУБД задаёт правила видимости параллельных изменений
На READ COMMITTED новый запрос внутри той же транзакции может увидеть новый committed-результат
На REPEATABLE READ транзакция работает с одним снимком данных
*/
