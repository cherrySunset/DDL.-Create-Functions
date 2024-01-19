--1
CREATE VIEW sales_revenue_by_category_qtr AS
WITH CurrentQuarterSales AS (
    SELECT
    fc.category_id,
    SUM(p.amount) AS total_sales
    FROM
    payment p
        JOIN rental r ON p.rental_id = r.rental_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN film_category fc ON f.film_id = fc.film_id
    WHERE
        EXTRACT(QUARTER FROM r.rental_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
        AND EXTRACT(YEAR FROM r.rental_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY
        fc.category_id
)
SELECT
cqs.category_id,
cqs.total_sales,
c.name AS category_name
FROM
    CurrentQuarterSales cqs
    JOIN category c ON cqs.category_id = c.category_id;

--2
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(current_quarter INT)
RETURNS TABLE (
    category_id INT,
    total_sales NUMERIC,
    category_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    WITH CurrentQuarterSales AS (
        SELECT
        fc.category_id,
        SUM(p.amount) AS total_sales
        FROM
           payment p
            JOIN rental r ON p.rental_id = r.rental_id
            JOIN inventory i ON r.inventory_id = i.inventory_id
            JOIN film f ON i.film_id = f.film_id
            JOIN film_category fc ON f.film_id = fc.film_id
        WHERE
            EXTRACT(QUARTER FROM r.rental_date) = current_quarter
            AND EXTRACT(YEAR FROM r.rental_date) = EXTRACT(YEAR FROM CURRENT_DATE)
        GROUP BY
            fc.category_id
    )
    SELECT
    cqs.category_id,
    cqs.total_sales,
    c.name AS category_name
    FROM
        CurrentQuarterSales cqs
        JOIN category c ON cqs.category_id = c.category_id;
END;
$$ LANGUAGE plpgsql;
--calling of function
SELECT * FROM get_sales_revenue_by_category_qtr(1);

--3
CREATE OR REPLACE PROCEDURE new_movie(
    IN movie_title VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    new_film_id INT;
BEGIN
    SELECT COALESCE(MAX(film_id), 0) + 1 INTO new_film_id FROM film;
    IF NOT EXISTS (SELECT 1 FROM language WHERE name = 'Klingon') THEN
        RAISE EXCEPTION 'Language "Klingon" does not exist in the "language" table.';
    END IF;
    INSERT INTO film (
        film_id,
        title,
        rental_rate,
        rental_duration,
        replacement_cost,
        release_year,
        language_id
    ) VALUES (
        new_film_id,
        movie_title,
        4.99,
        3,
        19.99,
        EXTRACT(YEAR FROM CURRENT_DATE),
        (SELECT language_id FROM language WHERE name = 'Klingon')
    );

    COMMIT;
END;
$$;
--calling of function
CALL new_movie('new_movie');

