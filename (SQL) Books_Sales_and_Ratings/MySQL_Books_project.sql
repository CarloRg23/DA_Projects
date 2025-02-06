CREATE DATABASE IF NOT EXISTS books;

USE books;

CREATE TABLE books_details
(
id SMALLINT,
publishing_year SMALLINT,
book_name VARCHAR(255),
author VARCHAR(1000),
language_code VARCHAR(255),
author_rating VARCHAR(255),
book_average_rating DECIMAL(3,2),
book_ratings_count MEDIUMINT,
genre VARCHAR(255)
);

SELECT *
FROM books_details;

LOAD DATA INFILE 'Books_Details_(Edited).csv' INTO TABLE books_details
FIELDS TERMINATED BY ',' ENCLOSED BY '"'  
IGNORE 1 LINES
(id, @publishing_year, book_name, author, language_code, author_rating, book_average_rating, book_ratings_count, genre)
SET publishing_year = IF(@publishing_year='',NULL,@publishing_year);

CREATE TABLE books_sales
(
id SMALLINT,
gross_sales DECIMAL(10,2),
publisher_revenue DECIMAL(10,2),
sale_price DECIMAL(4,2),
sales_rank SMALLINT,
publisher VARCHAR(255),
units_sold MEDIUMINT
);


LOAD DATA INFILE 'Books_Sales_(Edited).csv' INTO TABLE books_sales
FIELDS TERMINATED BY ',' ENCLOSED BY '"'  
IGNORE 1 LINES;

SELECT *
FROM books_sales;

EXPLAIN books_sales;

-- Verifying same number of rows on each table
SELECT COUNT(*)
FROM books_details;

SELECT COUNT(*)
FROM books_sales;

-- Finding Duplicates and Joining Tables

WITH CTE_ROW_NUM AS(
SELECT ROW_NUMBER()OVER(PARTITION BY publishing_year, book_name, author, language_code,
author_rating, book_average_rating, book_ratings_count, genre, gross_sales, publisher_revenue,
sale_price, sales_rank, publisher, units_sold) AS row_num
FROM books_details AS bd
LEFT JOIN books_sales AS bs
	ON bd.id = bs.id
)

SELECT *
FROM CTE_ROW_NUM
WHERE row_num > 1;
-- There are no duplicate columns


-- Standardizing the data
SELECT *
FROM books_details
WHERE book_name LIKE ' %' OR book_name LIKE '% ';

SELECT TRIM(book_name)
FROM books_details
WHERE book_name LIKE ' %' OR book_name LIKE '% ';

SET SQL_SAFE_UPDATES = 0;
UPDATE books_details
SET book_name = TRIM(book_name);
SET SQL_SAFE_UPDATES = 1;

SELECT *
FROM books_details;

-- checking genres
SELECT DISTINCT genre
FROM books_details
WHERE genre LIKE 'genre fiction%';

-- combining genres
SET SQL_SAFE_UPDATES = 0;
UPDATE books_details
SET genre = 'fiction'
WHERE genre LIKE 'genre fiction%';
SET SQL_SAFE_UPDATES = 1;

-- there was a weird problem with the genre fields,
-- so i had to overwrite every field:
SET SQL_SAFE_UPDATES = 0;
UPDATE books_details
SET genre = 'nonfiction'
WHERE genre LIKE 'nonfiction%';
SET SQL_SAFE_UPDATES = 1;

SELECT DISTINCT publisher
FROM books_sales
GROUP BY publisher
ORDER BY publisher;

-- combining publishers
SET SQL_SAFE_UPDATES = 0;
UPDATE books_sales
SET publisher = 'HarperCollins Publishers'
WHERE publisher = 'HarperCollins Publishing';
SET SQL_SAFE_UPDATES = 1;

-- Looking for null and blank values
SELECT *
FROM books_sales
WHERE units_sold IS NULL
OR units_sold = '';

-- Number of existing books per genre
SELECT genre, COUNT(*) AS Number_of_books
FROM books_details
GROUP BY genre;

-- Book ratings
SELECT MAX(book_average_rating) AS Max_Rating,
	MIN(book_average_rating) AS Min_Rating,
    AVG(book_average_rating) AS Avg_rating
FROM books_details;

-- Ratings according to book prices
SELECT
CASE
	WHEN sale_price >= 10 THEN 'More than $10'
    WHEN sale_price < 10 AND sale_price >= 5 THEN 'Between $5 and $10'
    WHEN sale_price < 5 THEN 'Less than $5'
END AS Price, AVG(book_average_rating) AS book_average_rating
FROM books_details bd
LEFT JOIN books_sales bs
	ON  bd.id = bs.id
GROUP BY Price
;

-- Ratings according to genre
SELECT genre, AVG(book_average_rating)
FROM books_details
GROUP BY genre;

-- Units sold by genre
SELECT genre, AVG(units_sold)
FROM books_sales bs
JOIN books_details bd
	ON bs.id = bd.id
GROUP BY genre;

-- Top rated books by genre
SELECT genre, book_name, book_average_rating, Ranking
FROM (
	SELECT *, RANK()OVER(PARTITION BY genre ORDER BY book_average_rating DESC) AS Ranking
	FROM books_details
) AS r
WHERE Ranking = 1;

-- Units sold by publisher
SELECT publisher, SUM(units_sold) AS total_units_sold
FROM books_sales
GROUP BY publisher
ORDER BY total_units_sold DESC