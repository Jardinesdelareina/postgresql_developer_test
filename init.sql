\connect postgres

DROP DATABASE IF EXISTS company WITH (FORCE);
CREATE DATABASE company;

\connect company


CREATE SCHEMA core;                     -- Основная модель данных
CREATE SCHEMA api;                      -- API базы данных
CREATE SCHEMA service;                  -- Служебный функционал, обеспечивающий целостность данных


GRANT ALL PRIVILEGES ON DATABASE company TO testuser;

--
-- DATA MODELS
--


CREATE TABLE core.departments
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(200)
);
COMMENT ON TABLE core.departments
IS 'Отделы';


CREATE TABLE core.offices
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    number INT NOT NULL,
    seats INT CHECK (seats >= 0) NOT NULL
);
COMMENT ON TABLE core.offices 
IS 'Офисы';


CREATE TABLE core.roles
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    salary NUMERIC(10, 2) NOT NULL
);
COMMENT ON TABLE core.roles 
IS 'Должности';


CREATE TABLE core.employees
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    date_of_birdth DATE NOT NULL,
    salary NUMERIC(10, 2),
    fk_boss INT REFERENCES core.employees(id) ON DELETE SET NULL,
    fk_department INT REFERENCES core.departments(id) ON DELETE CASCADE,
    fk_office INT REFERENCES core.offices(id) ON DELETE SET NULL,
    fk_role INT REFERENCES core.roles(id) ON DELETE CASCADE
);
COMMENT ON TABLE core.employees 
IS 'Сотрудники';


--
-- PROCEDURES
--

-- DEPARTMENT

CREATE OR REPLACE PROCEDURE api.create_department(
    input_title VARCHAR(200)
    ) AS $$
    INSERT INTO core.departments(title)
    VALUES(input_title);
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.create_department(VARCHAR(200)) 
IS 'Добавление отдела';


CREATE OR REPLACE PROCEDURE api.update_department(
    input_id INT,
    input_title VARCHAR(200)
    ) AS $$
    UPDATE core.departments
    SET title = input_title
    WHERE id = input_id;
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.update_department(INT, VARCHAR(200)) 
IS 'Изменение названия отдела';


CREATE OR REPLACE PROCEDURE api.delete_department(
    input_title VARCHAR(200)
    ) AS $$
    DELETE FROM core.departments WHERE title = input_title;
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.create_department(VARCHAR(200)) 
IS 'Удаление отдела';


-- OFFICES

CREATE OR REPLACE PROCEDURE api.create_office(
    input_number INT,
    input_seats INT
    ) AS $$
    INSERT INTO core.offices(number, seats)
    VALUES(input_number, input_seats);
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.create_office(INT, INT) 
IS 'Добавление офиса';


CREATE OR REPLACE PROCEDURE api.update_office(
    input_id INT,
    input_number INT DEFAULT NULL,
    input_seats INT DEFAULT NULL
    ) AS $$
    UPDATE core.offices
    SET number = COALESCE(input_number, number), 
        seats = COALESCE(input_seats, seats)
    WHERE id = input_id;
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.update_office(INT, INT, INT) 
IS 'Изменение количества мест в офисе';


CREATE OR REPLACE PROCEDURE api.delete_office(
    input_id INT
    ) AS $$
    DELETE FROM core.offices WHERE id = input_id;
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.delete_office(INT) 
IS 'Удаление офиса';


-- ROLES

CREATE OR REPLACE PROCEDURE api.create_role(
    input_title VARCHAR(300),
    input_salary NUMERIC(10, 2)
    ) AS $$
    INSERT INTO core.roles(title, salary)
    VALUES(input_title, input_salary);
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.create_role(VARCHAR(300), NUMERIC(10, 2)) 
IS 'Добавление должности';


/* 
Пример использования: 
CALL core.update_role(1, 'New Title', NULL);
В параметры процедуры вводится id должности и параметр, 
который нужно изменить (уже измененный вариант). 
Для неизменного параметра нужно ввести NULL. Можно ввести для изменения оба параметра.
*/
CREATE OR REPLACE PROCEDURE api.update_role(
    input_id INT,
    input_title VARCHAR(300) DEFAULT NULL,
    input_salary NUMERIC(10, 2) DEFAULT NULL
    ) AS $$
