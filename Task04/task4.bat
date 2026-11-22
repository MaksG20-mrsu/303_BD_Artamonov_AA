#!/bin/bash
set -e
cd -- "$(dirname -- "$0")"
if command -v chcp.com >/dev/null 2>&1; then
    chcp.com 65001 >/dev/null
fi

sqlite3 -bail movies_rating.db < db_init.sql

echo "1. Первые 100 уникальных пар пользователей, оценивших один и тот же фильм."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
WITH movie_users AS (
    SELECT DISTINCT movie_id, user_id
    FROM ratings
)
SELECT u1.name AS first_user, u2.name AS second_user, m.title
FROM movie_users AS a
JOIN movie_users AS b ON b.movie_id = a.movie_id AND a.user_id < b.user_id
JOIN users AS u1 ON u1.id = a.user_id
JOIN users AS u2 ON u2.id = b.user_id
JOIN movies AS m ON m.id = a.movie_id
ORDER BY m.title, m.id, a.user_id, b.user_id
LIMIT 100;
"
echo ""

echo "2. Десять самых свежих оценок от разных пользователей."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
WITH recent_ratings AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id ORDER BY timestamp DESC, id DESC
           ) AS row_number
    FROM ratings
)
SELECT m.title, u.name, r.rating, date(r.timestamp, 'unixepoch') AS rating_date
FROM recent_ratings AS r
JOIN movies AS m ON m.id = r.movie_id
JOIN users AS u ON u.id = r.user_id
WHERE r.row_number = 1
ORDER BY r.timestamp DESC, r.id DESC
LIMIT 10;
"
echo ""

echo "3. Фильмы с максимальной и минимальной средней оценкой."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
WITH movie_averages AS (
    SELECT movie_id, AVG(rating) AS average_rating
    FROM ratings
    GROUP BY movie_id
),
rating_bounds AS (
    SELECT MIN(average_rating) AS minimum, MAX(average_rating) AS maximum
    FROM movie_averages
)
SELECT m.title, m.year, a.average_rating,
       CASE WHEN a.average_rating = b.maximum THEN 'Да' ELSE 'Нет' END AS \"Рекомендуем\"
FROM movie_averages AS a
JOIN movies AS m ON m.id = a.movie_id
CROSS JOIN rating_bounds AS b
WHERE a.average_rating IN (b.minimum, b.maximum)
ORDER BY m.year, m.title, m.id;
"
echo ""

echo "4. Количество и средняя оценка, выставленная женщинами в 2010–2012 годах."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
SELECT COUNT(*) AS rating_count, AVG(r.rating) AS average_rating
FROM ratings AS r
JOIN users AS u ON u.id = r.user_id
WHERE u.gender = 'female'
  AND r.timestamp >= unixepoch('2010-01-01')
  AND r.timestamp < unixepoch('2013-01-01');
"
echo ""

echo "5. Первые 20 фильмов по году и названию со средней оценкой и местом в рейтинге."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
WITH movie_averages AS (
    SELECT movie_id, AVG(rating) AS average_rating
    FROM ratings
    GROUP BY movie_id
),
ranked_movies AS (
    SELECT movie_id, average_rating,
           RANK() OVER (ORDER BY average_rating DESC) AS rating_rank
    FROM movie_averages
)
SELECT m.title, m.year, r.average_rating, r.rating_rank
FROM ranked_movies AS r
JOIN movies AS m ON m.id = r.movie_id
ORDER BY m.year, m.title, m.id
LIMIT 20;
"
echo ""

echo "6. Десять последних зарегистрированных пользователей в формате «Фамилия Имя|Дата»."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
WITH user_names AS (
    SELECT id, trim(name) AS full_name, register_date, instr(trim(name), ' ') AS separator
    FROM users
)
SELECT CASE WHEN separator > 0
            THEN ltrim(substr(full_name, separator + 1)) || ' ' || substr(full_name, 1, separator - 1)
            ELSE full_name
       END || '|' || register_date AS registered_user
FROM user_names
ORDER BY register_date DESC, id DESC
LIMIT 10;
"
echo ""

echo "7. Таблица умножения от 1 до 10 в одном столбце."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
WITH RECURSIVE numbers(n) AS (
    VALUES (1)
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT printf('%dx%d=%d', a.n, b.n, a.n * b.n) AS multiplication
FROM numbers AS a
CROSS JOIN numbers AS b
ORDER BY a.n, b.n;
"
echo ""

echo "8. Жанры из таблицы movies по одному на строку."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
WITH RECURSIVE genre_parts(genre, rest) AS (
    SELECT '', genres || '|'
    FROM movies
    WHERE genres IS NOT NULL
    UNION ALL
    SELECT trim(substr(rest, 1, instr(rest, '|') - 1)),
           substr(rest, instr(rest, '|') + 1)
    FROM genre_parts
    WHERE rest <> ''
)
SELECT DISTINCT genre
FROM genre_parts
WHERE genre NOT IN ('', '(no genres listed)')
ORDER BY genre;
"
echo ""
