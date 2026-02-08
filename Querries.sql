-- SQL query to create a new database named 'university_enrollment'
CREATE DATABASE university_enrollment;

-- ============================================
-- University Course Enrollment System
-- Database Setup for SQL JOINs & Window Functions Assignment
-- PostgreSQL Compatible
-- ============================================

-- 1. CREATE DATABASE (Run this separately first if needed)
-- CREATE DATABASE university_enrollment;

-- 2. CONNECT TO DATABASE then run below:

-- ============================================
-- STEP 3: DATABASE SCHEMA DESIGN
-- ============================================

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;

-- Create students table
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    major VARCHAR(50) NOT NULL,
    enrollment_date DATE NOT NULL
);

-- Create courses table
CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_code VARCHAR(10) UNIQUE NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    credits INT NOT NULL CHECK (credits > 0)
);

-- Create enrollments table
CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    semester VARCHAR(20) NOT NULL,
    grade DECIMAL(3,2) CHECK (grade >= 0 AND grade <= 4.0),
    enrollment_date DATE NOT NULL,
    
    -- Foreign key constraints
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    
    -- Ensure a student can't enroll in same course in same semester twice
    UNIQUE(student_id, course_id, semester)
);

-- ============================================
-- SAMPLE DATA INSERTION
-- ============================================

-- Insert sample students
INSERT INTO students (student_id, first_name, last_name, major, enrollment_date) VALUES
(1, 'Alice', 'Johnson', 'Computer Science', '2023-09-01'),
(2, 'Bob', 'Smith', 'Business', '2023-09-01'),
(3, 'Charlie', 'Brown', 'Computer Science', '2024-01-15'),
(4, 'Diana', 'Prince', 'Mathematics', '2023-09-01'),
(5, 'Ethan', 'Clark', 'Business', '2024-01-15'),
(6, 'Fiona', 'Green', 'Mathematics', '2023-09-01'),
(7, 'George', 'Miller', 'Computer Science', '2024-01-15'),
(8, 'Hannah', 'Davis', 'DBMS', '2023-09-01'); -- Student with no declared major

-- Insert sample courses
INSERT INTO courses (course_id, course_code, course_name, department, credits) VALUES
(101, 'INSY8311', 'Database Development', 'Computer Science', 3),
(102, 'BUSN7501', 'Business Analytics', 'Business', 3),
(103, 'MATH6101', 'Advanced Calculus', 'Mathematics', 4),
(104, 'INSY8320', 'Data Warehousing', 'Computer Science', 3),
(105, 'ECON7100', 'Microeconomics', 'Business', 3),
(106, 'PHYS6200', 'Quantum Physics', 'Physics', 4); -- Course with no enrollments

-- Insert sample enrollments with grades
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, grade, enrollment_date) VALUES
(1, 1, 101, 'Fall2025', 3.8, '2025-09-01'),
(2, 1, 104, 'Fall2025', 3.5, '2025-09-01'),
(3, 2, 102, 'Fall2025', 3.2, '2025-09-02'),
(4, 2, 105, 'Fall2025', 3.9, '2025-09-02'),
(5, 3, 101, 'Fall2025', 2.8, '2025-09-01'),
(6, 4, 103, 'Fall2025', 3.7, '2025-09-03'),
(7, 5, 102, 'Fall2025', 3.0, '2025-09-02'),
(8, 5, 105, 'Fall2025', 3.4, '2025-09-02'),
(9, 6, 103, 'Fall2025', 3.6, '2025-09-03'),
(10, 7, 101, 'Fall2025', 3.1, '2025-09-01'),
(11, 7, 104, 'Fall2025', 3.3, '2025-09-01'),
(12, 1, 103, 'Spring2026', NULL, '2026-01-15'), -- Ongoing course, no grade yet
(13, 2, 103, 'Spring2026', NULL, '2026-01-15'),
(14, 3, 102, 'Spring2026', NULL, '2026-01-16'),
(15, 4, 101, 'Spring2026', NULL, '2026-01-15');

-- ============================================
-- STEP 4: PART A - SQL JOINS IMPLEMENTATION
-- ============================================

-- 1. INNER JOIN: Retrieve enrollments with valid students and courses
-- Business Use: Get complete enrollment records with student and course details
SELECT 
    e.enrollment_id,
    s.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    s.major,
    c.course_code,
    c.course_name,
    e.semester,
    e.grade
FROM enrollments e
INNER JOIN students s ON e.student_id = s.student_id
INNER JOIN courses c ON e.course_id = c.course_id
WHERE e.semester = 'Fall2025'
ORDER BY e.grade DESC NULLS LAST;

