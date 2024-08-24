-- a. Сотрудники, которых приняли на работу, но не выделили им рабочее место (работают удаленно)
SELECT CONCAT_WS(' ', first_name, middle_name, last_name) AS employees, 
FROM api.get_employees
WHERE fk_office IS NULL;


-- b. Количество сотрудников в каждом отделе (по убыванию количества)
SELECT d.title, COUNT(e.id) AS count_employees
FROM api.get_employees e
LEFT JOIN api.get_departments d ON d.id = e.fk_department
GROUP BY d.title
ORDER BY count_employees DESC;


-- c. Сотрудники, у которых год рождения – нечетное число
SELECT 
    CONCAT_WS(' ', first_name, middle_name, last_name) AS employees, 
    date_of_birdth
FROM api.get_employees
WHERE EXTRACT(YEAR FROM date_of_birdth)::INT % 2 != 0;


-- d. Сотрудники и их возраста (полных лет), а также день, месяц (словом) и год раздельно
SELECT 
    CONCAT_WS(' ', first_name, middle_name, last_name) AS employees, 
    ((EXTRACT(YEAR FROM CURRENT_DATE)::INT) - (EXTRACT(YEAR FROM date_of_birdth)::INT)) AS ages_of_birdth,
    (EXTRACT(YEAR FROM date_of_birdth)::INT) AS days_of_birdth,
    TO_CHAR(date_of_birdth, 'Month') AS month_of_birdth,
    (EXTRACT(YEAR FROM date_of_birdth)::INT) AS years_of_birdth
FROM api.get_employees;


-- e. Сотрудники, у которых день рождения в текущем месяце и зарплата у них ниже той, 
-- что указана в их должности «по-умолчанию»
SELECT 
    CONCAT_WS(' ', first_name, middle_name, last_name) AS employees, 
    ge.date_of_birdth,
    ge.salary
FROM api.get_employees ge
WHERE
    (EXTRACT(MONTH FROM date_of_birdth)::INT) = (EXTRACT(MONTH FROM CURRENT_DATE)::INT) AND
    salary < (SELECT gr.salary FROM api.get_roles gr WHERE gr.id = ge.fk_role);


-- f. Сотрудники, у которых фамилия оканчивается на «ков», 
-- родились они в январе и должность у них НЕ содержит «начальник»
SELECT 
    CONCAT_WS(' ', first_name, middle_name, last_name) AS employees, 
    date_of_birdth
FROM
    api.get_employees
WHERE
    last_name LIKE '%ков' AND
    (EXTRACT(MONTH FROM date_of_birdth)::INT) = 1 AND
    fk_boss IS NOT NULL;


-- g. Сотрудники, которые сидят в офисе № 4 вместе с теми, кто работает удаленно (нет офиса)
SELECT 
    CONCAT_WS(' ', e.first_name, e.middle_name, e.last_name) AS employees,
    o.number
FROM api.get_employees e
LEFT JOIN api.get_offices o ON e.fk_office = o.id 
WHERE o.number = 4 OR o.number IS NULL;


-- h. Сотрудники, у которых есть однофамильцы
-- i. + бонус = вывести в виде: [СотрудникФИО], [Список однофамильцев (их ФИО) через запятую]
SELECT 
    CONCAT_WS(' ', e.first_name, e.middle_name, e.last_name) AS employees,
    STRING_AGG(CONCAT_WS(' ', e1.first_name, e1.middle_name, e1.last_name), ', ') AS namesakes
FROM api.get_employees e
JOIN api.get_employees e1 ON e.last_name = e1.last_name AND e.id != e1.id
GROUP BY employees
ORDER BY employees;


-- j. Список [Год], [Месяц], [Количество дней рождений сотрудников в этом месяце]
SELECT 
    EXTRACT(YEAR FROM date_of_birdth) AS e_age,
    EXTRACT(MONTH FROM date_of_birdth) AS e_month,
    COUNT(*) AS days_of_birdth
FROM api.get_employees
GROUP BY e_age, e_month
ORDER BY e_age;


-- k. Список офисов, в которых есть еще свободные места
-- i. + бонус = данный список отсортировать по убыванию количества мест 
-- и соотв. вывести это количество вместе с вместимостью офиса
SELECT 
    o.number, 
    o.seats, 
    (o.seats + COALESCE((SELECT COUNT(e.id) 
                        FROM core.employees e 
                        WHERE e.fk_office = o.id), 0)) AS capacity
FROM api.get_offices o
WHERE o.seats > 0
ORDER BY o.seats DESC;


-- l. Отделы и средняя ЗП среди сотрудников в них
SELECT d.title, ROUND(AVG(e.salary), 2)::NUMERIC AS salary_employees
FROM api.get_departments d
LEFT JOIN api.get_employees e ON e.fk_department = d.id
GROUP BY d.title;


-- m. Список должностей, на которые еще никто не назначен
SELECT title
FROM api.get_roles
WHERE id NOT IN (SELECT fk_role FROM api.get_employees);


-- n. + бонус = вывести список сотрудников, отсортированный и пронумерованный в таком виде:

--- --- --- --- ---