BEGIN
    IF input_title IS NOT NULL OR input_salary IS NOT NULL THEN
        UPDATE core.roles 
        SET title = COALESCE(input_title, title),
            salary = COALESCE(input_salary, salary) 
        WHERE id = input_id;
    ELSE
        RAISE EXCEPTION 'Необходимо указать хотя бы один параметр (должность или зарплата)';
    END IF;
END;
$$ LANGUAGE plpgsql;
COMMENT ON PROCEDURE api.update_role(INT, VARCHAR(300), NUMERIC(10, 2)) 
IS 'Изменение параметров должности';


CREATE OR REPLACE PROCEDURE api.delete_role(
    input_id INT
    ) AS $$
    DELETE FROM core.roles WHERE id = input_id
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.delete_role(INT) 
IS 'Удаление должности';


-- EMPLOYEES

CREATE OR REPLACE PROCEDURE api.create_employee(
    input_first_name VARCHAR(50),
    input_last_name VARCHAR(50),
    input_middle_name VARCHAR(50),
    input_date_of_birdth DATE,
    input_salary NUMERIC(10, 2),
    input_boss INT,
    input_department INT,
    input_office INT,
    input_role INT
    ) AS $$
    INSERT INTO core.employees(first_name, last_name, middle_name, date_of_birdth, salary, 
    fk_boss, fk_department, fk_office, fk_role)
    VALUES(input_first_name, input_last_name, input_middle_name, input_date_of_birdth, 
    input_salary, input_boss, input_department, input_office, input_role);
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.create_employee(
    VARCHAR(50), VARCHAR(50), VARCHAR(50), DATE, NUMERIC(10, 2),
    INT, INT, INT, INT
) IS 'Добавление должости';


CREATE OR REPLACE PROCEDURE api.update_employee(
    input_id INT,
    iinput_first_name VARCHAR(50) DEFAULT NULL,
    input_last_name VARCHAR(50) DEFAULT NULL,
    input_middle_name VARCHAR(50) DEFAULT NULL,
    input_date_of_birdth DATE DEFAULT NULL,
    input_salary NUMERIC(10, 2) DEFAULT NULL,
    input_boss INT DEFAULT NULL,
    input_department INT DEFAULT NULL,
    input_office INT DEFAULT NULL,
    input_role INT DEFAULT NULL
    ) AS $$
BEGIN
    IF input_first_name IS NOT NULL 
    OR input_last_name IS NOT NULL 
    OR input_middle_name IS NOT NULL
    OR input_date_of_birdth IS NOT NULL
    OR input_salary IS NOT NULL
    OR input_boss IS NOT NULL
    OR input_department IS NOT NULL
    OR input_office IS NOT NULL
    OR input_role IS NOT NULL
    THEN
        UPDATE core.roles 
        SET first_name = COALESCE(input_first_name, first_name),
            last_name = COALESCE(input_last_name, last_name),
            middle_name = COALESCE(input_middle_name, middle_name),
            date_of_birdth = COALESCE(input_date_of_birdth, date_of_birdth),
            salary = COALESCE(input_salary, salary),
            fk_boss = COALESCE(input_boss, fk_boss),
            fk_department = COALESCE(input_department, fk_department),
            fk_office = COALESCE(input_office, fk_office),
            fk_role =COALESCE(input_role, fk_role)
        WHERE id = input_id;
    ELSE
        RAISE EXCEPTION 'Необходимо указать хотя бы один параметр (должность или зарплата)';
    END IF;
END;
$$ LANGUAGE plpgsql;
COMMENT ON PROCEDURE api.update_employee(
    INT, VARCHAR(50), VARCHAR(50), VARCHAR(50), DATE, NUMERIC(10, 2),
    INT, INT, INT, INT
) 
IS 'Изменение параметров сотрудника';


CREATE OR REPLACE PROCEDURE api.delete_employee(
    input_id INT
    ) AS $$
    DELETE FROM core.employees WHERE id = input_id
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.delete_employee(INT) 
IS 'Удаление сотрудника';


--
-- VIEWS
--


CREATE OR REPLACE VIEW api.get_departments AS
SELECT id, title FROM core.departments;
COMMENT ON VIEW api.get_departments 
IS 'Подробная информация об отделах';


CREATE OR REPLACE VIEW api.get_offices AS
SELECT id, number, seats FROM core.offices;
COMMENT ON VIEW api.get_offices 
IS 'Подробная информация об офисах';