-- 2. LEFT JOIN: Identify students who have never made an enrollment
-- Business Use: Find students who haven't enrolled in any courses (potential dropouts)
SELECT 
    s.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    s.major,
    s.enrollment_date AS student_enrollment_date
FROM students s
LEFT JOIN enrollments e ON s.student_id = e.student_id
WHERE e.enrollment_id IS NULL;

-- 3. RIGHT JOIN: Detect courses with no enrollment activity
-- Business Use: Identify unpopular courses that might need review or promotion
SELECT 
    c.course_id,
    c.course_code,
    c.course_name,
    c.department,
    c.credits
FROM enrollments e
RIGHT JOIN courses c ON e.course_id = c.course_id
WHERE e.enrollment_id IS NULL;

-- 4. FULL OUTER JOIN: Compare students and courses including unmatched records
-- Business Use: Comprehensive view of all students and courses, showing unenrolled students and unused courses
SELECT 
    COALESCE(s.student_id::TEXT, 'No Student') AS student_info,
    COALESCE(s.first_name || ' ' || s.last_name, 'N/A') AS student_name,
    COALESCE(c.course_code, 'No Course') AS course_info,
    COALESCE(c.course_name, 'N/A') AS course_name,
    CASE 
        WHEN e.enrollment_id IS NOT NULL THEN 'Enrolled'
        WHEN s.student_id IS NOT NULL AND e.enrollment_id IS NULL THEN 'Student Not Enrolled'
        WHEN c.course_id IS NOT NULL AND e.enrollment_id IS NULL THEN 'Course Not Taken'
        ELSE 'No Match'
    END AS status
FROM students s
FULL OUTER JOIN enrollments e ON s.student_id = e.student_id
FULL OUTER JOIN courses c ON e.course_id = c.course_id
WHERE (s.student_id IS NULL OR c.course_id IS NULL OR e.enrollment_id IS NULL)
ORDER BY s.student_id, c.course_id;

-- 5. SELF JOIN: Compare students within the same major and enrollment period
-- Business Use: Find students who enrolled in same semester and major for peer grouping
SELECT 
    s1.student_id AS student1_id,
    s1.first_name || ' ' || s1.last_name AS student1_name,
    s2.student_id AS student2_id,
    s2.first_name || ' ' || s2.last_name AS student2_name,
    s1.major,
    s1.enrollment_date
FROM students s1
INNER JOIN students s2 
    ON s1.major = s2.major 
    AND s1.enrollment_date = s2.enrollment_date
    AND s1.student_id < s2.student_id  -- Avoid duplicate pairs and self-join
WHERE s1.major IS NOT NULL
ORDER BY s1.major, s1.enrollment_date;

-- ============================================
-- STEP 5: PART B - WINDOW FUNCTIONS IMPLEMENTATION
-- ============================================

-- CATEGORY 1: RANKING FUNCTIONS
-- Top 5 courses by enrollment count per department
SELECT 
    department,
    course_code,
    course_name,
    enrollment_count,
    ROW_NUMBER() OVER(PARTITION BY department ORDER BY enrollment_count DESC) AS row_num,
    RANK() OVER(PARTITION BY department ORDER BY enrollment_count DESC) AS rank,
    DENSE_RANK() OVER(PARTITION BY department ORDER BY enrollment_count DESC) AS dense_rank,
    PERCENT_RANK() OVER(PARTITION BY department ORDER BY enrollment_count) AS percent_rank
FROM (
    SELECT 
        c.department,
        c.course_code,
        c.course_name,
        COUNT(e.enrollment_id) AS enrollment_count
    FROM courses c
    LEFT JOIN enrollments e ON c.course_id = e.course_id
    GROUP BY c.course_id, c.department, c.course_code, c.course_name
) AS course_stats
ORDER BY department, enrollment_count DESC
LIMIT 10;

