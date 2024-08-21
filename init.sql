\connect postgres

DROP DATABASE IF EXISTS company WITH (FORCE);
CREATE DATABASE company;

\connect company


CREATE SCHEMA core;
CREATE SCHEMA api;
CREATE SCHEMA service;


GRANT USAGE ON SCHEMA api TO PUBLIC;


--
-- DATA MODELS
--


CREATE TABLE core.departments
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(200)
);
COMMENT ON TABLE core.departments
IS 'Отделы';


CREATE TABLE core.offices
(
    number SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seats SMALLINT NOT NULL
);
COMMENT ON TABLE core.offices 
IS 'Офисы';


CREATE TABLE core.roles
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    fk_boss SMALLINT REFERENCES core.employees(id) ON DELETE SET NULL,
    fk_department SMALLINT REFERENCES core.departments(id) ON DELETE CASCADE,
    fk_office SMALLINT REFERENCES core.offices(number) ON DELETE SET NULL,
    fk_role SMALLINT REFERENCES core.roles(id) ON DELETE CASCADE
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
    input_id SMALLINT,
    input_title VARCHAR(200)
    ) AS $$
    UPDATE core.departments
    SET title = input_title
    WHERE id = input_id;
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.update_department(SMALLINT, VARCHAR(200)) 
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
    input_seats SMALLINT
    ) AS $$
    INSERT INTO core.offices(seats)
    VALUES(input_seats);
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.create_office(SMALLINT) 
IS 'Добавление офиса';


CREATE OR REPLACE PROCEDURE api.update_office(
    input_number SMALLINT,
    input_seats SMALLINT
    ) AS $$
    UPDATE core.offices
    SET seats = input_seats
    WHERE number = input_number;
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.update_office(SMALLINT, SMALLINT) 
IS 'Изменение количества мест в офисе';


CREATE OR REPLACE PROCEDURE api.delete_office(
    input_number SMALLINT
    ) AS $$
    DELETE FROM core.offices WHERE number = input_number;
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.delete_office(SMALLINT) 
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
    input_id SMALLINT,
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
COMMENT ON PROCEDURE api.update_role(SMALLINT, VARCHAR(300), NUMERIC(10, 2)) 
IS 'Изменение параметров должности';


CREATE OR REPLACE PROCEDURE api.delete_role(
    input_id SMALLINT
    ) AS $$
    DELETE FROM core.roles WHERE id = input_id
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.delete_role(SMALLINT) 
IS 'Удаление должности';


-- EMPLOYEES

CREATE OR REPLACE PROCEDURE api.create_employee(
    input_first_name VARCHAR(50),
    input_last_name VARCHAR(50),
    input_middle_name VARCHAR(50),
    input_date_of_birdth DATE,
    input_salary NUMERIC(10, 2),
    input_boss SMALLINT,
    input_department SMALLINT,
    input_office SMALLINT,
    input_role SMALLINT
    ) AS $$
    INSERT INTO core.employees(first_name, last_name, middle_name, date_of_birdth, salary, 
    fk_boss, fk_department, fk_office, fk_role)
    VALUES(input_first_name, input_last_name, input_middle_name, input_date_of_birdth, 
    input_salary, input_boss, input_department, input_office, input_role);
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.create_employee(
    VARCHAR(50), VARCHAR(50), VARCHAR(50), DATE, NUMERIC(10, 2),
    SMALLINT, SMALLINT, SMALLINT, SMALLINT
) IS 'Добавление должости';


CREATE OR REPLACE PROCEDURE api.update_employee(
    input_id SMALLINT,
    iinput_first_name VARCHAR(50) DEFAULT NULL,
    input_last_name VARCHAR(50) DEFAULT NULL,
    input_middle_name VARCHAR(50) DEFAULT NULL,
    input_date_of_birdth DATE DEFAULT NULL,
    input_salary NUMERIC(10, 2) DEFAULT NULL,
    input_boss SMALLINT DEFAULT NULL,
    input_department SMALLINT DEFAULT NULL,
    input_office SMALLINT DEFAULT NULL,
    input_role SMALLINT DEFAULT NULL
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
            fk_office = COALESCE(input_office, office),
            fk_role =COALESCE(input_role, role)
        WHERE id = input_id;
    ELSE
        RAISE EXCEPTION 'Необходимо указать хотя бы один параметр (должность или зарплата)';
    END IF;
END;
$$ LANGUAGE plpgsql;
COMMENT ON PROCEDURE api.update_employee(
    SMALLINT, VARCHAR(50), VARCHAR(50), VARCHAR(50), DATE, NUMERIC(10, 2),
    SMALLINT, SMALLINT, SMALLINT, SMALLINT
) 
IS 'Изменение параметров сотрудника';


CREATE OR REPLACE PROCEDURE api.delete_employee(
    input_id SMALLINT
    ) AS $$
    DELETE FROM core.employees WHERE id = input_id
$$ LANGUAGE sql;
COMMENT ON PROCEDURE api.delete_employee(SMALLINT) 
IS 'Удаление сотрудника';


--
-- VIEWS
--


CREATE OR REPLACE VIEW api.get_departments AS
SELECT id, title FROM core.departments;
COMMENT ON VIEW api.get_departments 
IS 'Подробная информация об отделах';


CREATE OR REPLACE VIEW api.get_offices AS
SELECT number, seats FROM core.offices;
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
    IF salary IS NULL THEN
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


CREATE OR REPLACE FUNCTION service.set_remote_work()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT seats FROM core.offices WHERE number = NEW.fk_office) <= (
        SELECT COUNT(id) FROM core.employees WHERE fk_office = NEW.fk_office
    ) THEN
        NEW.fk_office = NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_remote_work
BEFORE INSERT ON core.employees
FOR EACH ROW
EXECUTE FUNCTION service.set_remote_work();
COMMENT ON TRIGGER trg_set_default_salary ON core.employees
IS 'Проверка наличия свободных мест в офисе при добавлении сотрудника';