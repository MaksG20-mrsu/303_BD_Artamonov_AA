#!/bin/bash
set -e
cd -- "$(dirname -- "$0")"
if command -v chcp.com >/dev/null 2>&1; then
    chcp.com 65001 >/dev/null
fi

sqlite3 -bail movies_rating.db < db_init.sql

echo "1. Первые 10 фильмов с оценками, по году выпуска и названию."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
SELECT m.title, m.year
FROM movies AS m
WHERE EXISTS (SELECT 1 FROM ratings AS r WHERE r.movie_id = m.id)
ORDER BY m.year, m.title, m.id
LIMIT 10;
"
echo ""

echo "2. Первые 5 пользователей с фамилией на A, по дате регистрации."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
SELECT name, register_date
FROM users
WHERE instr(trim(name), ' ') > 0
  AND ltrim(substr(trim(name), instr(trim(name), ' ') + 1)) LIKE 'A%'
ORDER BY register_date, id
LIMIT 5;
"
echo ""

echo "3. Первые 50 оценок с именем эксперта, фильмом и датой оценки."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
SELECT u.name AS expert, m.title, m.year, r.rating,
       date(r.timestamp, 'unixepoch') AS rating_date
FROM ratings AS r
JOIN users AS u ON u.id = r.user_id
JOIN movies AS m ON m.id = r.movie_id
ORDER BY u.name, m.title, r.rating, r.id
LIMIT 50;
"
echo ""

echo "4. Первые 40 записей о фильмах и пользовательских тегах."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
SELECT m.title, m.year, t.tag
FROM tags AS t
JOIN movies AS m ON m.id = t.movie_id
ORDER BY m.year, m.title, t.tag, t.id
LIMIT 40;
"
echo ""

echo "5. Все фильмы последнего года выпуска в базе."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
SELECT title, year
FROM movies
WHERE year = (SELECT MAX(year) FROM movies)
ORDER BY title, id;
"
echo ""

echo "6. Комедии после 2000 года с оценками мужчин от 4.5."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
SELECT m.title, m.year, COUNT(*) AS rating_count
FROM movies AS m
JOIN ratings AS r ON r.movie_id = m.id
JOIN users AS u ON u.id = r.user_id
WHERE m.year > 2000
  AND instr('|' || m.genres || '|', '|Comedy|') > 0
  AND u.gender = 'male'
  AND r.rating >= 4.5
GROUP BY m.id, m.title, m.year
ORDER BY m.year, m.title, m.id;
"
echo ""

echo "7. Количество пользователей по профессиям."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
SELECT occupation, COUNT(*) AS user_count
FROM users
GROUP BY occupation
ORDER BY user_count DESC, occupation;
"
echo ""

echo "7. Самые распространённые и самые редкие профессии."
echo "--------------------------------------------------"
sqlite3 -bail -box -echo movies_rating.db "
WITH occupation_counts AS (
    SELECT occupation, COUNT(*) AS user_count
    FROM users
    GROUP BY occupation
)
SELECT 'most common' AS category, occupation, user_count
FROM occupation_counts
WHERE user_count = (SELECT MAX(user_count) FROM occupation_counts)
UNION ALL
SELECT 'rarest', occupation, user_count
FROM occupation_counts
WHERE user_count = (SELECT MIN(user_count) FROM occupation_counts)
ORDER BY category, occupation;
"