CREATE OR REPLACE VIEW api.get_roles AS
SELECT id, title, salary FROM core.roles;
COMMENT ON VIEW api.get_roles 
IS 'Подробная информация об должностях';


CREATE OR REPLACE VIEW api.get_employees AS
SELECT 
    id, 
    first_name, 
    last_name, 
    middle_name, 
    date_of_birdth, 
    salary, 
    fk_boss, 
    fk_department, 
    fk_office, 
    fk_role 
FROM core.employees;
COMMENT ON VIEW api.get_employees 
IS 'Подробная информация об сотрудниках';


--
-- TRIGGERS
--


CREATE OR REPLACE FUNCTION service.set_default_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary IS NULL THEN
        SELECT salary INTO NEW.salary
        FROM core.roles
        WHERE id = NEW.fk_role;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_default_salary
BEFORE INSERT ON core.employees
FOR EACH ROW
EXECUTE FUNCTION service.set_default_salary();
COMMENT ON TRIGGER trg_set_default_salary ON core.employees
IS 'Установка сотруднику зарплаты по-умолчанию согласно должности';


CREATE OR REPLACE FUNCTION service.decrement_seats()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT seats FROM core.offices WHERE id = NEW.fk_office) > 0 THEN
        UPDATE core.offices
        SET seats = seats - 1
        WHERE id = NEW.fk_office;
    ELSE
        UPDATE core.employees
        SET fk_office = NULL
        WHERE fk_office = NEW.fk_office;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_decrement_seats
AFTER INSERT ON core.employees
FOR EACH ROW
EXECUTE FUNCTION service.decrement_seats();
COMMENT ON TRIGGER trg_decrement_seats ON core.employees
IS 'Уменьшение количества мест в офисе при добавлении нового сотрудника';


CREATE OR REPLACE FUNCTION service.increment_seats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE core.offices
    SET seats = seats + 1
    WHERE id = OLD.fk_office;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_increment_seats
AFTER DELETE ON core.employees
FOR EACH ROW
EXECUTE FUNCTION service.increment_seats();
COMMENT ON TRIGGER trg_increment_seats ON core.employees
IS 'Увеличение количества мест в офисе при добавлении нового сотрудника';


--
-- GENERATE DATA
--


CREATE OR REPLACE FUNCTION service.generate_num(limit_num INT) RETURNS INT AS $$
    SELECT FLOOR(RANDOM() * limit_num) + 1;
$$ LANGUAGE sql;
COMMENT ON FUNCTION service.generate_num(INT)
IS 'Генерация случайного целого числа';


CREATE OR REPLACE FUNCTION service.generate_boolean_value() RETURNS BOOLEAN AS $$
    SELECT CASE WHEN random() < 0.5 THEN TRUE ELSE FALSE END;
$$ LANGUAGE sql;
COMMENT ON FUNCTION service.generate_boolean_value()
IS 'Генерация булевого значения';


-- Генерация данных об отделах
DO $$
DECLARE
    department_list VARCHAR[] := ARRAY[
        'Система безопасности',
        'Web-разработка',
        'Контроль качества',
        'DevOps',
        'Маркетинг',
        'Бухгалтерия',
        'HR',
        'Аналитика'
    ];
    i VARCHAR;
BEGIN
    FOREACH i IN ARRAY department_list
    LOOP
        CALL api.create_department(i);
    END LOOP;
END $$;


-- Генерация данных об офисах
DO $$
DECLARE
    random_num_number INT;
    random_num_seats INT;
    i INT;
BEGIN
    FOR i IN 1..100
    LOOP
        IF i = 1 THEN
            random_num_number := 4;
        ELSE
            random_num_number := service.generate_num(100);
        END IF;
        random_num_seats := service.generate_num(100);
        CALL api.create_office(random_num_number, random_num_seats);
    END LOOP;
END $$;


-- Генерация данных о должностях
CALL api.create_role('Backend-разработчик', 100000.00);
CALL api.create_role('Frontend-разработчик', 100000.00);
CALL api.create_role('Разработчик баз данных', 120000.00);
CALL api.create_role('Системный администратор', 170000.00);
CALL api.create_role('DBA', 260000.00);
CALL api.create_role('Team-lead DBA', 450000.00);
CALL api.create_role('DevOps-инженер', 280000.00);
CALL api.create_role('Старший DevOps-инженер', 400000.00);
CALL api.create_role('HR', 100000.00);
CALL api.create_role('Team-Lead HR', 150000.00);
CALL api.create_role('Менеджер проектов', 200000.00);
CALL api.create_role('Аналитик данных', 100000.00);
CALL api.create_role('Data-инженер', 150000.00);
CALL api.create_role('Маркетолог', 110000.00);
CALL api.create_role('Специалист по информационной безопасности', 130000.00);
CALL api.create_role('Тестировщик', 100000.00);
CALL api.create_role('CTO', 900000.00);



