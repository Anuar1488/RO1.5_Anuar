-- ===== PART 1: ENVIRONMENT SETUP & RE-RUNNABLE HEADER =====

CREATE SCHEMA IF NOT EXISTS university_management;
SET search_path TO university_management, public;

-- ===== PART 2: CREATE TABLES & CONSTRAINTS =====

CREATE TABLE IF NOT EXISTS departments (
    department_id SERIAL,
    department_name VARCHAR(100) NOT NULL,
    building VARCHAR(50) NOT NULL DEFAULT 'Main Campus',
    CONSTRAINT pk_departments PRIMARY KEY (department_id),
    CONSTRAINT uq_department_name UNIQUE (department_name)
);

CREATE TABLE IF NOT EXISTS instructors (
    instructor_id SERIAL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(150) NOT NULL,
    department_id INT NOT NULL,
    salary NUMERIC(10,2) DEFAULT 3500.00,
    employment_status VARCHAR(20) NOT NULL DEFAULT 'Active',
    CONSTRAINT pk_instructors PRIMARY KEY (instructor_id),
    CONSTRAINT uq_instructor_email UNIQUE (email),
    CONSTRAINT fk_instructors_departments FOREIGN KEY (department_id) REFERENCES departments (department_id) ON DELETE RESTRICT,
    CONSTRAINT chk_instructors_status CHECK (employment_status IN ('Active', 'On Leave', 'Terminated'))
);

