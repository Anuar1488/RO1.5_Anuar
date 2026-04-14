DROP SCHEMA IF EXISTS airline CASCADE;
CREATE SCHEMA airline;
SET search_path TO airline;

CREATE TABLE IF NOT EXISTS country (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS city (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(60) NOT NULL,
    country_id INT NOT NULL,
    FOREIGN KEY (country_id) REFERENCES country(country_id)
);

CREATE TABLE IF NOT EXISTS airports (
    airport_id SERIAL PRIMARY KEY,
    iata_code CHAR(3) NOT NULL UNIQUE,
    airport_name VARCHAR(100) NOT NULL,
    city_id INT NOT NULL,
    FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE IF NOT EXISTS flights (
    flight_id SERIAL PRIMARY KEY,
    flight_number VARCHAR(20) NOT NULL UNIQUE,
    dep_airport_id INT NOT NULL,
    arr_airport_id INT NOT NULL,
    CHECK (dep_airport_id <> arr_airport_id),
    FOREIGN KEY (dep_airport_id) REFERENCES airports(airport_id),
    FOREIGN KEY (arr_airport_id) REFERENCES airports(airport_id)
);

CREATE TABLE IF NOT EXISTS aircraft_models (
    model_id SERIAL PRIMARY KEY,
    manufacturer VARCHAR(50) NOT NULL,
    model_name VARCHAR(50) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0)
);

CREATE TABLE IF NOT EXISTS aircrafts (
    aircraft_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    model_id INT NOT NULL,
    tail_number VARCHAR(15) NOT NULL UNIQUE,
    FOREIGN KEY (model_id) REFERENCES aircraft_models(model_id)
);

CREATE TABLE IF NOT EXISTS seats (
    seat_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    aircraft_id INT NOT NULL,
    seat_number VARCHAR(10) NOT NULL,
    seat_class VARCHAR(20) NOT NULL CHECK (seat_class IN ('Economy', 'Business')),
    UNIQUE (aircraft_id, seat_number),
    FOREIGN KEY (aircraft_id) REFERENCES aircrafts(aircraft_id)
);

CREATE TABLE IF NOT EXISTS roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role_id INT NOT NULL,
    employee_number INT NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    iin BIGINT NOT NULL UNIQUE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE TABLE IF NOT EXISTS flight_instances (
    instance_id SERIAL PRIMARY KEY,
    flight_id INT NOT NULL,
    aircraft_id INT NOT NULL,
    departure_time TIMESTAMPTZ NOT NULL,
    arrival_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Scheduled',
    CHECK (departure_time > TIMESTAMPTZ '2026-01-01 00:00:00+00'),
    CHECK (arrival_time > departure_time),
    CHECK (status IN ('Scheduled','Departed','Arrived','Cancelled','Delayed')),
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id),
    FOREIGN KEY (aircraft_id) REFERENCES aircrafts(aircraft_id)
);

