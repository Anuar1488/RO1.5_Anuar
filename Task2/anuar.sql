CREATE SCHEMA IF NOT EXISTS airline_schema;

SET search_path TO airline_schema;

CREATE TABLE IF NOT EXISTS countries (
    id SERIAL PRIMARY KEY,
    name VARCHAR(60) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(60) NOT NULL
);

CREATE TABLE IF NOT EXISTS airport_list (
    id SERIAL PRIMARY KEY,
    code CHAR(3) UNIQUE NOT NULL,
    name VARCHAR(120) NOT NULL,
    city_id INT NOT NULL,
    country_id INT NOT NULL,
    FOREIGN KEY (city_id) REFERENCES cities(id),
    FOREIGN KEY (country_id) REFERENCES countries(id)
);

CREATE TABLE IF NOT EXISTS flight_routes (
    id SERIAL PRIMARY KEY,
    flight_code VARCHAR(25) UNIQUE NOT NULL,
    departure_airport INT NOT NULL,
    arrival_airport INT NOT NULL,
    FOREIGN KEY (departure_airport) REFERENCES airport_list(id),
    FOREIGN KEY (arrival_airport) REFERENCES airport_list(id)
);

CREATE TABLE IF NOT EXISTS plane_models (
    id SERIAL PRIMARY KEY,
    brand VARCHAR(60) NOT NULL,
    model VARCHAR(60) NOT NULL,
    seats_count INT CHECK (seats_count > 0)
);

CREATE TABLE IF NOT EXISTS planes (
    id SERIAL PRIMARY KEY,
    model_id INT NOT NULL,
    reg_number VARCHAR(20) UNIQUE NOT NULL,
    FOREIGN KEY (model_id) REFERENCES plane_models(id)
);

CREATE TABLE IF NOT EXISTS seat_map (
    id SERIAL PRIMARY KEY,
    plane_id INT NOT NULL,
    seat_no VARCHAR(10) NOT NULL,
    class_type VARCHAR(20) CHECK (class_type IN ('Economy','Business')),
    UNIQUE(seat_no),
    FOREIGN KEY (plane_id) REFERENCES planes(id)
);

CREATE TABLE IF NOT EXISTS flight_schedule (
    id SERIAL PRIMARY KEY,
    route_id INT NOT NULL,
    plane_id INT NOT NULL,
    dep_time TIMESTAMP NOT NULL,
    arr_time TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'Scheduled'
        CHECK (status IN ('Scheduled','Departed','Arrived','Cancelled','Delayed')),
    CHECK (dep_time > TIMESTAMP '2025-12-31'),
    FOREIGN KEY (route_id) REFERENCES flight_routes(id),
    FOREIGN KEY (plane_id) REFERENCES planes(id)
);

CREATE TABLE IF NOT EXISTS job_roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(40) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS staff (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role_id INT NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    iin BIGINT UNIQUE NOT NULL,
    FOREIGN KEY (role_id) REFERENCES job_roles(id)
);

CREATE TABLE IF NOT EXISTS crew_assignments (
    flight_id INT,
    staff_id INT,
    duty VARCHAR(40),
    PRIMARY KEY (flight_id, staff_id),
    FOREIGN KEY (flight_id) REFERENCES flight_schedule(id),
    FOREIGN KEY (staff_id) REFERENCES staff(id)
);

CREATE TABLE IF NOT EXISTS clients (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    passport VARCHAR(25) UNIQUE,
    email VARCHAR(60) UNIQUE
);

CREATE TABLE IF NOT EXISTS reservations (
    id SERIAL PRIMARY KEY,
    client_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_price NUMERIC(10,2) CHECK (total_price >= 0),
    FOREIGN KEY (client_id) REFERENCES clients(id)
);

CREATE TABLE IF NOT EXISTS tickets (
    id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL,
    flight_id INT NOT NULL,
    price NUMERIC(10,2) CHECK (price >= 0),
    FOREIGN KEY (reservation_id) REFERENCES reservations(id),
    FOREIGN KEY (flight_id) REFERENCES flight_schedule(id)
);

CREATE TABLE IF NOT EXISTS boarding_cards (
    id SERIAL PRIMARY KEY,
    ticket_id INT UNIQUE NOT NULL,
    seat_id INT NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id),
    FOREIGN KEY (seat_id) REFERENCES seat_map(id)
);

INSERT INTO countries (name) VALUES ('USA');

INSERT INTO cities (name) VALUES ('New York');

INSERT INTO airport_list (code, name, city_id, country_id)
VALUES ('JFK', 'John F Kennedy Airport', 1, 1);

INSERT INTO flight_routes (flight_code, departure_airport, arrival_airport)
VALUES ('AA101', 1, 1);

INSERT INTO plane_models (brand, model, seats_count)
VALUES ('Boeing', '737', 180);

INSERT INTO planes (model_id, reg_number)
VALUES (1, 'N12345');

INSERT INTO seat_map (plane_id, seat_no, class_type)
VALUES (1, '1A', 'Business');

INSERT INTO flight_schedule (route_id, plane_id, dep_time, arr_time, status)
VALUES (1, 1, '2026-02-01 10:00:00', '2026-02-01 14:00:00', 'Scheduled');

INSERT INTO job_roles (role_name)
VALUES ('Pilot');

INSERT INTO staff (first_name, last_name, role_id, phone_number, email, iin)
VALUES ('John', 'Doe', 1, '123456789', 'john@mail.com', 900101123456);

INSERT INTO crew_assignments (flight_id, staff_id, duty)
VALUES (1, 1, 'Captain');

INSERT INTO clients (first_name, last_name, passport, email)
VALUES ('Alice', 'Smith', 'AB123456', 'alice@mail.com');

INSERT INTO reservations (client_id, total_price)
VALUES (1, 500.00);

INSERT INTO tickets (reservation_id, flight_id, price)
VALUES (1, 1, 500.00);

INSERT INTO boarding_cards (ticket_id, seat_id)
VALUES (1, 1);