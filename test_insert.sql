INSERT INTO bakery (
    bakery_id, name, address, open_time, close_time, rent_cost, phone
) OVERRIDING SYSTEM VALUE VALUES (
    1,
    'Кондитерская Арбат',
    'г. Москва, ул. Арбат, д. 10',
    '08:00',
    '21:00',
    120000.00,
    '+7-900-111-22-33'
);

INSERT INTO client (
    client_id, full_name, phone, email, default_delivery_address
) OVERRIDING SYSTEM VALUE VALUES (
    1,
    'Иванов Алексей Сергеевич',
    '+7-900-222-33-44',
    'ivanov.alexey@example.com',
    'г. Москва, ул. Тверская, д. 15'
);

INSERT INTO employee (
    employee_id, bakery_id, full_name, passport_no, role_code,
    hourly_rate, fixed_monthly_salary, courier_bonus_pct,
    min_hours_per_month, login, password_hash, is_active, hire_date
) OVERRIDING SYSTEM VALUE VALUES
(
    1, 1,
    'Петров Сергей Иванович',
    '4501 123456',
    'OWNER',
    0.00,
    180000.00,
    0.00,
    0.00,
    'owner_1',
    'hash_owner_1',
    TRUE,
    '2024-01-10'
),
(
    2, 1,
    'Смирнова Анна Павловна',
    '4502 123457',
    'CHEF',
    900.00,
    30000.00,
    0.00,
    150.00,
    'chef_1',
    'hash_chef_1',
    TRUE,
    '2024-01-15'
),
(
    3, 1,
    'Кузнецова Мария Ивановна',
    '4503 123458',
    'CONFECTIONER',
    550.00,
    12000.00,
    0.00,
    160.00,
    'confectioner_1',
    'hash_confectioner_1',
    TRUE,
    '2024-02-01'
),
(
    4, 1,
    'Васильев Дмитрий Сергеевич',
    '4504 123459',
    'CASHIER',
    380.00,
    18000.00,
    0.00,
    150.00,
    'cashier_1',
    'hash_cashier_1',
    TRUE,
    '2024-02-05'
),
(
    5, 1,
    'Орлов Михаил Андреевич',
    '4505 123460',
    'COURIER',
    250.00,
    35000.00,
    4.50,
    140.00,
    'courier_1',
    'hash_courier_1',
    TRUE,
    '2024-02-10'
);

INSERT INTO work_schedule (
    employee_id, bakery_id, work_date, day_of_week,
    work_start_time, work_end_time,
    break_start_time, break_end_time
) VALUES
(1, 1, CURRENT_DATE, EXTRACT(ISODOW FROM CURRENT_DATE)::smallint, '10:00', '18:00', '13:00', '14:00'),
(2, 1, CURRENT_DATE, EXTRACT(ISODOW FROM CURRENT_DATE)::smallint, '07:00', '15:00', '11:00', '11:30'),
(3, 1, CURRENT_DATE, EXTRACT(ISODOW FROM CURRENT_DATE)::smallint, '08:00', '16:00', '12:00', '12:30'),
(4, 1, CURRENT_DATE, EXTRACT(ISODOW FROM CURRENT_DATE)::smallint, '09:00', '18:00', '13:30', '14:00'),
(5, 1, CURRENT_DATE, EXTRACT(ISODOW FROM CURRENT_DATE)::smallint, '10:00', '19:00', '14:00', '14:30');

INSERT INTO ingredient (
    ingredient_id, name, description, cost_per_kg, cost_per_piece,
    calories_per_100g, calories_per_piece, shelf_life_days,
    can_be_weight, can_be_piece
) OVERRIDING SYSTEM VALUE VALUES
(1, 'Мука', 'Пшеничная мука', 70.00, NULL, 364.00, NULL, 180, TRUE, FALSE),
(2, 'Сахар', 'Белый сахар', 85.00, NULL, 399.00, NULL, 365, TRUE, FALSE),
(3, 'Яйцо', 'Куриное яйцо', NULL, 12.00, NULL, 78.00, 25, FALSE, TRUE),
(4, 'Молоко', 'Молоко 3.2%', 95.00, NULL, 60.00, NULL, 7, TRUE, FALSE),
(5, 'Сливки', 'Сливки 33%', 420.00, NULL, 340.00, NULL, 10, TRUE, FALSE),
(6, 'Шоколад', 'Тёмный шоколад', 980.00, NULL, 545.00, NULL, 180, TRUE, FALSE),
(7, 'Ваниль', 'Ванильный сахар', 2500.00, NULL, 288.00, NULL, 365, TRUE, FALSE),
(8, 'Малина', 'Свежая малина', 650.00, NULL, 52.00, NULL, 3, TRUE, FALSE);

INSERT INTO utensil (
    utensil_id, name, description
) OVERRIDING SYSTEM VALUE VALUES
(1, 'Миксер', 'Планетарный миксер'),
(2, 'Духовка', 'Пекарская духовка'),
(3, 'Кондитерский мешок', 'Для крема и начинок');

-- 7. Магазин
INSERT INTO store (
    store_id, name, address, phone
) OVERRIDING SYSTEM VALUE VALUES
(
    1,
    'Фермерский рынок Покровка',
    'г. Москва, ул. Покровка, д. 8',
    '+7-900-333-44-55'
);

INSERT INTO store_ingredient_assortment (
    store_id, ingredient_id, price_per_kg, price_per_piece, stock_qty_g, stock_qty_pcs
) VALUES
(1, 1, 75.00, NULL, 50000.000, 0),
(1, 2, 90.00, NULL, 50000.000, 0),
(1, 3, NULL, 13.00, 0.000, 300),
(1, 4, 100.00, NULL, 30000.000, 0);

