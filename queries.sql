--- 1
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

--- 2
WITH ingredient_usage AS (
    SELECT
        plii.ingredient_id,
        oi.order_id,
        oi.quantity::numeric AS usage_count,
        0::numeric AS topping_count
    FROM price_list_item_ingredient plii
    JOIN price_list_item pli ON pli.price_list_item_id = plii.price_list_item_id
    JOIN order_item oi ON oi.price_list_item_id = pli.price_list_item_id
    JOIN customer_order co ON co.order_id = oi.order_id
    WHERE co.status IN ('COMPLETED', 'DELIVERED')

    UNION ALL

    SELECT
        oit.ingredient_id,
        oi.order_id,
        oi.quantity::numeric AS usage_count,
        oi.quantity::numeric AS topping_count
    FROM order_item_topping oit
    JOIN order_item oi ON oi.order_item_id = oit.order_item_id
    JOIN customer_order co ON co.order_id = oi.order_id
    WHERE co.status IN ('COMPLETED', 'DELIVERED')
)
SELECT
    i.name AS "Название ингредиента",
    SUM(u.usage_count) AS "Суммарное количество использований",
    COUNT(DISTINCT u.order_id) AS "Количество заказов с ингредиентом",
    SUM(u.topping_count) AS "Количество топингов с ингредиентом"
FROM ingredient i
JOIN ingredient_usage u ON u.ingredient_id = i.ingredient_id
GROUP BY i.ingredient_id, i.name
HAVING SUM(u.usage_count) > 5
ORDER BY
    "Суммарное количество использований" DESC,
    "Количество заказов с ингредиентом" DESC,
    i.name;

--- 3
WITH employee_bakeries AS (
    SELECT employee_id, bakery_id
    FROM employee

    UNION

    SELECT employee_id, bakery_id
    FROM work_schedule
),
bakery_counts AS (
    SELECT
        employee_id,
        COUNT(DISTINCT bakery_id) AS bakery_count
    FROM employee_bakeries
    GROUP BY employee_id
),
check_stats AS (
    SELECT
        co.cashier_id AS employee_id,
        COUNT(DISTINCT co.order_id) AS check_count,
        SUM(co.order_total_amount) AS check_revenue
    FROM customer_order co
    WHERE co.status IN ('COMPLETED', 'DELIVERED')
    GROUP BY co.cashier_id
),
invoice_stats AS (
    SELECT
        inv.courier_employee_id AS employee_id,
        COUNT(DISTINCT inv.invoice_id) AS invoice_count,
        SUM(co.order_total_amount) FILTER (
            WHERE co.status = 'DELIVERED'
              AND inv.has_claim = FALSE
              AND inv.recipient_signed = TRUE
        ) AS delivered_revenue
    FROM invoice inv
    JOIN customer_order co ON co.order_id = inv.order_id
    GROUP BY inv.courier_employee_id
)
SELECT
    e.employee_id::text || ' — ' || e.full_name || ' (' || e.role_code || ')' AS "Информация о работнике",
    COALESCE(bc.bakery_count, 0) AS "Количество кондитерских, в которых он работает",
    COALESCE(inv.invoice_count, 0) AS "Количество накладных",
    COALESCE(ch.check_count, 0) AS "Количество чеков",
    COALESCE(inv.invoice_count, 0) + COALESCE(ch.check_count, 0) AS "Количество накладных и чеков",
    COALESCE(inv.delivered_revenue, 0::numeric) + COALESCE(ch.check_revenue, 0::numeric) AS "Выручка с доставленных заказов и сформированных чеков"
FROM employee e
LEFT JOIN bakery_counts bc ON bc.employee_id = e.employee_id
LEFT JOIN invoice_stats inv ON inv.employee_id = e.employee_id
LEFT JOIN check_stats ch ON ch.employee_id = e.employee_id
ORDER BY e.employee_id;

