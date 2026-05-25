DROP USER IF EXISTS airline_admin_user;
DROP USER IF EXISTS airline_reader_user;
DROP ROLE IF EXISTS airline_admin;
DROP ROLE IF EXISTS airline_readonly;

CREATE ROLE airline_admin;
CREATE ROLE airline_readonly;

GRANT USAGE ON SCHEMA airline TO airline_admin;
GRANT USAGE ON SCHEMA airline TO airline_readonly;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA airline TO airline_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA airline TO airline_readonly;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA airline TO airline_admin;

CREATE USER airline_admin_user WITH PASSWORD 'airline_admin';
GRANT airline_admin TO airline_admin_user;
CREATE USER airline_reader_user WITH PASSWORD 'airline_reader';
GRANT airline_readonly TO airline_reader_user;

REVOKE UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA airline FROM airline_readonly;

SET search_path TO airline, public;

TRUNCATE TABLE 
    boarding_passes,
    tickets,
    bookings,
    passengers,
    flight_crew,
    flight_instances,
    employees,
    roles,
    seats,
    aircrafts,
    aircraft_models,
    flights,
    airports,
    city,
    country
RESTART IDENTITY CASCADE;

INSERT INTO country (country_name) VALUES
('Kazakhstan'),
('USA'),
('France'),
('Germany');

INSERT INTO city (city_name, country_id) VALUES
('Almaty', (SELECT country_id FROM country WHERE country_name = 'Kazakhstan')),
('Astana', (SELECT country_id FROM country WHERE country_name = 'Kazakhstan')),
('New York', (SELECT country_id FROM country WHERE country_name = 'USA')),
('Paris', (SELECT country_id FROM country WHERE country_name = 'France')),
('Frankfurt', (SELECT country_id FROM country WHERE country_name = 'Germany'));

INSERT INTO airports (iata_code, airport_name, city_id) VALUES
('ALA', 'Almaty International Airport', (SELECT city_id FROM city WHERE city_name = 'Almaty')),
('NQZ', 'Astana International Airport', (SELECT city_id FROM city WHERE city_name = 'Astana')),
('JFK', 'John F. Kennedy International Airport', (SELECT city_id FROM city WHERE city_name = 'New York')),
('CDG', 'Charles de Gaulle Airport', (SELECT city_id FROM city WHERE city_name = 'Paris')),
('FRA', 'Frankfurt Airport', (SELECT city_id FROM city WHERE city_name = 'Frankfurt'));

INSERT INTO flights (flight_number, dep_airport_id, arr_airport_id) VALUES
('KC101', (SELECT airport_id FROM airports WHERE iata_code = 'ALA'), (SELECT airport_id FROM airports WHERE iata_code = 'JFK')),
('KC202', (SELECT airport_id FROM airports WHERE iata_code = 'NQZ'), (SELECT airport_id FROM airports WHERE iata_code = 'CDG')),
('KC303', (SELECT airport_id FROM airports WHERE iata_code = 'ALA'), (SELECT airport_id FROM airports WHERE iata_code = 'FRA'));

INSERT INTO aircraft_models (manufacturer, model_name, capacity) VALUES
('Boeing', '787 Dreamliner', 250),
('Airbus', 'A320neo', 180),
('Embraer', 'E190-E2', 108);

INSERT INTO aircrafts (model_id, tail_number) VALUES
((SELECT model_id FROM aircraft_models WHERE model_name = '787 Dreamliner'), 'P4-KCA'),
((SELECT model_id FROM aircraft_models WHERE model_name = 'A320neo'), 'P4-KCB'),
((SELECT model_id FROM aircraft_models WHERE model_name = 'E190-E2'), 'P4-KCC');

INSERT INTO seats (aircraft_id, seat_number, seat_class) VALUES
((SELECT aircraft_id FROM aircrafts WHERE tail_number = 'P4-KCA'), '1A', 'Business'),
((SELECT aircraft_id FROM aircrafts WHERE tail_number = 'P4-KCA'), '12B', 'Economy'),
((SELECT aircraft_id FROM aircrafts WHERE tail_number = 'P4-KCB'), '1A', 'Business'),
((SELECT aircraft_id FROM aircrafts WHERE tail_number = 'P4-KCB'), '15C', 'Economy');

INSERT INTO roles (role_name) VALUES
('Pilot'),
('Co-Pilot'),
('Flight Attendant');

INSERT INTO employees (first_name, last_name, role_id, employee_number, email, iin) VALUES
('John', 'Doe', (SELECT role_id FROM roles WHERE role_name = 'Pilot'), 1001, 'john.doe@airline.com', 800101456789),
('Jane', 'Smith', (SELECT role_id FROM roles WHERE role_name = 'Co-Pilot'), 1002, 'jane.smith@airline.com', 900202123456),
('Anna', 'Lee', (SELECT role_id FROM roles WHERE role_name = 'Flight Attendant'), 1003, 'anna.lee@airline.com', 950303654321);

