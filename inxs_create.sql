DROP INDEX IF EXISTS idx_co_done_order_cover;
DROP INDEX IF EXISTS idx_oi_order_cover;

CREATE INDEX idx_co_done_order_cover
ON customer_order (order_id)
INCLUDE (bakery_id)
WHERE status IN ('COMPLETED', 'DELIVERED');

CREATE INDEX idx_oi_order_cover
ON order_item (order_id)
INCLUDE (price_list_item_id, quantity, line_total_amount);

EXPLAIN (ANALYZE, BUFFERS)
WITH order_stats AS (
    SELECT
        co.bakery_id,
        COUNT(DISTINCT co.order_id) AS order_count,
        SUM(co.order_total_amount) AS bakery_income,
        COUNT(DISTINCT co.client_id) AS client_count
    FROM customer_order co
    WHERE co.status IN ('COMPLETED', 'DELIVERED')
    GROUP BY co.bakery_id
),
ingredient_stats AS (
    SELECT
        bis.bakery_id,
        COUNT(DISTINCT bis.ingredient_id) AS ingredient_count
    FROM bakery_ingredient_stock bis
    GROUP BY bis.bakery_id
)
SELECT
    b.bakery_id AS "Номер кондитерской",
    b.address AS "Адрес кондитерской",
    b.rent_cost AS "Стоимость аренды",
    COALESCE(os.order_count, 0) AS "Количество заказов",
    COALESCE(os.bakery_income, 0::numeric) AS "Доход кондитерской",
    COALESCE(os.client_count, 0) AS "Количество клиентов",
    COALESCE(ins.ingredient_count, 0) AS "Количество ингредиентов"
FROM bakery b
LEFT JOIN order_stats os ON os.bakery_id = b.bakery_id
LEFT JOIN ingredient_stats ins ON ins.bakery_id = b.bakery_id
ORDER BY b.bakery_id;

---
EXPLAIN (ANALYZE, BUFFERS)
WITH product_names AS (
    SELECT DISTINCT
        p.name AS product_name
    FROM product p
),

product_ingredient_count AS (
    SELECT
        p.name AS product_name,
        COUNT(DISTINCT plii.ingredient_id) AS ingredient_count
    FROM product p
    JOIN price_list_item pli
        ON pli.product_id = p.product_id
    JOIN price_list_item_ingredient plii
        ON plii.price_list_item_id = pli.price_list_item_id
    GROUP BY p.name
),

product_utensil_count AS (
    SELECT
        p.name AS product_name,
        COUNT(DISTINCT pu.utensil_id) AS utensil_count
    FROM product p
    JOIN product_utensil pu
        ON pu.product_id = p.product_id
    GROUP BY p.name
),

product_order_quantities AS (
    SELECT
        p.name AS product_name,
        co.order_id,
        co.bakery_id,
        SUM(oi.quantity) AS product_qty_in_order,
        SUM(oi.line_total_amount) AS product_revenue_in_order
    FROM order_item oi
    JOIN customer_order co
        ON co.order_id = oi.order_id
    JOIN price_list_item pli
        ON pli.price_list_item_id = oi.price_list_item_id
    JOIN product p
        ON p.product_id = pli.product_id
    WHERE co.status IN ('COMPLETED', 'DELIVERED')
    GROUP BY
        p.name,
        co.order_id,
        co.bakery_id
),

product_order_stats AS (
    SELECT
        product_name,
        COUNT(DISTINCT order_id) AS order_count,
        ROUND(AVG(product_qty_in_order::numeric), 2) AS avg_qty_per_order,
        SUM(product_revenue_in_order) AS total_revenue,
        COUNT(DISTINCT bakery_id) AS sold_bakery_count
    FROM product_order_quantities
    GROUP BY product_name
),

current_bakery_products AS (
    SELECT DISTINCT
        p.name AS product_name,
        pl.bakery_id
    FROM product p
    JOIN price_list_item pli
        ON pli.product_id = p.product_id
    JOIN price_list pl
        ON pl.price_list_id = pli.price_list_id
    WHERE p.is_active = TRUE
      AND pl.is_active = TRUE
      AND pl.valid_from <= CURRENT_DATE
      AND (pl.valid_to IS NULL OR pl.valid_to >= CURRENT_DATE)
),

current_bakery_stats AS (
    SELECT
        product_name,
        COUNT(DISTINCT bakery_id) AS current_bakery_count
    FROM current_bakery_products
    GROUP BY product_name
),

product_report AS (
    SELECT
        pn.product_name,
        COALESCE(pic.ingredient_count, 0) AS ingredient_count,
        COALESCE(puc.utensil_count, 0) AS utensil_count,
        COALESCE(pos.order_count, 0) AS order_count,
        COALESCE(pos.avg_qty_per_order, 0::numeric) AS avg_qty_per_order,
        COALESCE(pos.total_revenue, 0::numeric) AS total_revenue,
        COALESCE(pos.sold_bakery_count, 0) AS sold_bakery_count,
        COALESCE(cbs.current_bakery_count, 0) AS current_bakery_count
    FROM product_names pn
    LEFT JOIN product_ingredient_count pic
        ON pic.product_name = pn.product_name
    LEFT JOIN product_utensil_count puc
        ON puc.product_name = pn.product_name
    LEFT JOIN product_order_stats pos
        ON pos.product_name = pn.product_name
    LEFT JOIN current_bakery_stats cbs
        ON cbs.product_name = pn.product_name
)

SELECT
    product_name AS "Название продукции",
    ingredient_count AS "Количество используемых ингредиентов",
    utensil_count AS "Количество используемой утвари",
    order_count AS "Количество заказов с данной продукцией",
    avg_qty_per_order AS "Среднее штук в одном заказе",
    total_revenue AS "Суммарная выручка с продажи продукции",
    sold_bakery_count AS "Количество кондитерских, где продукция продавалась",
    current_bakery_count AS "Количество кондитерских, где продукция продается сейчас",

    SUM(total_revenue) OVER (
        ORDER BY total_revenue DESC, product_name
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS "Сумма выручки за 3 позиции рейтинга",

    total_revenue - LAG(total_revenue) OVER (
        ORDER BY total_revenue DESC, product_name
    ) AS "Разница с предыдущей продукцией по выручке"

FROM product_report
ORDER BY
    total_revenue DESC,
    product_name;



Как произошло ускорение:
прочитать большую таблицу customer_order
для каждой строки проверить status
ненужные строки выбросить
оставшиеся сгруппировать по bakery_id
после
Index Scan using idx_lab_co_done_order_cover on customer_order co
actual rows=9684
Теперь PostgreSQL не читает всю таблицу заказов, а идёт в частичный индекс, где уже лежат только нужные статусы

в пятом
Parallel Hash Join
  -> Parallel Seq Scan on order_item oi
  -> Parallel Seq Scan on customer_order co
то есть читали
order_item почти целиком
customer_order почти целиком
И строилось хеш соединение

А после стало так
Parallel Bitmap Heap Scan on customer_order co
  -> Bitmap Index Scan on idx_lab_co_done_order_cover

Nested Loop
  -> customer_order co
  -> Index Only Scan using idx_lab_oi_order_cover on order_item oi
       Index Cond: (order_id = co.order_id)
1. Через частичный индекс найти завершённые/доставленные заказы
2. Для каждого такого заказа найти его позиции в order_item по order_id
3. Из индекса order_item сразу взять price_list_item_id, quantity, line_total_amount