--- 4
WITH positive AS (
    SELECT
        plii.ingredient_id,
        COUNT(DISTINCT pli.product_id) AS positive_product_count,
        ROUND(AVG(plii.taste_contribution_pct), 2) AS avg_positive_impact
    FROM price_list_item_ingredient plii
    JOIN price_list_item pli ON pli.price_list_item_id = plii.price_list_item_id
    GROUP BY plii.ingredient_id
),
negative AS (
    SELECT
        at.ingredient_id,
        COUNT(DISTINCT pli.product_id) AS negative_product_count,
        ROUND(AVG(at.taste_drop_pct), 2) AS avg_negative_impact
    FROM allowed_topping at
    JOIN price_list_item pli ON pli.price_list_item_id = at.price_list_item_id
    GROUP BY at.ingredient_id
),
substitute AS (
    SELECT
        rgi.substitute_ingredient_id AS ingredient_id,
        COUNT(DISTINCT pli.product_id) AS substitute_product_count,
        ROUND(AVG(rgi.taste_drop_pct), 2) AS avg_substitute_impact
    FROM replacement_group_item rgi
    JOIN replacement_group rg ON rg.replacement_group_id = rgi.replacement_group_id
    JOIN price_list_item pli ON pli.price_list_item_id = rg.price_list_item_id
    GROUP BY rgi.substitute_ingredient_id
),
all_roles AS (
    SELECT plii.ingredient_id, pli.product_id
    FROM price_list_item_ingredient plii
    JOIN price_list_item pli ON pli.price_list_item_id = plii.price_list_item_id

    UNION

    SELECT at.ingredient_id, pli.product_id
    FROM allowed_topping at
    JOIN price_list_item pli ON pli.price_list_item_id = at.price_list_item_id

    UNION

    SELECT rgi.substitute_ingredient_id AS ingredient_id, pli.product_id
    FROM replacement_group_item rgi
    JOIN replacement_group rg ON rg.replacement_group_id = rgi.replacement_group_id
    JOIN price_list_item pli ON pli.price_list_item_id = rg.price_list_item_id
),
total_products AS (
    SELECT
        ingredient_id,
        COUNT(DISTINCT product_id) AS total_product_count
    FROM all_roles
    GROUP BY ingredient_id
),
unused_ingredients AS (
    SELECT i.ingredient_id
    FROM ingredient i
    LEFT JOIN all_roles ar ON ar.ingredient_id = i.ingredient_id
    WHERE ar.ingredient_id IS NULL
)
SELECT
    i.name AS "Название ингредиента",
    i.ingredient_id AS "Айди ингредиента",
    COALESCE(p.positive_product_count, 0) AS "Количество продукции, где положительно влияет",
    COALESCE(p.avg_positive_impact, 0::numeric) AS "Среднее положительное влияние",
    COALESCE(n.negative_product_count, 0) AS "Количество продукции, где отрицательно влияет",
    COALESCE(n.avg_negative_impact, 0::numeric) AS "Среднее отрицательное влияние",
    COALESCE(s.substitute_product_count, 0) AS "Количество продукции, где может быть заменителем",
    COALESCE(s.avg_substitute_impact, 0::numeric) AS "Среднее влияние как заменителя",
    COALESCE(tp.total_product_count, 0) AS "Суммарное количество продукции",
    CASE
        WHEN ui.ingredient_id IS NULL THEN 'используется в продукции'
        ELSE 'нет связей с продукцией'
    END AS "Статус использования"
FROM ingredient i
LEFT JOIN positive p ON p.ingredient_id = i.ingredient_id
LEFT JOIN negative n ON n.ingredient_id = i.ingredient_id
LEFT JOIN substitute s ON s.ingredient_id = i.ingredient_id
LEFT JOIN total_products tp ON tp.ingredient_id = i.ingredient_id
LEFT JOIN unused_ingredients ui ON ui.ingredient_id = i.ingredient_id
ORDER BY
    "Суммарное количество продукции" DESC,
    i.name;

--- 5
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