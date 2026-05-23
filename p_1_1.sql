-- Процедура 1, позитивный тест.
-- Ожидаемый результат: заказ 1 пересчитывается обратно к сумме 380.00.

UPDATE order_item
SET base_price = 1,
    toppings_price = 1,
    line_total_amount = 1,
    final_taste_pct = 1
WHERE order_item_id = 1;

UPDATE customer_order
SET order_total_amount = 1
WHERE order_id = 1;

CALL proc_recalculate_order_total(1);

SELECT 'Строка заказа: ожидалось 380.00' AS check_name, line_total_amount AS actual_value
FROM order_item
WHERE order_item_id = 1;

SELECT 'Заказ: ожидалось 380.00' AS check_name, order_total_amount AS actual_value
FROM customer_order
WHERE order_id = 1;
