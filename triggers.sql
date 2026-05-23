-- 1
-- При добавлении нового топпинга к строке заказа проверяет склад и уменьшает остаток нужного ингредиента

CREATE OR REPLACE FUNCTION trg_decrease_stock_on_topping_insert()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_bakery_id bigint;
    v_price_list_item_id bigint;
    v_quantity integer;
    v_allowed_ingredient_id bigint;
    v_required_g numeric(12,3);
    v_required_pcs integer;
    v_stock_g numeric(12,3);
    v_stock_pcs integer;
BEGIN
    -- Выбираем заказ в который будем вставлять топинг и сразу достаем кондитерскую
    SELECT co.bakery_id, oi.price_list_item_id, oi.quantity
    INTO v_bakery_id, v_price_list_item_id, v_quantity
    FROM order_item oi
    JOIN customer_order co ON co.order_id = oi.order_id
    WHERE oi.order_item_id = NEW.order_item_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Строка заказа % не найдена', NEW.order_item_id;
    END IF;

    -- Проверяем можно ли такой топинг вообще добавить
    SELECT atp.ingredient_id
    INTO v_allowed_ingredient_id
    FROM allowed_topping atp
    WHERE atp.price_list_item_id = v_price_list_item_id
      AND atp.ingredient_id = NEW.ingredient_id
      AND atp.amount_unit = NEW.amount_unit;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Топпинг % не разрешён для позиции прайса % или указана неверная единица измерения',
            NEW.ingredient_id, v_price_list_item_id;
    END IF;

    -- Может быть в граммах или в штуках, смотрим хватает ли на складе и если да уменьшаем, иначе падаем с ошибкой
    IF NEW.amount_unit = 'g' THEN
        v_required_g := NEW.amount_value * v_quantity;

        SELECT stock_qty_g
        INTO v_stock_g
        FROM bakery_ingredient_stock
        WHERE bakery_id = v_bakery_id
          AND ingredient_id = NEW.ingredient_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Топпинг % отсутствует на складе кондитерской %',
                NEW.ingredient_id, v_bakery_id;
        END IF;

        IF v_stock_g < v_required_g THEN
            RAISE EXCEPTION 'Недостаточно топпинга % на складе кондитерской %. Нужно % г, доступно % г',
                NEW.ingredient_id, v_bakery_id, v_required_g, v_stock_g;
        END IF;

        UPDATE bakery_ingredient_stock
        SET stock_qty_g = stock_qty_g - v_required_g
        WHERE bakery_id = v_bakery_id
          AND ingredient_id = NEW.ingredient_id;

    ELSIF NEW.amount_unit = 'pcs' THEN
        v_required_pcs := (NEW.amount_value * v_quantity)::integer;

        SELECT stock_qty_pcs
        INTO v_stock_pcs
        FROM bakery_ingredient_stock
        WHERE bakery_id = v_bakery_id
          AND ingredient_id = NEW.ingredient_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Топпинг % отсутствует на складе кондитерской %',
                NEW.ingredient_id, v_bakery_id;
        END IF;

        IF v_stock_pcs < v_required_pcs THEN
            RAISE EXCEPTION 'Недостаточно топпинга % на складе кондитерской %. Нужно % шт., доступно % шт.',
                NEW.ingredient_id, v_bakery_id, v_required_pcs, v_stock_pcs;
        END IF;

        UPDATE bakery_ingredient_stock
        SET stock_qty_pcs = stock_qty_pcs - v_required_pcs
        WHERE bakery_id = v_bakery_id
          AND ingredient_id = NEW.ingredient_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_decrease_stock_on_topping_insert
BEFORE INSERT ON order_item_topping
FOR EACH ROW
EXECUTE FUNCTION trg_decrease_stock_on_topping_insert();

-- 2
-- При добавления графика работы проверять не пересекается ли он с предыдущим текущим графиком работы работника и не выходит за рамки рабочих часов кондитерской больше чем на час
-- В случае если выходит, вывести ошибку и данные не добавлять

CREATE OR REPLACE FUNCTION trg_validate_work_schedule()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_open_time time;
    v_close_time time;
    v_conflict_schedule_id bigint;
BEGIN
    -- Получаем рабочие часы кондитерской для которой добавляем график работы
    SELECT open_time, close_time
    INTO v_open_time, v_close_time
    FROM bakery
    WHERE bakery_id = NEW.bakery_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Кондитерская % не найдена', NEW.bakery_id;
    END IF;

    -- Проверяем что мы не выходим за пределы часа
    IF NEW.work_start_time < (v_open_time - INTERVAL '1 hour')::time
       OR NEW.work_end_time > (v_close_time + INTERVAL '1 hour')::time THEN
        RAISE EXCEPTION 'График сотрудника % на дату % выходит за допустимые рамки кондитерской %',
            NEW.employee_id, NEW.work_date, NEW.bakery_id;
    END IF;

    -- Смотрим отсутствие пересечения с каким-то другим графиком сотрудника
    SELECT ws.schedule_id
    INTO v_conflict_schedule_id
    FROM work_schedule ws
    WHERE ws.employee_id = NEW.employee_id
      AND ws.work_date = NEW.work_date
      AND ws.schedule_id <> COALESCE(NEW.schedule_id, -1)
      AND NEW.work_start_time < ws.work_end_time
      AND NEW.work_end_time > ws.work_start_time;

    IF FOUND THEN
        RAISE EXCEPTION 'График сотрудника % на дату % пересекается с графиком %',
            NEW.employee_id, NEW.work_date, v_conflict_schedule_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_work_schedule
BEFORE INSERT OR UPDATE ON work_schedule
FOR EACH ROW
EXECUTE FUNCTION trg_validate_work_schedule();
