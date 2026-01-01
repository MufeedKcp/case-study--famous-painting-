-- 1. Fetch all the paintings which are not displayed on any museums?
SELECT 
*
FROM work 
WHERE museum_id IS NULL;

-- 2. Are there museums without any paintings?
SELECT
M.museum_id,
M.name, 
city, 
country
FROM museum m
LEFT JOIN work w
	ON m.museum_id = w.museum_id
WHERE w.museum_id IS NULL;


-- 3. How many paintings have an asking price of more than their regular price?
SELECT
COUNT(DISTINCT work_id) AS Price_Greater_Than_Regular
FROM product_size
WHERE sale_price > regular_price;
    
    
-- 4. Which paintings are currently discounted by more than 45% from their regular prices?”
SELECT 
work_id,
MAX((regular_price - sale_price) / regular_price * 100)  AS DiscountPercentage
FROM product_size
GROUP BY work_id
HAVING MAX((regular_price - sale_price) / regular_price * 100) > 45;


-- 5. Which Canva size costs the most?
SELECT 
c.size_id,
p.sale_price
FROM canvas_size c
JOIN product_size p
	ON c.size_id = p.size_id 
WHERE sale_price = (SELECT MAX(sale_price) FROM product_size);


-- 6. Delete duplicate records from work, product_size, subject and image link tables

DELETE 
FROM image_link 
WHERE (work_id, url,thumbnail_small_url, thumbnail_large_url) IN (
SELECT 
	work_id, 
	url,thumbnail_small_url, 
	thumbnail_large_url
FROM(
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY work_id, url,thumbnail_small_url, thumbnail_large_url) AS DupRecords
	FROM image_link
) AS t
WHERE DupRecords > 1
);


DELETE 
FROM subject
WHERE (work_id, subject) IN (
SELECT 
	work_id,
    subject															
FROM(
	SELECT 
		work_id,
		subject,
		ROW_NUMBER() OVER (PARTITION BY work_id, subject ORDER BY work_id) AS DupRecords
	FROM subject
) AS t
WHERE DupRecords > 1
) ;


DELETE
FROM work
WHERE work_id IN (
SELECT *									
FROM(
SELECT 
ROW_NUMBER() OVER (PARTITION BY work_id ORDER BY work_id) AS DupRecords
FROM work
) AS t
WHERE DupRecords > 1
);



DELETE
FROM product_size
WHERE (work_id, size_id) IN (
SELECT 
	work_id,
	size_id									
FROM(
	SELECT 
		work_id,
		size_id,
		ROW_NUMBER() OVER (PARTITION BY work_id, size_id ORDER BY work_id) AS DupRecords
	FROM product_size
) AS t
WHERE DupRecords > 1
);


-- 7. Fetch the top 10 most famous painting subject
SELECT *
FROM (
SELECT 
subject,
COUNT(*) AS TotalSubject 
FROM subject
GROUP BY subject
) AS T 
ORDER BY TotalSubject DESC
LIMIT 10;


-- 8. Identify the museums which are open on both Sunday and Monday. Display museum name, city.
SELECT 
name,
city
FROM museum_hours h 
JOIN museum m 
	ON h.museum_id = m.museum_id 
WHERE h.museum_id IN (
	SELECT museum_id FROM museum_hours WHERE day = 'Sunday')
AND h.museum_id IN (
	SELECT museum_id FROM museum_hours WHERE day = 'Monday');
    
    
    
-- 9. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
SELECT
w.name,
COUNT(w.museum_id) AS TotalPaintingPerMuseum
FROM work w
JOIN museum m
	ON w.museum_id = m.museum_id
GROUP BY w.name
ORDER BY COUNT(museum_id) DESC
LIMIT 5;

-- 10. Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
SELECT 
a.full_name,
COUNT(*) AS TotalWorks
FROM work w
JOIN artist a
	ON w.artist_id = a.artist_id
GROUP BY a.full_name, a.artist_id
ORDER BY COUNT(*) DESC
LIMIT 5;

-- 11. Identify the artist and the museum where the most expensive painting is placed. 
-- Display the artist name, sale price, painting name, museum name, museum city.
SELECT 
	p.work_id,
	sale_price,
	w.name AS PaintingName,
	m.name AS MuseumName,
	full_name AS ArtistName
FROM product_size p 
JOIN work w 
	ON p.work_id = w.work_id
JOIN museum m
	ON w.museum_id = m.museum_id
JOIN artist a
	ON a.artist_id = w.artist_id
WHERE sale_price = (SELECT MAX(sale_price) FROM product_size);



-- 12.Which are the 3 most popular and 3 least popular painting styles?
WITH CTE_Style AS (
SELECT 
COALESCE(NULLIF(TRIM(style), ''), 'UNKNOWN') AS style,
COUNT(*) AS No_Of_Style,
ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS RankStyle,
ROW_NUMBER() OVER (ORDER BY COUNT(*) ASC) AS RankStyle2
FROM work
GROUP BY style
ORDER BY COUNT(*) DESC
) 
SELECT 
'Most_Popular_Style' AS Top_3,
style,
No_Of_Style
FROM CTE_Style
WHERE RankStyle <= 3

UNION ALL

SELECT 
'Least_Popular_Style' AS Top_3,
style,
No_Of_Style
FROM CTE_Style
WHERE RankStyle2 <= 3;

-- 12.Which country has the 5th highest no of paintings?
SELECT 
country,
COUNT(w.name) No_Of_Painting
FROM work w 
JOIN museum m 
	ON w.museum_id = m.museum_id
GROUP BY country
ORDER BY COUNT(w.name) DESC
LIMIT 1 OFFSET 4;


-- 13.Which artist has the most no of Portraits paintings outside USA?. 
-- Display artist name, no of paintings and the artist nationality.
SELECT 
	w.artist_id,
	full_name AS Artist_Name,
	nationality,
	COUNT(DISTINCT w.work_id) AS NO_Of_Painting
FROM work w 
JOIN artist a 
	ON w.artist_id = a.artist_id
JOIN museum m
	ON m.museum_id = w.museum_id
JOIN subject s 
	ON s.work_id = w.work_id
WHERE country != 'USA'
AND subject = 'Portraits'
GROUP BY w.artist_id,full_name, nationality
ORDER BY COUNT(DISTINCT w.work_id) DESC
LIMIT 1;


-- 14.Identify the artists whose paintings are displayed in multiple countries
SELECT 
a.artist_id,
full_name AS Artist_Name
FROM artist a 
JOIN work w 
	ON a.artist_id = w.artist_id
JOIN museum m 
	ON w.museum_id = m.museum_id
GROUP BY a.artist_id, full_name
HAVING COUNT(DISTINCT country) > 1;

-- 15. Which museum has the most no of most popular painting style?
WITH MostPopularStyle AS (
SELECT 
style
FROM work
GROUP BY style
ORDER BY COUNT(*) DESC 
LIMIT 1 
)
SELECT
	m.museum_id,
	M.name,
	S.style,
	COUNT(*) AS TotalStyle
FROM work w
JOIN museum m
    ON w.museum_id = m.museum_id
JOIN MostPopularStyle s
    ON w.style = s.style
GROUP BY m.museum_id, m.name, w.style
ORDER BY TotalStyle DESC
LIMIT 1;