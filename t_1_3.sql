-- 1 негативный тест
-- последний INSERT завершается ошибкой, потому что ингредиент 1 не разрешён как топпинг для позиции прайса 1

DELETE FROM customer_order
WHERE order_type = 'TEST_TRIGGER_RUN'
  AND status = 'TOPPING_FORBIDDEN';

INSERT INTO customer_order (
    client_id, bakery_id, cashier_id,
    order_type, status, order_total_amount
) VALUES (
    1, 1, 4, 'TEST_TRIGGER_RUN', 'TOPPING_FORBIDDEN', 0
);

INSERT INTO order_item (
    order_id, price_list_item_id, quantity,
    base_price, toppings_price, line_total_amount, final_taste_pct
) VALUES (
    (SELECT MAX(order_id)
     FROM customer_order
     WHERE order_type = 'TEST_TRIGGER_RUN'
       AND status = 'TOPPING_FORBIDDEN'),
    1, 1, 320.00, 0.00, 320.00, 100.00
);

INSERT INTO order_item_topping (
    order_item_id, ingredient_id, amount_value, amount_unit,
    extra_price, taste_drop_pct_applied
) VALUES (
    (SELECT MAX(oi.order_item_id)
     FROM order_item oi
     JOIN customer_order co ON co.order_id = oi.order_id
     WHERE co.order_type = 'TEST_TRIGGER_RUN'
       AND co.status = 'TOPPING_FORBIDDEN'),
    1, 10.000, 'g', 10.00, 1.00
);
