-- 2 позитивный тест
-- создаётся новый заказ и одна строка заказа.

DELETE FROM customer_order
WHERE order_type = 'TEST_PROC_RUN'
  AND status = 'NEW_ORDER';

CALL proc_make_order(
    NULL,
    1,
    1,
    4,
    'TEST_PROC_RUN',
    'NEW_ORDER',
    1,
    2,
    NULL
);

SELECT 'Ожидался 1 заказ' AS check_name, COUNT(*) AS actual_orders
FROM customer_order
WHERE order_type = 'TEST_PROC_RUN'
  AND status = 'NEW_ORDER';

SELECT 'Ожидалась 1 строка заказа с количеством 2' AS check_name,
       COUNT(*) AS actual_items,
       SUM(quantity) AS actual_quantity
FROM order_item oi
JOIN customer_order co ON co.order_id = oi.order_id
WHERE co.order_type = 'TEST_PROC_RUN'
  AND co.status = 'NEW_ORDER'
  AND oi.price_list_item_id = 1;
