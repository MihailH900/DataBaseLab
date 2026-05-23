-- 1
-- Расчёт итоговой стоимости заказа с учётом всех топпингов
-- На вход принимает номер заказа
-- Если заказа нет, формируется ошибка
-- После успешного пересчёта обновляются строки заказа и сам заказ

CREATE OR REPLACE PROCEDURE proc_recalculate_order_total(
    IN p_order_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id bigint;
    v_total numeric(12,2);
    v_item record;
    v_toppings_price numeric(12,2);
    v_taste_drop_pct numeric(5,2);
BEGIN
    -- Проверяем, существует ли такой заказ
    SELECT order_id
    INTO v_order_id
    FROM customer_order
    WHERE order_id = p_order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заказ % не найден', p_order_id;
    END IF;

    -- Пересчитываем каждую строку заказа отдельно
    FOR v_item IN
        SELECT
            oi.order_item_id,
            oi.quantity,
            pli.sale_price
        FROM order_item oi
        JOIN price_list_item pli ON pli.price_list_item_id = oi.price_list_item_id
        WHERE oi.order_id = p_order_id
    LOOP
        -- Считаем стоимость топпингов и падение вкуса для конкретной строки заказа
        SELECT
            COALESCE(SUM(extra_price), 0),
            COALESCE(SUM(taste_drop_pct_applied), 0)
        INTO v_toppings_price, v_taste_drop_pct
        FROM order_item_topping
        WHERE order_item_id = v_item.order_item_id;

        -- Обновляем строку заказа
        UPDATE order_item
        SET
            base_price = v_item.sale_price,
            toppings_price = v_toppings_price,
            line_total_amount = (v_item.sale_price + v_toppings_price) * v_item.quantity,
            final_taste_pct = GREATEST(100 - v_taste_drop_pct, 0)
        WHERE order_item_id = v_item.order_item_id;
    END LOOP;

    -- Считаем итоговую сумму заказа
    SELECT COALESCE(SUM(line_total_amount), 0)
    INTO v_total
    FROM order_item
    WHERE order_id = p_order_id;

    -- Обновляем сам заказ
    UPDATE customer_order
    SET order_total_amount = v_total
    WHERE order_id = p_order_id;

    RAISE NOTICE 'Стоимость заказа % пересчитана: %', p_order_id, v_total;
END;
$$;

-- 2
-- Оформление заказа
-- Если p_order_id = NULL, создаётся новый заказ и новая строка заказа
-- Если p_order_id задан, строка добавляется в существующий заказ
-- Если такая продукция уже есть в заказе, увеличивается количество
-- p_result_order_id — OUT-параметр, в него возвращается номер заказа

CREATE OR REPLACE PROCEDURE proc_make_order(
    IN p_order_id bigint,
    IN p_client_id bigint,
    IN p_bakery_id bigint,
    IN p_cashier_id bigint,
    IN p_order_type text,
    IN p_status text,
    IN p_price_list_item_id bigint,
    IN p_quantity integer,
    OUT p_result_order_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_item_bakery_id bigint;
    v_order_bakery_id bigint;
    v_base_price numeric(12,2);
    v_changed_count int;
BEGIN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'Количество продукции должно быть положительным';
    END IF;

    -- Проверяем что позиция прайса вообще существует (такое вообще можно заказать)
    SELECT pl.bakery_id, pli.sale_price
    INTO v_item_bakery_id, v_base_price
    FROM price_list_item pli
    JOIN price_list pl ON pl.price_list_id = pli.price_list_id
    WHERE pli.price_list_item_id = p_price_list_item_id
      AND pl.is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Позиция прайса % не найдена или прайс не активен', p_price_list_item_id;
    END IF;

    --  Создаем или новый заказ или дописываем в старый
    IF p_order_id IS NULL THEN
        IF p_client_id IS NULL OR p_bakery_id IS NULL OR p_cashier_id IS NULL
           OR p_order_type IS NULL OR p_status IS NULL THEN
            RAISE EXCEPTION 'Для нового заказа нужно передать client_id, bakery_id, cashier_id, order_type и status';
        END IF;

        IF p_bakery_id <> v_item_bakery_id THEN
            RAISE EXCEPTION 'Позиция прайса % относится к кондитерской %, а заказ создаётся для кондитерской %',
                p_price_list_item_id, v_item_bakery_id, p_bakery_id;
        END IF;

        INSERT INTO customer_order (
            client_id, bakery_id, cashier_id,
            order_type, status, order_total_amount
        ) VALUES (
            p_client_id, p_bakery_id, p_cashier_id,
            p_order_type, p_status, 0
        );

        SELECT MAX(order_id)
        INTO p_result_order_id
        FROM customer_order
        WHERE client_id = p_client_id
          AND bakery_id = p_bakery_id
          AND cashier_id = p_cashier_id
          AND order_type = p_order_type
          AND status = p_status;
    ELSE
        SELECT bakery_id
        INTO v_order_bakery_id
        FROM customer_order
        WHERE order_id = p_order_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Заказ % не найден', p_order_id;
        END IF;

        IF v_order_bakery_id <> v_item_bakery_id THEN
            RAISE EXCEPTION 'Позиция прайса % относится к кондитерской %, а заказ % относится к кондитерской %',
                p_price_list_item_id, v_item_bakery_id, p_order_id, v_order_bakery_id;
        END IF;

        p_result_order_id := p_order_id;
    END IF;

    UPDATE order_item
    SET quantity = quantity + p_quantity
    WHERE order_id = p_result_order_id
      AND price_list_item_id = p_price_list_item_id;

    GET DIAGNOSTICS v_changed_count = ROW_COUNT;

    IF v_changed_count = 0 THEN
        INSERT INTO order_item (
            order_id, price_list_item_id, quantity,
            base_price, toppings_price, line_total_amount, final_taste_pct
        ) VALUES (
            p_result_order_id, p_price_list_item_id, p_quantity,
            v_base_price, 0, v_base_price * p_quantity, 100
        );
    END IF;

    CALL proc_recalculate_order_total(p_result_order_id);

    RAISE NOTICE 'Заказ % оформлен или обновлён', p_result_order_id;
END;
$$;