CREATE OR REPLACE VIEW service.first_name_male AS
SELECT first_name 
FROM (SELECT UNNEST(array[
    'Андрей', 'Александр', 'Алексей', 'Артем', 'Борис', 'Вадим', 
    'Василий', 'Виктор', 'Геннадий', 'Георгий', 'Даниил', 
    'Дмитрий', 'Евгений', 'Иван', 'Игорь', 'Илья', 'Константин', 
    'Леонид', 'Максим', 'Михаил', 'Никита', 'Николай', 'Олег', 
    'Павел', 'Петр', 'Роман', 'Сергей', 'Станислав', 'Тимофей', 
    'Федор', 'Юрий', 'Яков', 'Ярослав', 'Артур', 'Владимир', 
    'Григорий', 'Захар', 'Анатолий']) AS first_name) AS f
ORDER BY RANDOM()
LIMIT 1;
COMMENT ON VIEW service.first_name_male
IS 'Случайное мужское имя';


CREATE OR REPLACE VIEW service.last_name_male AS
SELECT last_name 
FROM (SELECT UNNEST(array[
    'Иванов', 'Петров', 'Сидоров', 'Смирнов', 'Кузнецов', 'Попов', 
    'Васильев', 'Петров', 'Смирнов', 'Морозов', 'Новиков', 'Зайцев', 
    'Борисов', 'Александров', 'Сергеев', 'Ковалев', 'Илларионов', 
    'Григорьев', 'Романов', 'Федоров', 'Яковлев', 'Поляков', 'Соколов', 
    'Макаров', 'Антонов', 'Крылов', 'Гаврилов', 'Ефимов', 'Фомин', 
    'Дорофеев', 'Беляев', 'Никонов', 'Артемьев', 'Левин', 'Зуев', 
    'Кондратьев', 'Андреев', 'Захаров']) AS last_name) AS l
ORDER BY RANDOM()
LIMIT 1;
COMMENT ON VIEW service.last_name_male
IS 'Случайная мужская фамилия';


CREATE OR REPLACE VIEW service.middle_name_male AS
SELECT middle_name 
FROM (SELECT UNNEST(array[
    'Иванович', 'Петрович', 'Васильевич', 'Алексеевич', 'Борисович', 'Александрович', 
    'Сергеевич', 'Илларионович', 'Григорьевич', 'Романович', 'Федорович', 'Макарович', 
    'Антонович', 'Ефимович', 'Андреевич', 'Захарович', NULL]) AS middle_name) AS m
ORDER BY RANDOM()
LIMIT 1;
COMMENT ON VIEW service.middle_name_male
IS 'Случайное мужское отчество';


CREATE OR REPLACE VIEW service.first_name_female AS
SELECT first_name 
FROM (SELECT UNNEST(array[
    'Анна', 'Виктория', 'Екатерина', 'Мария', 'Ольга', 'Татьяна', 
    'Алиса', 'Дарья', 'Елена', 'Ирина', 'Ксения', 'Лариса', 
    'Надежда', 'Полина', 'София', 'Юлия', 'Анжела', 'Валентина', 
    'Евгения', 'Марина', 'Оксана', 'Тамара', 'Антонина', 'Валерия', 
    'Ева', 'Кристина', 'Лилия', 'Нина', 'Раиса', 'Светлана', 
    'Юлиана', 'Ангелина', 'Галина', 'Елена', 'Лидия', 'Милена', 
    'Ольга', 'Таисия', 'Агата']) AS first_name) AS f
ORDER BY RANDOM()
LIMIT 1;
COMMENT ON VIEW service.first_name_female
IS 'Случайное женское имя';


