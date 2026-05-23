/*
Добавить минимальные тестовые данные для демонстрации ACID, уровней изоляции,
non-repeatable read, phantom read, write skew, SAVEPOINT и ROLLBACK TO SAVEPOINT

Можно запускать повторно: сначала он удаляет старые ACID_TEST_ данные,
затем вставляет их заново
*/

BEGIN;

DELETE FROM work_schedule
WHERE employee_id IN (
    SELECT employee_id
    FROM employee
    WHERE login LIKE 'ACID_TEST_%'
);

DELETE FROM activity_log
WHERE employee_id IN (
    SELECT employee_id
    FROM employee
    WHERE login LIKE 'ACID_TEST_%'
);

DELETE FROM employee
WHERE login LIKE 'ACID_TEST_%';

DELETE FROM bakery_ingredient_stock
WHERE bakery_id IN (
    SELECT bakery_id
    FROM bakery
    WHERE name = 'ACID_TEST_BAKERY'
)
OR ingredient_id IN (
    SELECT ingredient_id
    FROM ingredient
    WHERE name LIKE 'ACID_TEST_%'
);

DELETE FROM ingredient
WHERE name LIKE 'ACID_TEST_%';

DELETE FROM bakery
WHERE name = 'ACID_TEST_BAKERY';

INSERT INTO bakery (name, address, open_time, close_time, rent_cost, phone)
VALUES (
    'ACID_TEST_BAKERY',
    'Тестовый адрес для сценариев ACID',
    '08:00',
    '22:00',
    0,
    '+7-000-000-00-00'
);

INSERT INTO ingredient (
    name,
    description,
    cost_per_kg,
    cost_per_piece,
    calories_per_100g,
    calories_per_piece,
    shelf_life_days,
    can_be_weight,
    can_be_piece
)
VALUES
    (
        'ACID_TEST_STOCK_MAIN',
        'Основной ингредиент для Atomicity, Durability, non-repeatable read и SAVEPOINT',
        100,
        NULL,
        300,
        NULL,
        30,
        TRUE,
        FALSE
    ),
    (
        'ACID_TEST_PHANTOM_EXISTING',
        'Уже существующий ингредиент для phantom read',
        100,
        NULL,
        300,
        NULL,
        30,
        TRUE,
        FALSE
    ),
    (
        'ACID_TEST_PHANTOM_NEW',
        'Ингредиент, запас которого будет добавлен во второй сессии',
        100,
        NULL,
        300,
        NULL,
        30,
        TRUE,
        FALSE
    );

-- 4. Начальные остатки ингредиентов.
-- ACID_TEST_STOCK_MAIN: 1000 г
-- ACID_TEST_PHANTOM_EXISTING: 200 г
INSERT INTO bakery_ingredient_stock (
    bakery_id,
    ingredient_id,
    stock_qty_g,
    stock_qty_pcs,
    avg_daily_consumption_g,
    avg_daily_consumption_pcs
)
SELECT
    b.bakery_id,
    i.ingredient_id,
    CASE
        WHEN i.name = 'ACID_TEST_STOCK_MAIN' THEN 1000
        WHEN i.name = 'ACID_TEST_PHANTOM_EXISTING' THEN 200
    END AS stock_qty_g,
    0,
    0,
    0
FROM bakery b
JOIN ingredient i
    ON i.name IN ('ACID_TEST_STOCK_MAIN', 'ACID_TEST_PHANTOM_EXISTING')
WHERE b.name = 'ACID_TEST_BAKERY';

-- 5. Два активных кассира для write skew
-- Бизнес-правило
-- в тестовой кондитерской должен оставаться хотя бы один активный кассир
-- В схеме это правило не закреплено ограничением, поэтому возможен write skew
INSERT INTO employee (
    bakery_id,
    full_name,
    passport_no,
    role_code,
    hourly_rate,
    fixed_monthly_salary,
    courier_bonus_pct,
    min_hours_per_month,
    login,
    password_hash,
    is_active,
    hire_date
)
SELECT
    b.bakery_id,
    'ACID Test Cashier 1',
    'ACID-TEST-PASSPORT-1',
    'CASHIER',
    500,
    0,
    0,
    0,
    'ACID_TEST_cashier_1',
    'hash',
    TRUE,
    CURRENT_DATE
FROM bakery b
WHERE b.name = 'ACID_TEST_BAKERY'
UNION ALL
SELECT
    b.bakery_id,
    'ACID Test Cashier 2',
    'ACID-TEST-PASSPORT-2',
    'CASHIER',
    500,
    0,
    0,
    0,
    'ACID_TEST_cashier_2',
    'hash',
    TRUE,
    CURRENT_DATE
FROM bakery b
WHERE b.name = 'ACID_TEST_BAKERY';

COMMIT;

SELECT b.bakery_id, b.name
FROM bakery b
WHERE b.name = 'ACID_TEST_BAKERY';

SELECT i.name, bis.stock_qty_g
FROM bakery_ingredient_stock bis
JOIN bakery b ON b.bakery_id = bis.bakery_id
JOIN ingredient i ON i.ingredient_id = bis.ingredient_id
WHERE b.name = 'ACID_TEST_BAKERY'
ORDER BY i.name;

SELECT login, full_name, role_code, is_active
FROM employee
WHERE login LIKE 'ACID_TEST_%'
ORDER BY login;