-- 1 позитивный тест
-- топпинг добавляется, остаток малины уменьшается с 1000 до 976 г

DELETE FROM customer_order
WHERE order_type = 'TEST_TRIGGER_RUN'
  AND status = 'TOPPING_OK';

DELETE FROM bakery_ingredient_stock
WHERE bakery_id = 1 AND ingredient_id = 8;

INSERT INTO bakery_ingredient_stock (
    bakery_id, ingredient_id, stock_qty_g, stock_qty_pcs,
    avg_daily_consumption_g, avg_daily_consumption_pcs
) VALUES (
    1, 8, 1000.000, 0, 0.000, 0
);

INSERT INTO customer_order (
    client_id, bakery_id, cashier_id,
    order_type, status, order_total_amount
) VALUES (
    1, 1, 4, 'TEST_TRIGGER_RUN', 'TOPPING_OK', 0
);

INSERT INTO order_item (
    order_id, price_list_item_id, quantity,
    base_price, toppings_price, line_total_amount, final_taste_pct
) VALUES (
    (SELECT MAX(order_id)
     FROM customer_order
     WHERE order_type = 'TEST_TRIGGER_RUN'
       AND status = 'TOPPING_OK'),
    1, 2, 320.00, 0.00, 640.00, 100.00
);

INSERT INTO order_item_topping (
    order_item_id, ingredient_id, amount_value, amount_unit,
    extra_price, taste_drop_pct_applied
) VALUES (
    (SELECT MAX(oi.order_item_id)
     FROM order_item oi
     JOIN customer_order co ON co.order_id = oi.order_id
     WHERE co.order_type = 'TEST_TRIGGER_RUN'
       AND co.status = 'TOPPING_OK'),
    8, 12.000, 'g', 70.00, 6.00
);

SELECT 'Ожидалось 976.000 г' AS check_name, stock_qty_g AS actual_stock_g
FROM bakery_ingredient_stock
WHERE bakery_id = 1 AND ingredient_id = 8;
