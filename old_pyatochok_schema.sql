CREATE TABLE bakery (
    bakery_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    address text NOT NULL,
    open_time time NOT NULL,
    close_time time NOT NULL,
    rent_cost numeric(12,2) NOT NULL CHECK (rent_cost >= 0),
    phone text,
    CONSTRAINT chk_bakery_work_time CHECK (close_time > open_time)
);

CREATE TABLE client (
    client_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    phone text NOT NULL,
    email text,
    default_delivery_address text
);

CREATE TABLE employee (
    employee_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bakery_id bigint NOT NULL,
    full_name text NOT NULL,
    passport_no text NOT NULL,
    role_code text NOT NULL,
    hourly_rate numeric(12,2) NOT NULL DEFAULT 0 CHECK (hourly_rate >= 0),
    fixed_monthly_salary numeric(12,2) NOT NULL DEFAULT 0 CHECK (fixed_monthly_salary >= 0),
    courier_bonus_pct numeric(5,2) NOT NULL DEFAULT 0 CHECK (courier_bonus_pct >= 0 AND courier_bonus_pct <= 100),
    min_hours_per_month numeric(6,2) NOT NULL DEFAULT 0 CHECK (min_hours_per_month >= 0),
    login text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    hire_date date NOT NULL,
    CONSTRAINT uq_employee_passport UNIQUE (passport_no),
    CONSTRAINT chk_employee_role
        CHECK (role_code IN ('CHEF', 'CONFECTIONER', 'CASHIER', 'COURIER', 'OWNER')),
    CONSTRAINT fk_employee_bakery
        FOREIGN KEY (bakery_id)
        REFERENCES bakery(bakery_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE work_schedule (
    schedule_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id bigint NOT NULL,
    bakery_id bigint NOT NULL,
    work_date date NOT NULL,
    day_of_week smallint NOT NULL,
    work_start_time time NOT NULL,
    work_end_time time NOT NULL,
    break_start_time time,
    break_end_time time,
    CONSTRAINT chk_schedule_day_of_week CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_schedule_work_time CHECK (work_end_time > work_start_time),
    CONSTRAINT chk_schedule_break_time CHECK (
        (break_start_time IS NULL AND break_end_time IS NULL)
        OR
        (break_start_time IS NOT NULL AND break_end_time IS NOT NULL
         AND break_start_time >= work_start_time
         AND break_end_time <= work_end_time
         AND break_end_time > break_start_time)
    ),
    CONSTRAINT fk_schedule_employee
        FOREIGN KEY (employee_id)
        REFERENCES employee(employee_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_schedule_bakery
        FOREIGN KEY (bakery_id)
        REFERENCES bakery(bakery_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE ingredient (
    ingredient_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    description text,
    cost_per_kg numeric(12,2) CHECK (cost_per_kg IS NULL OR cost_per_kg >= 0),
    cost_per_piece numeric(12,2) CHECK (cost_per_piece IS NULL OR cost_per_piece >= 0),
    calories_per_100g numeric(8,2) CHECK (calories_per_100g IS NULL OR calories_per_100g >= 0),
    calories_per_piece numeric(8,2) CHECK (calories_per_piece IS NULL OR calories_per_piece >= 0),
    shelf_life_days integer CHECK (shelf_life_days IS NULL OR shelf_life_days >= 0),
    can_be_weight boolean NOT NULL DEFAULT false,
    can_be_piece boolean NOT NULL DEFAULT false,
    CONSTRAINT chk_ingredient_measure CHECK (can_be_weight OR can_be_piece)
);

CREATE TABLE utensil (
    utensil_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    description text
);

CREATE TABLE store (
    store_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    address text NOT NULL,
    phone text
);

CREATE TABLE product (
    product_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    chef_id bigint NOT NULL,
    name text NOT NULL,
    recipe_description text,
    is_active boolean NOT NULL DEFAULT true,
    CONSTRAINT fk_product_chef
        FOREIGN KEY (chef_id)
        REFERENCES employee(employee_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE bakery_ingredient_stock (
    bakery_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    stock_qty_g numeric(12,3) NOT NULL DEFAULT 0 CHECK (stock_qty_g >= 0),
    stock_qty_pcs integer NOT NULL DEFAULT 0 CHECK (stock_qty_pcs >= 0),
    avg_daily_consumption_g numeric(12,3) NOT NULL DEFAULT 0 CHECK (avg_daily_consumption_g >= 0),
    avg_daily_consumption_pcs integer NOT NULL DEFAULT 0 CHECK (avg_daily_consumption_pcs >= 0),
    CONSTRAINT pk_bakery_ingredient_stock PRIMARY KEY (bakery_id, ingredient_id),
    CONSTRAINT fk_bakery_ingredient_stock_bakery
        FOREIGN KEY (bakery_id)
        REFERENCES bakery(bakery_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_bakery_ingredient_stock_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient(ingredient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE bakery_utensil_inventory (
    bakery_id bigint NOT NULL,
    utensil_id bigint NOT NULL,
    qty_available integer NOT NULL DEFAULT 0 CHECK (qty_available >= 0),
    condition_status text,
    CONSTRAINT pk_bakery_utensil_inventory PRIMARY KEY (bakery_id, utensil_id),
    CONSTRAINT fk_bakery_utensil_inventory_bakery
        FOREIGN KEY (bakery_id)
        REFERENCES bakery(bakery_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_bakery_utensil_inventory_utensil
        FOREIGN KEY (utensil_id)
        REFERENCES utensil(utensil_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE store_ingredient_assortment (
    store_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    price_per_kg numeric(12,2) CHECK (price_per_kg IS NULL OR price_per_kg >= 0),
    price_per_piece numeric(12,2) CHECK (price_per_piece IS NULL OR price_per_piece >= 0),
    stock_qty_g numeric(12,3) NOT NULL DEFAULT 0 CHECK (stock_qty_g >= 0),
    stock_qty_pcs integer NOT NULL DEFAULT 0 CHECK (stock_qty_pcs >= 0),
    CONSTRAINT pk_store_ingredient_assortment PRIMARY KEY (store_id, ingredient_id),
    CONSTRAINT fk_store_ingredient_assortment_store
        FOREIGN KEY (store_id)
        REFERENCES store(store_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_store_ingredient_assortment_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient(ingredient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE store_utensil_assortment (
    store_id bigint NOT NULL,
    utensil_id bigint NOT NULL,
    price_amount numeric(12,2) NOT NULL CHECK (price_amount >= 0),
    stock_qty integer NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    CONSTRAINT pk_store_utensil_assortment PRIMARY KEY (store_id, utensil_id),
    CONSTRAINT fk_store_utensil_assortment_store
        FOREIGN KEY (store_id)
        REFERENCES store(store_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_store_utensil_assortment_utensil
        FOREIGN KEY (utensil_id)
        REFERENCES utensil(utensil_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE product_utensil (
    product_id bigint NOT NULL,
    utensil_id bigint NOT NULL,
    usage_note text,
    CONSTRAINT pk_product_utensil PRIMARY KEY (product_id, utensil_id),
    CONSTRAINT fk_product_utensil_product
        FOREIGN KEY (product_id)
        REFERENCES product(product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_product_utensil_utensil
        FOREIGN KEY (utensil_id)
        REFERENCES utensil(utensil_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE price_list (
    price_list_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bakery_id bigint NOT NULL,
    name text NOT NULL,
    valid_from date NOT NULL,
    valid_to date,
    is_active boolean NOT NULL DEFAULT true,
    CONSTRAINT chk_price_list_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT fk_price_list_bakery
        FOREIGN KEY (bakery_id)
        REFERENCES bakery(bakery_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE price_list_item (
    price_list_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    price_list_id bigint NOT NULL,
    product_id bigint NOT NULL,
    item_code text NOT NULL,
    sale_price numeric(12,2) NOT NULL CHECK (sale_price >= 0),
    prep_time_minutes integer NOT NULL CHECK (prep_time_minutes >= 0),
    calories_kcal numeric(8,2) NOT NULL CHECK (calories_kcal >= 0),
    CONSTRAINT uq_price_list_item_code UNIQUE (price_list_id, item_code),
    CONSTRAINT fk_price_list_item_price_list
        FOREIGN KEY (price_list_id)
        REFERENCES price_list(price_list_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_price_list_item_product
        FOREIGN KEY (product_id)
        REFERENCES product(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE price_list_item_ingredient (
    price_list_item_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    amount_value numeric(12,3) NOT NULL CHECK (amount_value > 0),
    amount_unit text NOT NULL,
    taste_contribution_pct numeric(5,2) NOT NULL CHECK (taste_contribution_pct >= 0 AND taste_contribution_pct <= 100),
    CONSTRAINT pk_price_list_item_ingredient PRIMARY KEY (price_list_item_id, ingredient_id),
    CONSTRAINT chk_price_list_item_ingredient_unit CHECK (amount_unit IN ('g', 'pcs')),
    CONSTRAINT fk_price_list_item_ingredient_item
        FOREIGN KEY (price_list_item_id)
        REFERENCES price_list_item(price_list_item_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_price_list_item_ingredient_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient(ingredient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE allowed_topping (
    price_list_item_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    default_amount numeric(12,3) NOT NULL CHECK (default_amount > 0),
    amount_unit text NOT NULL,
    extra_price numeric(12,2) NOT NULL CHECK (extra_price >= 0),
    taste_drop_pct numeric(5,2) NOT NULL CHECK (taste_drop_pct >= 0 AND taste_drop_pct <= 100),
    CONSTRAINT pk_allowed_topping PRIMARY KEY (price_list_item_id, ingredient_id),
    CONSTRAINT chk_allowed_topping_unit CHECK (amount_unit IN ('g', 'pcs')),
    CONSTRAINT fk_allowed_topping_item
        FOREIGN KEY (price_list_item_id)
        REFERENCES price_list_item(price_list_item_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_allowed_topping_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient(ingredient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE replacement_group (
    replacement_group_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    price_list_item_id bigint NOT NULL,
    group_name text NOT NULL,
    comment text,
    CONSTRAINT fk_replacement_group_item
        FOREIGN KEY (price_list_item_id)
        REFERENCES price_list_item(price_list_item_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE replacement_group_item (
    replacement_group_id bigint NOT NULL,
    base_ingredient_id bigint NOT NULL,
    substitute_ingredient_id bigint NOT NULL,
    taste_drop_pct numeric(5,2) NOT NULL CHECK (taste_drop_pct >= 0 AND taste_drop_pct <= 100),
    CONSTRAINT pk_replacement_group_item PRIMARY KEY (
        replacement_group_id,
        base_ingredient_id,
        substitute_ingredient_id
    ),
    CONSTRAINT chk_replacement_not_same CHECK (base_ingredient_id <> substitute_ingredient_id),
    CONSTRAINT fk_replacement_group_item_group
        FOREIGN KEY (replacement_group_id)
        REFERENCES replacement_group(replacement_group_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_replacement_group_item_base_ingredient
        FOREIGN KEY (base_ingredient_id)
        REFERENCES ingredient(ingredient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_replacement_group_item_substitute_ingredient
        FOREIGN KEY (substitute_ingredient_id)
        REFERENCES ingredient(ingredient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE customer_order (
    order_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id bigint NOT NULL,
    bakery_id bigint NOT NULL,
    cashier_id bigint NOT NULL,
    order_datetime timestamptz NOT NULL DEFAULT now(),
    order_type text NOT NULL,
    status text NOT NULL,
    order_total_amount numeric(12,2) NOT NULL DEFAULT 0 CHECK (order_total_amount >= 0),
    CONSTRAINT fk_customer_order_client
        FOREIGN KEY (client_id)
        REFERENCES client(client_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_customer_order_bakery
        FOREIGN KEY (bakery_id)
        REFERENCES bakery(bakery_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_customer_order_cashier
        FOREIGN KEY (cashier_id)
        REFERENCES employee(employee_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE invoice (
    invoice_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id bigint NOT NULL,
    courier_employee_id bigint NOT NULL,
    recipient_fio text NOT NULL,
    delivery_address text NOT NULL,
    delivery_due_at timestamptz NOT NULL,
    delivered_at timestamptz,
    recipient_signed boolean NOT NULL DEFAULT false,
    claim_text text,
    has_claim boolean NOT NULL DEFAULT false,
    CONSTRAINT uq_invoice_order UNIQUE (order_id),
    CONSTRAINT fk_invoice_order
        FOREIGN KEY (order_id)
        REFERENCES customer_order(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_invoice_courier
        FOREIGN KEY (courier_employee_id)
        REFERENCES employee(employee_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE order_item (
    order_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id bigint NOT NULL,
    price_list_item_id bigint NOT NULL,
    quantity integer NOT NULL CHECK (quantity > 0),
    base_price numeric(12,2) NOT NULL CHECK (base_price >= 0),
    toppings_price numeric(12,2) NOT NULL DEFAULT 0 CHECK (toppings_price >= 0),
    line_total_amount numeric(12,2) NOT NULL CHECK (line_total_amount >= 0),
    final_taste_pct numeric(5,2) NOT NULL CHECK (final_taste_pct >= 0 AND final_taste_pct <= 100),
    CONSTRAINT fk_order_item_order
        FOREIGN KEY (order_id)
        REFERENCES customer_order(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_item_price_list_item
        FOREIGN KEY (price_list_item_id)
        REFERENCES price_list_item(price_list_item_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE order_item_topping (
    order_item_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    amount_value numeric(12,3) NOT NULL CHECK (amount_value > 0),
    amount_unit text NOT NULL,
    extra_price numeric(12,2) NOT NULL CHECK (extra_price >= 0),
    taste_drop_pct_applied numeric(5,2) NOT NULL CHECK (taste_drop_pct_applied >= 0 AND taste_drop_pct_applied <= 100),
    CONSTRAINT pk_order_item_topping PRIMARY KEY (order_item_id, ingredient_id),
    CONSTRAINT chk_order_item_topping_unit CHECK (amount_unit IN ('g', 'pcs')),
    CONSTRAINT fk_order_item_topping_order_item
        FOREIGN KEY (order_item_id)
        REFERENCES order_item(order_item_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_item_topping_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient(ingredient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE order_item_exclusion (
    order_item_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_order_item_exclusion PRIMARY KEY (order_item_id, ingredient_id),
    CONSTRAINT fk_order_item_exclusion_order_item
        FOREIGN KEY (order_item_id)
        REFERENCES order_item(order_item_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_item_exclusion_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient(ingredient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE invoice_return_item (
    invoice_id bigint NOT NULL,
    order_item_id bigint NOT NULL,
    is_returned boolean NOT NULL DEFAULT true,
    return_reason text,
    CONSTRAINT pk_invoice_return_item PRIMARY KEY (invoice_id, order_item_id),
    CONSTRAINT fk_invoice_return_item_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES invoice(invoice_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_invoice_return_item_order_item
        FOREIGN KEY (order_item_id)
        REFERENCES order_item(order_item_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE activity_log (
    log_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id bigint NOT NULL,
    action_type text NOT NULL,
    action_at timestamptz NOT NULL DEFAULT now(),
    info text,
    CONSTRAINT fk_activity_log_employee
        FOREIGN KEY (employee_id)
        REFERENCES employee(employee_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);
