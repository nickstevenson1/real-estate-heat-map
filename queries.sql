
-- Query that returns the average price of each neighborhood over all years.
SELECT n.name, avg(sale_price) FROM property
    JOIN neighborhood n ON nbhd_1 = n.number
    JOIN d_class d ON d.id = d_class
WHERE d.name LIKE 'RESIDENTIAL%'
GROUP BY n.name;


-- Query that returns the neighborhood name, avg price, year of price.
-- Ordered by year of avg_price
SELECT n.name, avg(sale_price) AS avg_price, extract(year FROM reception_date) AS year 
    FROM property
    JOIN neighborhood n ON n.number = nbhd_1
    JOIN d_class d ON d.id = d_class
WHERE d.name LIKE 'RESIDENTIAL%' and extract(year FROM reception_date) > 2010
GROUP BY n.name, extract(year FROM reception_date)
ORDER BY extract(year FROM reception_date);


-- Query returns the price growth of each neighborhood each year.
-- Ordered by neighborhood name, then by year.
SELECT n.name AS name, 
    (avg(sale_price) - lag(avg(sale_price)) over 
    (ORDER BY n.name, extract(year FROM reception_date))) / (lag(avg(sale_price)) 
    over (ORDER BY n.name, extract(year FROM reception_date)) + 1) AS price_growth, 
    extract(year FROM reception_date) AS year 
    FROM property
    JOIN neighborhood n ON n.number = nbhd_1
    JOIN d_class d ON d.id = d_class
WHERE d.name LIKE 'RESIDENTIAL%' and extract(year FROM reception_date) > 2010
GROUP BY n.name, extract(year FROM reception_date) 
ORDER BY n.name, extract(year FROM reception_date);


-- Query that returns the average price group of each neighborhood over
-- all years. This query is used in our map visualization.
SELECT c.name, avg(price_growth) AS avg_price_growth FROM
    (SELECT n.name AS name, 
        (avg(sale_price) - lag(avg(sale_price)) over 
        (ORDER BY n.name, extract(year FROM reception_date))) / (lag(avg(sale_price)) 
        over (ORDER BY n.name, extract(year FROM reception_date)) + 1) AS price_growth, 
        extract(year FROM reception_date) AS year 
        FROM property
        JOIN neighborhood n ON n.number = nbhd_1
        JOIN d_class d ON d.id = d_class
    WHERE d.name LIKE 'RESIDENTIAL%' and extract(year FROM reception_date) > 2010
    GROUP BY n.name, extract(year FROM reception_date) 
    ORDER BY n.name, extract(year FROM reception_date)) AS c
WHERE c.price_growth < 10
GROUP BY c.name;


-- Query that returns the correlation between airbnb price and residential properties
-- by neighborhood.
SELECT corr("a_price", "p_price") FROM 
    (SELECT airbnb_avg_price.name, airbnb_avg_price.avg_price a_price, 
    avg_prop_price.avg_price p_price FROM
        (SELECT n.name, avg(sale_price) AS avg_price FROM property
            JOIN neighborhood n ON n.number = nbhd_1
            JOIN d_class d ON d.id = d_class
        WHERE extract(year FROM reception_date) > 2010 and d.name LIKE 'RESIDENTIAL%'
        GROUP BY n.name) AS avg_prop_price,
        (SELECT neighborhood AS name, avg(cast(price AS numeric)) AS avg_price 
            FROM airbnb
        GROUP BY neighborhood) AS airbnb_avg_price
    WHERE UPPER(avg_prop_price.name) = UPPER(airbnb_avg_price.name)) AS prices;