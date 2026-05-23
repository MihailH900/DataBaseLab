/*
долговечность
Если транзакция успешно завершилась COMMIT, результат должен сохраниться в базе
Он не должен исчезнуть после закрытия SQL-окна, переподключения к БД или запуска нового SELECT

Выполняем COMMIT
Закрываем текущую сессию или открываем новую
Видим зафиксированное значение
Запускается в одной сессии + затем проверяется в новой сессии
*/

-- RESET
UPDATE bakery_ingredient_stock bis
SET stock_qty_g = 1000
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

-- сессия 1 - фиксируем новое значение
BEGIN;
UPDATE bakery_ingredient_stock bis
SET stock_qty_g = 1234
FROM bakery b, ingredient i
WHERE bis.bakery_id = b.bakery_id
  AND bis.ingredient_id = i.ingredient_id
  AND b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';
COMMIT;

-- сессия 1 - рроверка сразу после COMMIT
SELECT bis.stock_qty_g AS value_after_commit
FROM bakery_ingredient_stock bis
JOIN bakery b ON b.bakery_id = bis.bakery_id
JOIN ingredient i ON i.ingredient_id = bis.ingredient_id
WHERE b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

-- сессия 2
-- выполенине заново уже после переподключения
-- осталось 1234
SELECT bis.stock_qty_g AS value_after_reconnect
FROM bakery_ingredient_stock bis
JOIN bakery b ON b.bakery_id = bis.bakery_id
JOIN ingredient i ON i.ingredient_id = bis.ingredient_id
WHERE b.name = 'ACID_TEST_BAKERY'
  AND i.name = 'ACID_TEST_STOCK_MAIN';

/*
До COMMIT изменение является временным и может быть отменено ROLLBACK
После COMMIT изменение становится частью состояния базы и видимо новым подключениям
*/
