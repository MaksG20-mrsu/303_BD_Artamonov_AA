PRAGMA foreign_keys = ON;
BEGIN;

INSERT INTO users (first_name, last_name, email, gender, occupation_id)
VALUES
    ('Александр', 'Артамонов', 'artamonov.aa@example.com', 'male',
     (SELECT id FROM occupations WHERE name = 'student')),
    ('Владислав', 'Давыдкин', 'davydkin.va@example.com', 'male',
     (SELECT id FROM occupations WHERE name = 'student')),
    ('Роман', 'Долгачёв', 'dolgachev.rs@example.com', 'male',
     (SELECT id FROM occupations WHERE name = 'student')),
    ('Валерия', 'Житина', 'zhitina.vv@example.com', 'female',
     (SELECT id FROM occupations WHERE name = 'student')),
    ('Вячеслав', 'Иванов', 'ivanov.vs@example.com', 'male',
     (SELECT id FROM occupations WHERE name = 'student'));

-- Capture the generated keys before inserting the related rows.
CREATE TEMP TABLE added_movies (
    title TEXT PRIMARY KEY,
    movie_id INTEGER NOT NULL
) STRICT;

INSERT INTO movies (title, year) VALUES ('Dune', 2021);
INSERT INTO temp.added_movies VALUES ('Dune', last_insert_rowid());

INSERT INTO movies (title, year) VALUES ('The Holdovers', 2023);
INSERT INTO temp.added_movies VALUES ('The Holdovers', last_insert_rowid());

INSERT INTO movies (title, year) VALUES ('Flow', 2024);
INSERT INTO temp.added_movies VALUES ('Flow', last_insert_rowid());

WITH requested_genres(title, genre) AS (
    VALUES ('Dune', 'Sci-Fi'), ('The Holdovers', 'Comedy'), ('Flow', 'Animation')
)
INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.movie_id, (SELECT id FROM genres WHERE name = r.genre)
FROM requested_genres AS r
JOIN temp.added_movies AS m ON m.title = r.title;

WITH new_ratings(title, rating) AS (
    VALUES ('Dune', 4.5), ('The Holdovers', 4.0), ('Flow', 5.0)
)
INSERT INTO ratings (user_id, movie_id, rating)
SELECT (SELECT id FROM users WHERE email = 'artamonov.aa@example.com'),
       m.movie_id, r.rating
FROM new_ratings AS r
JOIN temp.added_movies AS m ON m.title = r.title;

DROP TABLE temp.added_movies;
COMMIT;