CREATE TABLE IF NOT EXISTS students (
    student_id SERIAL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_students PRIMARY KEY (student_id),
    CONSTRAINT uq_student_email UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS semesters (
    semester_id SERIAL,
    academic_year VARCHAR(9) NOT NULL, -- e.g., '2025-2026'
    term VARCHAR(10) NOT NULL,
    CONSTRAINT pk_semesters PRIMARY KEY (semester_id),
    CONSTRAINT chk_semesters_term CHECK (term IN ('fall', 'spring', 'summer'))
);

CREATE TABLE IF NOT EXISTS classrooms (
    classroom_id SERIAL,
    room_number VARCHAR(10) NOT NULL,
    capacity INT NOT NULL,
    status VARCHAR(20) DEFAULT 'available',
    CONSTRAINT pk_classrooms PRIMARY KEY (classroom_id),
    CONSTRAINT uq_room_number UNIQUE (room_number),
    CONSTRAINT chk_classrooms_capacity CHECK (capacity > 0)
);

CREATE TABLE IF NOT EXISTS courses (
    course_id SERIAL,
    course_code VARCHAR(10) NOT NULL,
    title VARCHAR(150) NOT NULL,
    lecture_hours INT NOT NULL,
    lab_hours INT NOT NULL,
    department_id INT NOT NULL,
    CONSTRAINT pk_courses PRIMARY KEY (course_id),
    CONSTRAINT uq_course_code UNIQUE (course_code),
    CONSTRAINT fk_courses_departments FOREIGN KEY (department_id) REFERENCES departments (department_id) ON DELETE RESTRICT,
    CONSTRAINT chk_courses_hours CHECK (lecture_hours >= 0 AND lab_hours >= 0)
);

-- Junction Table representing Schedule (Courses + Instructors + Semesters + Classrooms)
CREATE TABLE IF NOT EXISTS course_offerings (
    offering_id SERIAL,
    course_id INT NOT NULL,
    instructor_id INT NOT NULL,
	semester_id INT NOT NULL,
    classroom_id INT NOT NULL,
    slot_time VARCHAR(50) NOT NULL, -- e.g., 'Monday 09:00'
    CONSTRAINT pk_course_offerings PRIMARY KEY (offering_id),
    CONSTRAINT fk_offerings_courses FOREIGN KEY (course_id) REFERENCES courses (course_id) ON DELETE RESTRICT,
    CONSTRAINT fk_offerings_instructors FOREIGN KEY (instructor_id) REFERENCES instructors (instructor_id) ON DELETE RESTRICT,
    CONSTRAINT fk_offerings_semesters FOREIGN KEY (semester_id) REFERENCES semesters (semester_id) ON DELETE RESTRICT,
    CONSTRAINT fk_offerings_classrooms FOREIGN KEY (classroom_id) REFERENCES classrooms (classroom_id) ON DELETE RESTRICT
);

-- Bridge Table (Many-to-Many) between Students and Course Offerings
CREATE TABLE IF NOT EXISTS enrollments (
    enrollment_id SERIAL,
    student_id INT NOT NULL,
    offering_id INT NOT NULL,
    base_fee NUMERIC(10,2) NOT NULL DEFAULT 50000.00,
    discount_rate NUMERIC(3,2) NOT NULL DEFAULT 0.00,
    -- GENERATED ALWAYS AS STORED computed column requirement
    final_cost NUMERIC(10,2) GENERATED ALWAYS AS (base_fee * (1.00 - discount_rate)) STORED,
    registration_status VARCHAR(20) DEFAULT 'active',
    CONSTRAINT pk_enrollments PRIMARY KEY (enrollment_id),
    CONSTRAINT fk_enrollments_students FOREIGN KEY (student_id) REFERENCES students (student_id) ON DELETE CASCADE,
    CONSTRAINT fk_enrollments_offerings FOREIGN KEY (offering_id) REFERENCES course_offerings (offering_id) ON DELETE RESTRICT,
    CONSTRAINT chk_enrollments_discount CHECK (discount_rate >= 0.00 AND discount_rate <= 1.00)
);

CREATE TABLE IF NOT EXISTS grades (
    grade_id SERIAL,
    enrollment_id INT NOT NULL,
    grade_letter VARCHAR(2) NOT NULL, -- 'A', 'B+', 'F'
    grade_numeric NUMERIC(3,2) NOT NULL, -- GPA from 0.00 to 4.00
    CONSTRAINT pk_grades PRIMARY KEY (grade_id),
    CONSTRAINT uq_grades_enrollment UNIQUE (enrollment_id),
    CONSTRAINT fk_grades_enrollments FOREIGN KEY (enrollment_id) REFERENCES enrollments (enrollment_id) ON DELETE CASCADE,
    CONSTRAINT chk_grades_numeric CHECK (grade_numeric >= 0.00 AND grade_numeric <= 4.00)
);

-- ===== PART 3: ALTER TABLE OPERATIONS =====

-- 1. ALTER COLUMN TYPE: Extending length of classroom room numbers for complex wing-codes
ALTER TABLE classrooms ALTER COLUMN room_number TYPE VARCHAR(20);

-- 2. ADD COLUMN: Adding description text field to courses for syllabus overviews
ALTER TABLE courses ADD COLUMN IF NOT EXISTS syllabus_summary VARCHAR(250);

-- 3. ADD CONSTRAINT: Enforcing structural checks on student registration statuses
ALTER TABLE enrollments DROP CONSTRAINT IF EXISTS chk_enrollment_status;
ALTER TABLE enrollments ADD CONSTRAINT chk_enrollment_status CHECK (registration_status IN ('active', 'dropped', 'completed', 'cancelled'));

-- 4. SET DEFAULT: Upgrading the minimum default base fee floor for newly registered classes
ALTER TABLE enrollments ALTER COLUMN base_fee SET DEFAULT 60000.00;

-- 5. DROP COLUMN: Removing building from departments to avoid redundancy if handled globally later
ALTER TABLE departments DROP COLUMN IF EXISTS building;


-- ===== PART 4: DATA POPULATION (INSERT) =====

-- Clear existing records while resetting index counters
TRUNCATE TABLE grades, enrollments, course_offerings, courses, classrooms, semesters, students, instructors, departments RESTART IDENTITY CASCADE;

INSERT INTO departments (department_name) VALUES
('Computer Science & Engineering'),
('Mathematics & Statistics'),
('Data Science'),
('Physics'),
('Electrical Engineering');

INSERT INTO classrooms (room_number, capacity, status) VALUES
('Auditorium 101', 120, 'available'),
('Lab 204', 30, 'available'),
('Room 302', 45, 'available'),
('Room 305', 40, 'available'),
('Lab 108', 25, 'available');

-- ИМЕНА СТУДЕНТОВ СИНХРОНИЗИРОВАНЫ ДЛЯ ИЗБЕЖАНИЯ ОШИБОК ПОДЗАПРОСОВ
INSERT INTO students (first_name, last_name, email, enrollment_date) VALUES
('Aliyar', 'Amanov', 'aliyar.a@university.kz', '2026-02-01'),
('Dinara', 'Saparova', 'dinara.s@university.kz', '2026-02-01'),
('Anuar', 'Suleimenov', 'anuar.s@university.kz', '2026-02-15'),
('Ansar', 'Erzhanov', 'ansar.e@university.kz', '2026-02-15'),
('Olzhagul', 'Mukhitova', 'olzhagul.m@university.kz', '2026-02-20');

INSERT INTO instructors (first_name, last_name, email, department_id, salary, employment_status) VALUES
('Alex', 'Taylor', 'alex.taylor@university.kz', (SELECT department_id FROM departments WHERE department_name = 'Computer Science & Engineering'), 4500.00, 'Active'),
('Dmitry', 'Volkov', 'dmitry.volkov@university.kz', (SELECT department_id FROM departments WHERE department_name = 'Data Science'), 5000.00, 'Active'),
('Elena', 'Petrova', 'elena.petrova@university.kz', (SELECT department_id FROM departments WHERE department_name = 'Mathematics & Statistics'), 3800.00, 'Active'),
('Serik', 'Akhmetov', 'serik.akhmetov@university.kz', (SELECT department_id FROM departments WHERE department_name = 'Computer Science & Engineering'), 3900.00, 'Active'),
('Zarina', 'Umarova', 'zarina.umarova@university.kz', (SELECT department_id FROM departments WHERE department_name = 'Physics'), 4100.00, 'Active');

INSERT INTO semesters (academic_year, term) VALUES
('2025-2026', 'fall'),
('2025-2026', 'spring'),
('2026-2027', 'fall'),
('2026-2027', 'spring'),
('2026-2027', 'summer');

INSERT INTO courses (course_code, title, lecture_hours, lab_hours, department_id) VALUES
('CS101', 'Introduction to Computer Science', 30, 15, (SELECT department_id FROM departments WHERE department_name = 'Computer Science & Engineering')),
('CS302', 'Advanced Database Systems (SQL)', 45, 30, (SELECT department_id FROM departments WHERE department_name = 'Computer Science & Engineering')),
('DS201', 'Introduction to Data Science & Analytics', 30, 30, (SELECT department_id FROM departments WHERE department_name = 'Data Science')),
('MATH102', 'Calculus II', 45, 0, (SELECT department_id FROM departments WHERE department_name = 'Mathematics & Statistics')),
('PHYS101', 'General Physics I', 30, 15, (SELECT department_id FROM departments WHERE department_name = 'Physics'));

INSERT INTO course_offerings (course_id, instructor_id, semester_id, classroom_id, slot_time) VALUES
((SELECT course_id FROM courses WHERE course_code = 'CS101'), (SELECT instructor_id FROM instructors WHERE email = 'alex.taylor@university.kz'), (SELECT semester_id FROM semesters WHERE academic_year = '2025-2026' AND term = 'spring'), (SELECT classroom_id FROM classrooms WHERE room_number = 'Auditorium 101'), 'Monday 09:00'),
((SELECT course_id FROM courses WHERE course_code = 'CS302'), (SELECT instructor_id FROM instructors WHERE email = 'serik.akhmetov@university.kz'), (SELECT semester_id FROM semesters WHERE academic_year = '2025-2026' AND term = 'spring'), (SELECT classroom_id FROM classrooms WHERE room_number = 'Lab 204'), 'Tuesday 14:00'),
((SELECT course_id FROM courses WHERE course_code = 'DS201'), (SELECT instructor_id FROM instructors WHERE email = 'dmitry.volkov@university.kz'), (SELECT semester_id FROM semesters WHERE academic_year = '2025-2026' AND term = 'spring'), (SELECT classroom_id FROM classrooms WHERE room_number = 'Lab 108'), 'Wednesday 11:00'),
((SELECT course_id FROM courses WHERE course_code = 'MATH102'), (SELECT instructor_id FROM instructors WHERE email = 'elena.petrova@university.kz'), (SELECT semester_id FROM semesters WHERE academic_year = '2025-2026' AND term = 'spring'), (SELECT classroom_id FROM classrooms WHERE room_number = 'Room 302'), 'Thursday 09:00'),
((SELECT course_id FROM courses WHERE course_code = 'PHYS101'), (SELECT instructor_id FROM instructors WHERE email = 'zarina.umarova@university.kz'), (SELECT semester_id FROM semesters WHERE academic_year = '2025-2026' AND term = 'spring'), (SELECT classroom_id FROM classrooms WHERE room_number = 'Room 305'), 'Friday 13:00');

-- СВЯЗУЮЩИЕ ИМЕНА ИСПРАВЛЕНЫ И ССЫЛАЮТСЯ НА СТУДЕНТОВ ВЫШЕ
INSERT INTO enrollments (student_id, offering_id, base_fee, discount_rate, registration_status) VALUES
((SELECT student_id FROM students WHERE email = 'aliyar.a@university.kz'), 1, 55000.00, 0.10, 'active'),
((SELECT student_id FROM students WHERE email = 'aliyar.a@university.kz'), 2, 60000.00, 0.00, 'active'),
((SELECT student_id FROM students WHERE email = 'dinara.s@university.kz'), 2, 60000.00, 0.05, 'active'),
((SELECT student_id FROM students WHERE email = 'anuar.s@university.kz'), 2, 60000.00, 0.00, 'active'),
((SELECT student_id FROM students WHERE email = 'ansar.e@university.kz'), 2, 60000.00, 0.00, 'active'),
((SELECT student_id FROM students WHERE email = 'olzhagul.m@university.kz'), 2, 60000.00, 0.20, 'cancelled'),
((SELECT student_id FROM students WHERE email = 'anuar.s@university.kz'), 3, 58000.00, 0.00, 'active'),
((SELECT student_id FROM students WHERE email = 'ansar.e@university.kz'), 4, 50000.00, 0.15, 'active');

INSERT INTO grades (enrollment_id, grade_letter, grade_numeric) VALUES
(1, 'A', 4.00),
(2, 'B+', 3.50),
(3, 'A-', 3.67),
(4, 'B', 3.00),
(5, 'C+', 2.50);

-- ===== PART 6: GRANT + REVOKE (DCL AUTHORIZATION) =====

-- Manually revoke all privileges from previous runs to clear dependencies and prevent error 2BP01
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA university_management FROM university_management_readonly, university_management_writer;
REVOKE ALL PRIVILEGES ON SCHEMA university_management FROM university_management_readonly, university_management_writer;

-- Safely drop existing roles once their privileges are cleared so the script stays re-runnable
DROP ROLE IF EXISTS university_management_readonly;
DROP ROLE IF EXISTS university_management_writer;

-- 1. Create two roles for the university management domain
CREATE ROLE university_management_readonly;
CREATE ROLE university_management_writer;

-- Enable schema usage access for both roles to allow interaction with internal objects
GRANT USAGE ON SCHEMA university_management TO university_management_readonly;
GRANT USAGE ON SCHEMA university_management TO university_management_writer;

-- 2. Grant read-only access on all tables in the schema
GRANT SELECT ON ALL TABLES IN SCHEMA university_management TO university_management_readonly;

-- 3. Grant insert and update privileges on the main enrollment ledger table
GRANT INSERT, UPDATE ON university_management.enrollments TO university_management_writer;

-- 4. Revoke update privileges with a one-line comment explaining the business logic
-- The university_management_writer role represents front-office clerks; UPDATE was revoked to prevent manual tampering with financial base fees after initial student registration.
REVOKE UPDATE ON university_management.enrollments FROM university_management_writer;
-- ===== PART 5: UPDATE & DELETE STATEMENTS =====

-- UPDATE #1 (Simple): Mark classrooms as 'occupied' if they are listed in active scheduling slots
UPDATE classrooms
SET status = 'occupied'
WHERE classroom_id IN (SELECT classroom_id FROM course_offerings);

-- UPDATE #2 (Complex using Subquery/FROM): Implement a 5% inflation premium on base fees for all CS courses
UPDATE enrollments
SET base_fee = base_fee * 1.05
FROM course_offerings, courses, departments
WHERE enrollments.offering_id = course_offerings.offering_id
AND course_offerings.course_id = courses.course_id
AND courses.department_id = departments.department_id
AND departments.department_name = 'Computer Science & Engineering';

-- DELETE WITH TRANSACTION, RETURNING AND ROLLBACK
-- Business Case: Purging cancelled class registrations while verifying financial values before rollback demonstration
BEGIN;

DELETE FROM grades
WHERE enrollment_id IN (SELECT enrollment_id FROM enrollments WHERE registration_status = 'cancelled')
RETURNING grade_id, enrollment_id, grade_letter;

DELETE FROM enrollments
WHERE registration_status = 'cancelled'
RETURNING enrollment_id, student_id, final_cost, registration_status;

-- Explicit rollback to protect architecture demonstration state
ROLLBACK;