--Вывести к каждому самолету класс обслуживания и количество мест этого класса

SELECT ad.model->>'ru' AS model, ad.aircraft_code, s.fare_conditions, count(fare_conditions ) AS quantity
FROM aircrafts_data ad
JOIN seats s
ON ad.aircraft_code = s.aircraft_code
GROUP BY ad.model, ad.aircraft_code, s.fare_conditions
ORDER BY ad.model;

--Найти 3 самых вместительных самолета (модель + кол-во мест)

SELECT ad.model->>'ru' AS model, count(seat_no) AS seat_quantity
FROM aircrafts_data ad
JOIN seats s
ON ad.aircraft_code = s.aircraft_code
GROUP BY ad.model
ORDER BY count(seat_no) DESC
LIMIT 3;

--Вывести код,модель самолета и места не эконом класса для самолета 'Аэробус A321-200' с сортировкой по местам

SELECT ad.aircraft_code, ad.model->>'ru' AS model , s.seat_no, s.fare_conditions
FROM aircrafts_data ad
JOIN seats s
ON ad.aircraft_code = s.aircraft_code
WHERE ad.model @> '{"ru":"Аэробус A321-200"}'
AND s.fare_conditions NOT LIKE 'Economy'
ORDER BY s.seat_no;

--Вывести города в которых больше 1 аэропорта ( код аэропорта, аэропорт, город)
SELECT ad.airport_code, ad.airport_name->'ru' AS airport_name, ad.city->>'ru' AS city
FROM airports_data ad
WHERE ad.city IN (
	SELECT ad.city
	FROM airports_data ad
	GROUP BY ad.city
	HAVING count(ad.city) > 1);

-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

SELECT
	f.flight_id,
	f.flight_no,
	f.scheduled_departure,
	f.scheduled_arrival,
	f.departure_airport,
	f.arrival_airport,
	f.status,
	f.aircraft_code,
	f.actual_departure,
	f.actual_arrival
FROM
	flights f
WHERE
	f.departure_airport IN (
		SELECT ad.airport_code
		FROM airports_data ad
		WHERE ad.city @> '{"ru":"Екатеринбург"}'
	)
	AND f.arrival_airport IN (
		SELECT ad.airport_code
		FROM airports_data ad
		WHERE ad.city @> '{"ru":"Москва"}'
	)
	AND (f.status LIKE 'Scheduled' OR f.status LIKE 'On Time' OR f.status LIKE 'Delayed')
ORDER BY
	f.scheduled_departure
LIMIT 1;

--Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)

SELECT ticket_no, flight_id, fare_conditions, amount, note
	FROM
		(
		SELECT tf.ticket_no, tf.flight_id, tf.fare_conditions, tf.amount, 'min price' AS note
		FROM ticket_flights tf
		ORDER BY tf.amount
		LIMIT 1
		) AS cheapest
UNION
SELECT ticket_no, flight_id, fare_conditions, amount, note
	FROM
		(
		SELECT tf.ticket_no, tf.flight_id, tf.fare_conditions, tf.amount, 'max price' AS note
		FROM ticket_flights tf
		ORDER BY tf.amount DESC
		LIMIT 1
		) AS "most expensive";


--Написать DDL таблицы Customers, должны быть поля id , firstName, LastName, email, phone. Добавить ограничения на поля (constraints).

CREATE TABLE IF NOT EXISTS customers (
	customer_id BIGSERIAL PRIMARY KEY,
	first_name VARCHAR (30),
	last_name VARCHAR (30),
	email VARCHAR (40) UNIQUE NOT NULL,
	phone CHAR (9)
);

ALTER TABLE customers
	ADD CONSTRAINT email_regex
		CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
	ADD CONSTRAINT phone_unq UNIQUE (phone);

--Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + ограничения

CREATE TABLE IF NOT EXISTS orders (
	order_id BIGSERIAL PRIMARY KEY,
	customer_id BIGINT NOT NULL REFERENCES customers,
	quantity SMALLINT,
	CONSTRAINT quantity CHECK (quantity > 0));

-- Написать 5 insert в эти таблицы
INSERT INTO customers (first_name, last_name, email, phone)
VALUES
	('Nick', 'Johnson', 'nick@gmail.com', '291234567'),
	('Mike', 'November', 'mike@gmail.com', '331234567'),
	('Ivan', 'Ivanov', 'ivan@gmail.com', '152134567'),
	('Peter', 'Ferdinand', 'peter@gmail.com', '441234567'),
	('Alex', 'Gor', 'gor@gmail.com', '171234567');

INSERT INTO orders (customer_id, quantity)
VALUES
	((SELECT c.customer_id FROM customers c WHERE c.email = 'nick@gmail.com'), 2),
	((SELECT c.customer_id FROM customers c WHERE c.email = 'mike@gmail.com'), 1),
	((SELECT c.customer_id FROM customers c WHERE c.email = 'ivan@gmail.com'), 5),
	((SELECT c.customer_id FROM customers c WHERE c.email = 'peter@gmail.com'), 2),
	((SELECT c.customer_id FROM customers c WHERE c.email = 'gor@gmail.com'), 12);

-- удалить таблицы

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

--Написать свой кастомный запрос ( rus + sql)
-- получить сведения о количестве выплаченных неустоек пассажирам в период c 17.07.2017 по 23.07.2017 в связи с задержкой времени прилета к месту назначения (неустойка выплачивается в случае опоздания рейса более чем на 3 часа)

SELECT count(tf.ticket_no)
FROM ticket_flights tf
JOIN flights f
ON tf.flight_id = f.flight_id
WHERE (f.actual_arrival BETWEEN '2017-07-17' AND '2017-07-24')
AND (
	(date_part('day', f.actual_arrival - f.scheduled_arrival) * 24 +
	date_part('hour',  f.actual_arrival - f.scheduled_arrival)) > 3
	);