CREATE OR REPLACE VIEW service.last_name_female AS
SELECT last_name 
FROM (SELECT UNNEST(array[
    'Иванова', 'Петрова', 'Сидорова', 'Смирнова', 'Кузнецова', 'Попова', 
    'Васильева', 'Петрова', 'Смирнова', 'Морозова', 'Новикова', 'Зайцева', 
    'Борисова', 'Александрова', 'Сергеева', 'Ковалева', 'Илларионова', 'Григорьева', 
    'Романова', 'Федорова', 'Яковлева', 'Полякова', 'Соколова', 'Макарова', 
    'Антонова', 'Крылова', 'Гаврилова', 'Ефимова', 'Фомина', 'Дорофеева', 
    'Беляева', 'Никонова', 'Артемьева', 'Левина', 'Зуева', 'Кондратьева', 
    'Андреева', 'Захарова']) AS last_name) AS l
ORDER BY RANDOM()
LIMIT 1;
COMMENT ON VIEW service.last_name_female
IS 'Случайная женская фамилия';


CREATE OR REPLACE VIEW service.middle_name_female AS
SELECT middle_name 
FROM (SELECT UNNEST(array[
    'Ивановна', 'Петровна', 'Васильевна', 'Алексеевна', 'Борисовна', 'Александровна', 
    'Сергеевна', 'Илларионовна', 'Григорьевна', 'Романовна', 'Федоровна', 'Макаровна', 
    'Антоновна', 'Ефимовна', 'Андреевна', 'Захаровна', NULL]) AS middle_name) AS m
ORDER BY RANDOM()
LIMIT 1;
COMMENT ON VIEW service.middle_name_female
IS 'Случайное женское отчество';


CREATE OR REPLACE FUNCTION service.generate_date()
RETURNS DATE AS $$
DECLARE
    start_date DATE := '1950-12-31';
    end_date DATE := '2005-01-01';
    random_days INTEGER;
BEGIN
    random_days := RANDOM() * (end_date - start_date) + 1;
    RETURN start_date + random_days;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION service.generate_date()
IS 'Генерация случайной даты';


CREATE OR REPLACE FUNCTION service.generate_numeric() 
RETURNS NUMERIC(10, 2) AS $$
DECLARE
    varchar_num VARCHAR;
BEGIN
    varchar_num := (SELECT service.generate_num(90)) || '0000.00';
    RETURN varchar_num::NUMERIC(10, 2);
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION service.generate_date()
IS 'Генерация случайного числа типа NUMERIC(10, 2)';


-- Генерация данных о сотрудниках
DO $$
DECLARE
    random_boolean_value BOOLEAN;
    i INT;
    first_name_value VARCHAR(50);
    middle_name_value VARCHAR(50);
    last_name_value VARCHAR(50);
    random_date_value DATE;
    random_numeric_value NUMERIC(10, 2);
    random_boss_value INT;
    random_department_value INT;
    random_office_value INT;
    random_role_value INT;
BEGIN
    FOR i IN 1..1000 LOOP
        random_boolean_value := (SELECT service.generate_boolean_value());
        IF random_boolean_value = TRUE THEN
            first_name_value := (SELECT first_name FROM service.first_name_male);
            middle_name_value := (SELECT middle_name FROM service.middle_name_male);
            last_name_value := (SELECT last_name FROM service.last_name_male);
        ELSE
            first_name_value := (SELECT first_name FROM service.first_name_female);
            middle_name_value := (SELECT middle_name FROM service.middle_name_female);
            last_name_value := (SELECT last_name FROM service.last_name_female);
        END IF;
        random_date_value := (SELECT service.generate_date());
        random_numeric_value := (
            SELECT CASE WHEN random_boolean_value = TRUE THEN service.generate_numeric() ELSE NULL END
        );
        random_boss_value := NULL;
        random_department_value := (SELECT service.generate_num(8));
        random_office_value := (SELECT service.generate_num(100));
        random_role_value := (SELECT service.generate_num(16));
        CALL api.create_employee(
            first_name_value,
            last_name_value,
            middle_name_value,
            random_date_value,
            random_numeric_value,
            random_boss_value,
            random_department_value,
            random_office_value,
            random_role_value
        );
    END LOOP;

    WITH row_employees AS (
        SELECT id, ROW_NUMBER() OVER(PARTITION BY fk_office ORDER BY id) AS row_number
        FROM core.employees
    )
    UPDATE core.employees e
    SET fk_boss = CASE WHEN re.row_number = 1 THEN NULL ELSE e.id END
    FROM row_employees re
    WHERE e.id = re.id;
END $$;