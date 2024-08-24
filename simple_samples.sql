create table public.test_employee
(
	id 				integer primary key, 	-- Идентификатор
	employee_name 	varchar, 				-- Наименование
	salary 			numeric(19, 2), 		-- оклад
	email 			varchar 				-- эл. почта
);

insert into public.test_employee
values (1,  'AAA', 101, 'AAA@yandex.ru'),
	   (2,  'BBB', 122, 'BBB@gmail.com'),
	   (3,  'CCC', 150, 'AAA@yandex.ru'),
	   (4,  'DDD', 50, 	'DDD@yandex.ru'),
	   (5,  'EEE', 251, 'EEE@yandex.ru'),
	   (6,  'FFF', 77, 	'AAA@yandex.ru'),
	   (7,  'GGG', 20, 	'GGG@yandex.ru'),
	   (8,  'HHH', 10, 	'BBB@gmail.com'),
	   (9,  'III', 305, 'III@yandex.ru'),
	   (10, 'JJJ', 400, 'JJJ@yandex.ru'),
	   (11, 'KKK', 325, 'KKK@yandex.ru'),
	   (12, 'LLL', 10, 	'LLL@yandex.ru'),
	   (13, 'MMM', 400, 'MMM@yandex.ru'),
	   (14, 'NNN', 255, NULL);


-- 1. Вывести записи (список сотрудников) у которых миниммальный оклад в компании
select id, employee_name, salary, email from test_employee
where salary = (
    select min(salary) from test_employee
);


-- 2. Вывести список сотрудников у которых дублируется email 
-- (отсортировать чтобы люди, у которых дублируется конкретный email, были расположены рядом).
select id, employee_name, email from test_employee
where email in (
    select email from test_employee group by email having count(email) > 1
)
order by email;

-- 2.1 Варианты предотвращения данной ситуации в будущем?
/* Колонка email должна быть с констрейнтом unique */


-- 3. Как, используя CTE, найти пятый по величине оклад в таблице? 
-- (пояснение: по величине - значит по убывыанию, т.е. 1ый - самый большой оклад, 
-- 2ый - следующий за ним оклад, который меньше и т.д.)
/* В CTE отсортировать все зарплаты в порядке убывания и пронумеровать позиции,
затем запросом выбрать из CTE нужную (пятую) позицию */

-- 3.1 Вывести сотрудников, у которых такой оклад
WITH salaries AS (
    SELECT 
        id,
        employee_name, 
        salary, 
        ROW_NUMBER() OVER (ORDER BY salary DESC) AS position
    FROM test_employee
)
SELECT 
    id,
    employee_name,
    salary,
    position
FROM salaries
WHERE position = 5;


-- 4. Напишите один запрос, в котором вычислите сумму всех четных 
-- и сумму всех нечетных окладов (отдельными столбцами)
select 
    sum(case when salary % 2 = 0 then salary else 0 end) as even,
    sum(case when salary % 2 != 0 then salary else 0 end) as odd
from test_employee;


-- 5. Как получить последний id без использования функции max?
select id from test_employee order by id desc limit 1;

-- 6. Вывести список сотрудников, исключив из него тех, у кого email содержит @yandex.ru
select id, employee_name, email 
from test_employee 
where email not like '%@yandex.ru';

-- 7. Добавить столбец в таблицу - флаг, который будет содержать значения 0 или 1, 
-- в зависимости от того, есть ли дубли по email (указанного у сотрудника) или нет. 
-- Расчитать его значение. Вывести результаты
alter table test_employee
add column flag int;

with duoble_email as (
    select email from test_employee group by email having count(email) > 1
)

update test_employee
set flag = case when email in (select email from duoble_email) then 0 else 1 end 
returning id, email, flag;