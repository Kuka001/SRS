CREATE SCHEMA university;

CREATE TABLE university.teachers (
    teacher_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department_id INT NOT NULL,
    hire_date DATE DEFAULT CURRENT_DATE,
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE university.departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(100)
);

CREATE TABLE university.courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    department_id INT NOT NULL
);

CREATE TABLE university.students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE university.grades (
    grade_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    grade DECIMAL(5,2) CHECK (grade >= 0 AND grade <= 100) DEFAULT 0.00,
    grade_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE university.teachers_courses (
    teacher_id INT NOT NULL,
    course_id INT NOT NULL,
    PRIMARY KEY (teacher_id, course_id)
);

CREATE TABLE university.students_courses (
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    PRIMARY KEY (student_id, course_id)
);

ALTER TABLE university.teachers
ADD CONSTRAINT teachers_department
FOREIGN KEY (department_id) REFERENCES university.departments(department_id);

ALTER TABLE university.courses
ADD CONSTRAINT fk_courses_department
FOREIGN KEY (department_id) REFERENCES university.departments(department_id);

ALTER TABLE university.grades
ADD CONSTRAINT fk_grades_student
FOREIGN KEY (student_id) REFERENCES university.students(student_id);

ALTER TABLE university.grades
ADD CONSTRAINT fk_grades_course
FOREIGN KEY (course_id) REFERENCES university.courses(course_id);

ALTER TABLE university.teachers_courses
ADD CONSTRAINT fk_teachers_courses_teacher
FOREIGN KEY (teacher_id) REFERENCES university.teachers(teacher_id);

ALTER TABLE university.teachers_courses
ADD CONSTRAINT fk_teachers_courses_course
FOREIGN KEY (course_id) REFERENCES university.courses(course_id);

ALTER TABLE university.students_courses
ADD CONSTRAINT fk_students_courses_student
FOREIGN KEY (student_id) REFERENCES university.students(student_id);

ALTER TABLE university.students_courses
ADD CONSTRAINT fk_students_courses_course
FOREIGN KEY (course_id) REFERENCES university.courses(course_id);

-- 1. departments
INSERT INTO university.departments (department_name, location) VALUES
('Математика', 'А корпусы'),
('Физика', 'В корпусы'),
('Информатика', 'С корпусы');

-- 2. teachers
INSERT INTO university.teachers (first_name, last_name, department_id, hire_date, email) VALUES
('Иван', 'Иванов', 1, '2010-09-01', 'ivanov@example.com'),
('Петр', 'Петров', 2, '2012-09-01', 'petrov@example.com'),
('Сергей', 'Сергеев', 3, '2015-09-01', 'sergeev@example.com');

-- 3. courses
INSERT INTO university.courses (course_name, department_id) VALUES
('Алгебра', 1),
('Механика', 2),
('Бағдарламалау', 3);

-- 4. students
INSERT INTO university.students (first_name, last_name, enrollment_date, email) VALUES
('Алексей', 'Алексеев', '2020-09-01', 'alexeev@example.com'),
('Мария', 'Маринина', '2020-09-01', 'marinina@example.com'),
('Дмитрий', 'Дмитриев', '2020-09-01', 'dmitriev@example.com');

-- 5. teachers_courses
INSERT INTO university.teachers_courses (teacher_id, course_id) VALUES
(1, 1),
(2, 2),
(3, 3);

-- 6. students_courses
INSERT INTO university.students_courses (student_id, course_id) VALUES
(1, 1),
(1, 3),
(2, 2),
(3, 1),
(3, 3);

-- 7. grades (с исправленным типом DECIMAL(5,2))
INSERT INTO university.grades (student_id, course_id, grade, grade_date) VALUES
(1, 1, 85.5, '2021-01-15'),
(1, 3, 90.0, '2021-01-20'),
(2, 2, 78.0, '2021-01-18'),
(3, 1, 92.5, '2021-01-15'),
(3, 3, 88.0, '2021-01-20');


CREATE ROLE uni_admin;
CREATE ROLE teacher;
CREATE ROLE student;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA university TO uni_admin;
GRANT SELECT, INSERT, UPDATE ON university.teachers, university.courses, university.teachers_courses TO teacher;
GRANT SELECT ON university.courses, university.students_courses, university.grades TO student;

CREATE INDEX idx_teachers_department ON university.teachers(department_id);
CREATE INDEX idx_courses_department ON university.courses(department_id);
CREATE INDEX idx_grades_student ON university.grades(student_id);
CREATE INDEX idx_grades_course ON university.grades(course_id);
CREATE INDEX idx_teachers_courses_teacher ON university.teachers_courses(teacher_id);
CREATE INDEX idx_teachers_courses_course ON university.teachers_courses(course_id);
CREATE INDEX idx_students_courses_student ON university.students_courses(student_id);
CREATE INDEX idx_students_courses_course ON university.students_courses(course_id);


SELECT 
    tc.table_name AS "Таблица",
    kcu.column_name AS "Столбец",
    tc.constraint_type AS "Тип ограничения",
    tc.constraint_name AS "Имя ограничения",
    ccu.table_name AS "Связанная таблица",
    ccu.column_name AS "Связанный столбец",
    rc.update_rule AS "Правило обновления",
    rc.delete_rule AS "Правило удаления",
    chc.check_clause AS "Условие проверки"
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name 
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.referential_constraints rc 
    ON tc.constraint_name = rc.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON rc.unique_constraint_name = ccu.constraint_name
LEFT JOIN information_schema.check_constraints chc 
    ON tc.constraint_name = chc.constraint_name
WHERE tc.table_schema = 'university'
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;


SELECT 
    r.rolname AS "Рөл",
    n.nspname AS "Схема",
    pg_catalog.has_schema_privilege(r.rolname, n.nspname, 'USAGE') AS "Қолдану рұқсаты",
    pg_catalog.has_schema_privilege(r.rolname, n.nspname, 'CREATE') AS "Құру рұқсаты"
FROM pg_roles r
JOIN pg_namespace n ON n.nspname = 'university'
WHERE r.rolname IN ('uni_admin', 'teacher', 'student');


SET ROLE uni_admin;
SELECT t.first_name, t.last_name, d.department_name
FROM university.teachers t
JOIN university.departments d ON t.department_id = d.department_id;

SELECT s.first_name, s.last_name, c.course_name, g.grade
FROM university.students s
JOIN university.students_courses sc ON s.student_id = sc.student_id
JOIN university.courses c ON sc.course_id = c.course_id
LEFT JOIN university.grades g ON s.student_id = g.student_id AND c.course_id = g.course_id;

SELECT d.department_name, COUNT(t.teacher_id) as teacher_count
FROM university.departments d
JOIN university.teachers t ON d.department_id = t.department_id
GROUP BY d.department_name
HAVING COUNT(t.teacher_id) > 1;

SET enable_seqscan = OFF;
EXPLAIN ANALYSE SELECT * FROM university.grades WHERE student_id = 1;

SELECT c.course_name, AVG(g.grade) as average_grade
FROM university.courses c
JOIN university.grades g ON c.course_id = g.course_id
GROUP BY c.course_name;