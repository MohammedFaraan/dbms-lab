-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

DROP DATABASE IF EXISTS 02JST25UCS402_sailors;

CREATE DATABASE 02JST25UCS402_sailors;

USE 02JST25UCS402_sailors;


-- ============================================================
-- 2. CREATE SAILORS TABLE
-- ============================================================

CREATE TABLE SAILORS (
    sid INT PRIMARY KEY,
    sname VARCHAR(50) NOT NULL,
    rating INT,
    age INT
);


-- ============================================================
-- 3. CREATE BOAT TABLE
-- ============================================================

CREATE TABLE BOAT (
    bid INT PRIMARY KEY,
    bname VARCHAR(50) NOT NULL,
    color VARCHAR(50)
);


-- ============================================================
-- 4. CREATE RESERVES TABLE
-- ============================================================

CREATE TABLE RESERVES (
    sid INT NOT NULL,
    bid INT NOT NULL,
    res_date DATE NOT NULL,

    PRIMARY KEY (sid, bid, res_date),

    FOREIGN KEY (sid)
        REFERENCES SAILORS(sid)
        ON DELETE CASCADE,

    FOREIGN KEY (bid)
        REFERENCES BOAT(bid)
        ON DELETE CASCADE
);


-- ============================================================
-- 5. INSERT DATA INTO SAILORS
-- ============================================================

INSERT INTO SAILORS (sid, sname, rating, age)
VALUES
    (1, 'Albert', 8, 41),
    (2, 'Bob', 9, 45),
    (3, 'Charlie', 9, 49),
    (4, 'David', 8, 54),
    (5, 'Eve', 7, 59);

-- Test SAILORS table
SELECT * FROM SAILORS;


-- ============================================================
-- 6. INSERT DATA INTO BOAT
-- ============================================================

INSERT INTO BOAT (bid, bname, color)
VALUES
    (101, 'Boat1', 'Red'),
    (102, 'Boat2', 'Blue'),
    (103, 'Boat3', 'Green'),
    (104, 'Boat4', 'Yellow'),
    (105, 'Boat5', 'White');

-- Test BOAT table
SELECT * FROM BOAT;


-- ============================================================
-- 7. INSERT DATA INTO RESERVES
-- ============================================================

INSERT INTO RESERVES (sid, bid, res_date)
VALUES
    (1, 101, '2023-01-01'),
    (1, 102, '2023-02-01'),
    (1, 103, '2023-03-01'),
    (1, 104, '2023-04-01'),
    (1, 105, '2023-05-01'),

    (2, 101, '2023-02-01'),
    (3, 101, '2023-03-01'),
    (4, 101, '2023-04-01'),
    (5, 101, '2023-05-01'),

    (2, 102, '2023-02-01'),
    (3, 103, '2023-03-01'),
    (4, 104, '2023-04-01'),
    (5, 105, '2023-05-01');

-- Test RESERVES table
SELECT * FROM RESERVES;


-- ============================================================
-- QUERY 1
-- Find the colours of boats reserved by Albert
-- ============================================================

-- Method 1: Using JOIN

SELECT DISTINCT b.color
FROM BOAT b
JOIN RESERVES r
    ON b.bid = r.bid
JOIN SAILORS s
    ON r.sid = s.sid
WHERE s.sname = 'Albert';


-- Method 2: Using IN

SELECT DISTINCT b.color
FROM BOAT b
JOIN RESERVES r
    ON b.bid = r.bid
WHERE r.sid IN (
    SELECT s.sid
    FROM SAILORS s
    WHERE s.sname = 'Albert'
);


-- ============================================================
-- QUERY 2
-- Find all sailor IDs of sailors who have a rating of at least 8
-- OR have reserved boat 103
-- ============================================================

SELECT DISTINCT s.sid
FROM SAILORS s
LEFT JOIN RESERVES r
    ON s.sid = r.sid
WHERE s.rating >= 8
   OR r.bid = 103;


-- ============================================================
-- QUERY 3
-- Find the names of sailors who have NOT reserved a boat
-- whose name contains 'storm'
-- ============================================================

SELECT s.sname
FROM SAILORS s
WHERE s.sid NOT IN (
    SELECT r.sid
    FROM RESERVES r
    JOIN BOAT b
        ON r.bid = b.bid
    WHERE b.bname LIKE '%storm%'
)
ORDER BY s.sname ASC;


-- ============================================================
-- QUERY 4
-- Find the names of sailors who have reserved ALL boats
-- ============================================================

-- Method 1: Relational Division using NOT EXISTS

SELECT s.sname
FROM SAILORS s
WHERE NOT EXISTS (
    SELECT b.bid
    FROM BOAT b
    WHERE NOT EXISTS (
        SELECT r.bid
        FROM RESERVES r
        WHERE r.sid = s.sid
          AND r.bid = b.bid
    )
);


-- Method 2: Using GROUP BY and HAVING

SELECT s.sid, s.sname
FROM SAILORS s
JOIN RESERVES r
    ON s.sid = r.sid
GROUP BY s.sid, s.sname
HAVING COUNT(DISTINCT r.bid) = (
    SELECT COUNT(*)
    FROM BOAT
);


-- ============================================================
-- QUERY 5
-- Find the name and age of the oldest sailor
-- ============================================================

-- Approach 1: ORDER BY and LIMIT

SELECT sname, age
FROM SAILORS
ORDER BY age DESC
LIMIT 1;


-- Approach 2: Using MAX()

SELECT sname, age
FROM SAILORS
WHERE age = (
    SELECT MAX(age)
    FROM SAILORS
);


-- ============================================================
-- QUERY 6
-- For each boat reserved by at least 5 sailors aged >= 40,
-- find the boat ID and average age
-- ============================================================

SELECT
    r.bid AS boat_id,
    AVG(s.age) AS avg_age
FROM RESERVES r
JOIN SAILORS s
    ON r.sid = s.sid
WHERE s.age >= 40
GROUP BY r.bid
HAVING COUNT(DISTINCT r.sid) >= 5;


-- ============================================================
-- QUERY 7
-- Create a view showing boat details alongside the rating
-- of the reserving sailors
-- ============================================================

CREATE OR REPLACE VIEW ReservedBoatsByRating AS
SELECT 
    s.rating,
    s.sname AS sailor_name,
    b.bname AS boat_name,
    b.color
FROM SAILORS s
JOIN RESERVES r
    ON s.sid = r.sid
JOIN BOAT b
    ON r.bid = b.bid;


-- Test the view
SELECT *
FROM ReservedBoatsByRating
WHERE rating = 8;

-- ============================================================
-- QUERY 8
-- Trigger to prevent boats from being deleted if they
-- have active reservations
-- ============================================================

DELIMITER //

DROP TRIGGER IF EXISTS prevent_delete_active_reservations //

CREATE TRIGGER prevent_delete_active_reservations
BEFORE DELETE ON BOAT
FOR EACH ROW
BEGIN
    DECLARE reservation_count INT DEFAULT 0;

    SELECT COUNT(*)
    INTO reservation_count
    FROM RESERVES
    WHERE bid = OLD.bid;

    IF reservation_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Cannot delete a boat with active reservations';
    END IF;
END //

DELIMITER ;


-- ============================================================
-- TEST THE TRIGGER
-- ============================================================

DELETE FROM BOAT
WHERE bid = 103;