-- CATEGORY 2: AGGREGATE WINDOW FUNCTIONS
-- Running total of enrollments per semester and department
SELECT 
    semester,
    department,
    monthly_enrollments,
    -- ROWS BETWEEN unbounded preceding and current row (default)
    SUM(monthly_enrollments) OVER(
        PARTITION BY department 
        ORDER BY semester 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_rows,
    -- RANGE BETWEEN unbounded preceding and current row
    SUM(monthly_enrollments) OVER(
        PARTITION BY department 
        ORDER BY semester 
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_range,
    AVG(monthly_enrollments) OVER(
        PARTITION BY department 
        ORDER BY semester 
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS centered_moving_avg
FROM (
    SELECT 
        e.semester,
        c.department,
        COUNT(e.enrollment_id) AS monthly_enrollments
    FROM enrollments e
    JOIN courses c ON e.course_id = c.course_id
    GROUP BY e.semester, c.department
) AS dept_enrollments
ORDER BY department, semester;

-- CATEGORY 3: NAVIGATION FUNCTIONS
-- Semester-over-semester enrollment growth per course
WITH course_semester_stats AS (
    SELECT 
        c.course_code,
        c.course_name,
        e.semester,
        COUNT(e.enrollment_id) AS enrollments,
        AVG(e.grade) AS avg_grade
    FROM enrollments e
    JOIN courses c ON e.course_id = c.course_id
    WHERE e.grade IS NOT NULL  -- Only completed courses
    GROUP BY c.course_id, c.course_code, c.course_name, e.semester
)
SELECT 
    course_code,
    course_name,
    semester,
    enrollments,
    avg_grade,
    LAG(enrollments, 1) OVER(PARTITION BY course_code ORDER BY semester) AS prev_semester_enrollments,
    enrollments - LAG(enrollments, 1) OVER(PARTITION BY course_code ORDER BY semester) AS enrollment_growth,
    LAG(avg_grade, 1) OVER(PARTITION BY course_code ORDER BY semester) AS prev_semester_avg_grade,
    avg_grade - LAG(avg_grade, 1) OVER(PARTITION BY course_code ORDER BY semester) AS grade_change,
    LEAD(enrollments, 1) OVER(PARTITION BY course_code ORDER BY semester) AS next_semester_enrollments
FROM course_semester_stats
ORDER BY course_code, semester;

-- CATEGORY 4: DISTRIBUTION FUNCTIONS
-- Student segmentation by GPA quartiles within their major
WITH student_gpa AS (
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        s.major,
        AVG(e.grade) AS cumulative_gpa,
        COUNT(e.enrollment_id) AS courses_completed
    FROM students s
    JOIN enrollments e ON s.student_id = e.student_id
    WHERE e.grade IS NOT NULL
        AND s.major IS NOT NULL
    GROUP BY s.student_id, s.first_name, s.last_name, s.major
    HAVING COUNT(e.enrollment_id) >= 2  -- Only students with at least 2 completed courses
)
SELECT 
    student_id,
    student_name,
    major,
    cumulative_gpa,
    courses_completed,
    -- NTILE divides students into 4 equal quartiles within each major
    NTILE(4) OVER(PARTITION BY major ORDER BY cumulative_gpa DESC) AS performance_quartile,
    -- CUME_DIST shows cumulative distribution (percentage of students with GPA <= current)
    CUME_DIST() OVER(PARTITION BY major ORDER BY cumulative_gpa) AS cumulative_distribution,
    CASE NTILE(4) OVER(PARTITION BY major ORDER BY cumulative_gpa DESC)
        WHEN 1 THEN 'Top Performer'
        WHEN 2 THEN 'Above Average'
        WHEN 3 THEN 'Average'
        WHEN 4 THEN 'Needs Improvement'
    END AS performance_segment
FROM student_gpa
ORDER BY major, cumulative_gpa DESC;

-- Complex example combining multiple window functions
-- 3-semester moving average of enrollments per course with rankings
SELECT 
    course_code,
    course_name,
    semester,
    semester_enrollments,
    AVG(semester_enrollments) OVER(
        PARTITION BY course_code 
        ORDER BY semester 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS three_semester_moving_avg,
    SUM(semester_enrollments) OVER(
        PARTITION BY course_code 
        ORDER BY semester 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_enrollments,
    RANK() OVER(PARTITION BY semester ORDER BY semester_enrollments DESC) AS semester_rank
FROM (
    SELECT 
        c.course_code,
        c.course_name,
        e.semester,
        COUNT(e.enrollment_id) AS semester_enrollments
    FROM enrollments e
    JOIN courses c ON e.course_id = c.course_id
    GROUP BY c.course_id, c.course_code, c.course_name, e.semester
) AS course_semester_data
ORDER BY course_code, semester;

-- ============================================
-- DATA VERIFICATION QUERIES
-- ============================================

-- Check table counts
SELECT 'students' AS table_name, COUNT(*) AS record_count FROM students
UNION ALL
SELECT 'courses', COUNT(*) FROM courses
UNION ALL
SELECT 'enrollments', COUNT(*) FROM enrollments;

-- View sample data from each table
SELECT * FROM students LIMIT 5;
SELECT * FROM courses LIMIT 5;
SELECT * FROM enrollments LIMIT 10;