INSERT INTO flight_instances (flight_id, aircraft_id, departure_time, arrival_time, status) VALUES
((SELECT flight_id FROM flights WHERE flight_number = 'KC101'), (SELECT aircraft_id FROM aircrafts WHERE tail_number = 'P4-KCA'), '2026-06-01 10:00:00+00', '2026-06-01 22:00:00+00', 'Scheduled'),
((SELECT flight_id FROM flights WHERE flight_number = 'KC202'), (SELECT aircraft_id FROM aircrafts WHERE tail_number = 'P4-KCB'), '2026-07-15 08:00:00+00', '2026-07-15 14:00:00+00', 'Scheduled');

INSERT INTO flight_crew (instance_id, employee_id, assignment_role) VALUES
((SELECT instance_id FROM flight_instances WHERE departure_time = '2026-06-01 10:00:00+00'), (SELECT employee_id FROM employees WHERE employee_number = 1001), 'Captain'),
((SELECT instance_id FROM flight_instances WHERE departure_time = '2026-06-01 10:00:00+00'), (SELECT employee_id FROM employees WHERE employee_number = 1002), 'First Officer'),
((SELECT instance_id FROM flight_instances WHERE departure_time = '2026-06-01 10:00:00+00'), (SELECT employee_id FROM employees WHERE employee_number = 1003), 'Cabin Crew');

INSERT INTO passengers (first_name, last_name, passport_num, email) VALUES
('Michael', 'Johnson', 'N12345678', 'michael.j@example.com'),
('Emily', 'Davis', 'N87654321', 'emily.d@example.com');

INSERT INTO bookings (passenger_id, booking_date, amount) VALUES
((SELECT passenger_id FROM passengers WHERE passport_num = 'N12345678'), '2026-04-10 12:00:00+00', 1500.00),
((SELECT passenger_id FROM passengers WHERE passport_num = 'N87654321'), '2026-04-12 14:30:00+00', 800.00);

INSERT INTO tickets (booking_id, instance_id, fare) VALUES
((SELECT booking_id FROM bookings WHERE amount = 1500.00), (SELECT instance_id FROM flight_instances WHERE departure_time = '2026-06-01 10:00:00+00'), 1500.00),
((SELECT booking_id FROM bookings WHERE amount = 800.00), (SELECT instance_id FROM flight_instances WHERE departure_time = '2026-07-15 08:00:00+00'), 800.00);

-- 15. Посадочные талоны (Полностью исправлено: поиск места идет через связку с tail_number)
INSERT INTO boarding_passes (ticket_id, seat_id) VALUES
(
    (SELECT ticket_id FROM tickets WHERE fare = 1500.00), 
    (SELECT seat_id FROM seats WHERE seat_number = '1A' AND aircraft_id = (SELECT aircraft_id FROM aircrafts WHERE tail_number = 'P4-KCA'))
),
(
    (SELECT ticket_id FROM tickets WHERE fare = 800.00), 
    (SELECT seat_id FROM seats WHERE seat_number = '1A' AND aircraft_id = (SELECT aircraft_id FROM aircrafts WHERE tail_number = 'P4-KCB'))
);

-- Changing flight status in case of delay
SELECT flight_id, status AS status_before FROM flight_instances WHERE instance_id = 1;
UPDATE flight_instances SET status = 'Delayed' WHERE instance_id = 1;

-- Updating the ticket price for a specific booking
SELECT booking_id, fare AS fare_before FROM tickets WHERE ticket_id = 1;
UPDATE tickets SET fare = fare + 50.00 WHERE ticket_id = 1;

-- Bulk Upgrade (10% off all tickets for a specific flight using FROM/WHERE)
SELECT t.ticket_id, t.fare AS fare_before, f.flight_number 
FROM tickets t 
JOIN flight_instances fi ON t.instance_id = fi.instance_id
JOIN flights f ON fi.flight_id = f.flight_id 
WHERE f.flight_number = 'KC202';

UPDATE tickets t 
SET fare = t.fare * 0.90 
FROM flight_instances fi, flights f 
WHERE t.instance_id = fi.instance_id 
  AND fi.flight_id = f.flight_id 
  AND f.flight_number = 'KC202';

BEGIN;
UPDATE flight_instances SET status = 'Cancelled' WHERE instance_id = 2;
-- Simulating the deletion of linked boarding passes
DELETE FROM boarding_passes WHERE ticket_id IN (SELECT ticket_id FROM tickets WHERE instance_id = 2);
-- We make sure that the records inside the transaction have been deleted.
SELECT COUNT(*) AS remaining_passes FROM boarding_passes WHERE ticket_id IN (SELECT ticket_id FROM tickets WHERE instance_id = 2);
-- Roll back the transaction, returning the data to its place
ROLLBACK;