INSERT INTO store_utensil_assortment (
    store_id, utensil_id, price_amount, stock_qty
) VALUES
(1, 1, 4500.00, 3),
(1, 2, 25000.00, 1);

INSERT INTO bakery_ingredient_stock (
    bakery_id, ingredient_id, stock_qty_g, stock_qty_pcs,
    avg_daily_consumption_g, avg_daily_consumption_pcs
) VALUES
(1, 1, 6000.000, 0, 250.000, 0),
(1, 2, 4000.000, 0, 180.000, 0),
(1, 3, 0.000, 60, 0.000, 8),
(1, 5, 2500.000, 0, 120.000, 0);

INSERT INTO bakery_utensil_inventory (
    bakery_id, utensil_id, qty_available, condition_status
) VALUES
(1, 1, 1, 'good'),
(1, 2, 1, 'good'),
(1, 3, 2, 'good');

-- 12. Продукт
INSERT INTO product (
    product_id, chef_id, name, recipe_description, is_active
) OVERRIDING SYSTEM VALUE VALUES (
    1,
    2,
    'Эклер ванильный',
    'Эклер с ванильным кремом',
    TRUE
);

INSERT INTO product_utensil (
    product_id, utensil_id, usage_note
) VALUES
(1, 1, 'Для крема'),
(1, 2, 'Для выпечки'),
(1, 3, 'Для начинки');

INSERT INTO price_list (
    price_list_id, bakery_id, name, valid_from, valid_to, is_active
) OVERRIDING SYSTEM VALUE VALUES (
    1,
    1,
    'Основной прайс',
    CURRENT_DATE,
    NULL,
    TRUE
);

-- 15. Позиция прайса
INSERT INTO price_list_item (
    price_list_item_id, price_list_id, product_id, item_code, sale_price, prep_time_minutes, calories_kcal
) OVERRIDING SYSTEM VALUE VALUES (
    1,
    1,
    1,
    'ECLAIR-001',
    320.00,
    25,
    420.00
);

INSERT INTO price_list_item_ingredient (
    price_list_item_id, ingredient_id, amount_value, amount_unit, taste_contribution_pct
) VALUES
(1, 1, 60.000, 'g', 20.00),
(1, 3, 2.000, 'pcs', 20.00),
(1, 4, 80.000, 'g', 15.00),
(1, 5, 40.000, 'g', 20.00),
(1, 2, 20.000, 'g', 10.00),
(1, 7, 3.000, 'g', 15.00);

INSERT INTO allowed_topping (
    price_list_item_id, ingredient_id, default_amount, amount_unit, extra_price, taste_drop_pct
) VALUES
(1, 6, 10.000, 'g', 60.00, 7.00),
(1, 8, 12.000, 'g', 70.00, 6.00);

INSERT INTO replacement_group (
    replacement_group_id, price_list_item_id, group_name, comment
) OVERRIDING SYSTEM VALUE VALUES (
    1,
    1,
    'Замена кремовой основы',
    'Замена для эклера'
);

INSERT INTO replacement_group_item (
    replacement_group_id, base_ingredient_id, substitute_ingredient_id, taste_drop_pct
) VALUES
(1, 5, 4, 10.00);

INSERT INTO customer_order (
    order_id, client_id, bakery_id, cashier_id, order_datetime,
    order_type, status, order_total_amount
) OVERRIDING SYSTEM VALUE VALUES (
    1,
    1,
    1,
    4,
    NOW(),
    'DELIVERY',
    'DELIVERED',
    380.00
);

INSERT INTO order_item (
    order_item_id, order_id, price_list_item_id, quantity,
    base_price, toppings_price, line_total_amount, final_taste_pct
) OVERRIDING SYSTEM VALUE VALUES (
    1,
    1,
    1,
    1,
    320.00,
    60.00,
    380.00,
    93.00
);

INSERT INTO order_item_topping (
    order_item_id, ingredient_id, amount_value, amount_unit,
    extra_price, taste_drop_pct_applied
) VALUES
(1, 6, 10.000, 'g', 60.00, 7.00);

INSERT INTO invoice (
    invoice_id, order_id, courier_employee_id, recipient_fio,
    delivery_address, delivery_due_at, delivered_at,
    recipient_signed, claim_text, has_claim
) OVERRIDING SYSTEM VALUE VALUES (
    1,
    1,
    5,
    'Иванов Алексей Сергеевич',
    'г. Москва, ул. Тверская, д. 15',
    NOW() + INTERVAL '2 hour',
    NOW() + INTERVAL '1 hour 40 minute',
    TRUE,
    NULL,
    FALSE
);

INSERT INTO activity_log (
    log_id, employee_id, action_type, action_at, info
) OVERRIDING SYSTEM VALUE VALUES
(1, 1, 'CREATE_PRICE_LIST', NOW(), 'Создан основной прайс'),
(2, 2, 'CREATE_RECIPE_SET', NOW(), 'Создан продукт Эклер ванильный'),
(3, 4, 'CREATE_ORDER', NOW(), 'Создан заказ на доставку'),
(4, 5, 'PROCESS_DELIVERY', NOW(), 'Оформлена накладная');

SELECT * FROM bakery;
SELECT * FROM employee;
SELECT * FROM product;
SELECT * FROM price_list_item;
SELECT * FROM customer_order;
SELECT * FROM order_item;
SELECT * FROM invoice;