CREATE TABLE IF NOT EXISTS flight_crew (
    instance_id INT NOT NULL,
    employee_id INT NOT NULL,
    assignment_role VARCHAR(30) NOT NULL,
    PRIMARY KEY (instance_id, employee_id),
    FOREIGN KEY (instance_id) REFERENCES flight_instances(instance_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE IF NOT EXISTS passengers (
    passenger_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    passport_num VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS bookings (
    booking_id SERIAL PRIMARY KEY,
    passenger_id INT NOT NULL,
    booking_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id)
);

CREATE TABLE IF NOT EXISTS tickets (
    ticket_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    instance_id INT NOT NULL,
    fare NUMERIC(10,2) NOT NULL CHECK (fare >= 0),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (instance_id) REFERENCES flight_instances(instance_id)
);

CREATE TABLE IF NOT EXISTS boarding_passes (
    pass_id SERIAL PRIMARY KEY,
    ticket_id INT NOT NULL UNIQUE,
    seat_id INT NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id),
    FOREIGN KEY (seat_id) REFERENCES seats(seat_id)
);

INSERT INTO country (country_name) VALUES
('Kazakhstan'),
('USA'),
('France')
ON CONFLICT (country_name) DO NOTHING;

INSERT INTO city (city_name, country_id) VALUES
('Almaty', 1),
('Astana', 1),
('New York', 2),
('Paris', 3)
ON CONFLICT DO NOTHING;

INSERT INTO airports (iata_code, airport_name, city_id) VALUES
('ALA', 'Almaty International Airport', 1),
('NQZ', 'Astana International Airport', 2),
('JFK', 'John F. Kennedy International Airport', 3),
('CDG', 'Charles de Gaulle Airport', 4)
ON CONFLICT (iata_code) DO NOTHING;

INSERT INTO flights (flight_number, dep_airport_id, arr_airport_id) VALUES
('KC101', 1, 3),
('KC202', 2, 4)
ON CONFLICT (flight_number) DO NOTHING;

INSERT INTO aircraft_models (manufacturer, model_name, capacity) VALUES
('Boeing', '787 Dreamliner', 250),
('Airbus', 'A320neo', 180)
ON CONFLICT DO NOTHING;

INSERT INTO aircrafts (model_id, tail_number) VALUES
(1, 'P4-KCA'),
(2, 'P4-KCB')
ON CONFLICT (tail_number) DO NOTHING;

INSERT INTO seats (aircraft_id, seat_number, seat_class) VALUES
(1, '1A', 'Business'),
(1, '12B', 'Economy'),
(2, '1A', 'Business'),
(2, '15C', 'Economy')
ON CONFLICT (aircraft_id, seat_number) DO NOTHING;

INSERT INTO roles (role_name) VALUES
('Pilot'),
('Co-Pilot'),
('Flight Attendant')
ON CONFLICT (role_name) DO NOTHING;

INSERT INTO employees (first_name, last_name, role_id, employee_number, email, iin) VALUES
('John', 'Doe', 1, 1001, 'john.doe@airline.com', 800101456789),
('Jane', 'Smith', 2, 1002, 'jane.smith@airline.com', 900202123456),
('Anna', 'Lee', 3, 1003, 'anna.lee@airline.com', 950303654321)
ON CONFLICT (email) DO NOTHING;

INSERT INTO flight_instances (flight_id, aircraft_id, departure_time, arrival_time, status) VALUES
(1, 1, '2026-06-01 10:00:00+00', '2026-06-01 22:00:00+00', 'Scheduled'),
(2, 2, '2026-07-15 08:00:00+00', '2026-07-15 14:00:00+00', 'Scheduled')
ON CONFLICT DO NOTHING;

INSERT INTO flight_crew (instance_id, employee_id, assignment_role) VALUES
(1, 1, 'Captain'),
(1, 2, 'First Officer'),
(1, 3, 'Cabin Crew'),
(2, 1, 'Captain')
ON CONFLICT DO NOTHING;

INSERT INTO passengers (first_name, last_name, passport_num, email) VALUES
('Michael', 'Johnson', 'N12345678', 'michael.j@example.com'),
('Emily', 'Davis', 'N87654321', 'emily.d@example.com')
ON CONFLICT (passport_num) DO NOTHING;

INSERT INTO bookings (passenger_id, booking_date, amount) VALUES
(1, '2026-04-10 12:00:00+00', 1500.00),
(2, '2026-04-12 14:30:00+00', 800.00)
ON CONFLICT DO NOTHING;

INSERT INTO tickets (booking_id, instance_id, fare) VALUES
(1, 1, 1500.00),
(2, 2, 800.00)
ON CONFLICT DO NOTHING;

INSERT INTO boarding_passes (ticket_id, seat_id) VALUES
(1, 1),
(2, 3)
ON CONFLICT (ticket_id) DO NOTHING