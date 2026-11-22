import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TITLE_YEAR = re.compile(r"(.*?)\s*\(([0-9]{4})\)$")

SCHEMA = """PRAGMA foreign_keys = ON;
BEGIN;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS movies;

CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER,
    genres TEXT NOT NULL
);
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    gender TEXT NOT NULL,
    register_date TEXT NOT NULL,
    occupation TEXT NOT NULL
);
CREATE TABLE ratings (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    movie_id INTEGER NOT NULL REFERENCES movies(id),
    rating REAL NOT NULL,
    timestamp INTEGER NOT NULL
);
CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    movie_id INTEGER NOT NULL REFERENCES movies(id),
    tag TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);

"""


def csv_rows(filename):
    with (ROOT / filename).open(encoding="utf-8-sig", newline="") as source:
        yield from csv.DictReader(source)


def movies():
    for row in csv_rows("movies.csv"):
        title = row["title"].strip()
        match = TITLE_YEAR.fullmatch(title)
        if match:
            title, year = match.group(1), int(match.group(2))
        else:
            year = None
        yield int(row["movieId"]), title, year, row["genres"]


def users():
    with (ROOT / "users.txt").open(encoding="utf-8-sig", newline="") as source:
        for user_id, name, email, gender, date, occupation in csv.reader(
            source, delimiter="|", quoting=csv.QUOTE_NONE
        ):
            yield int(user_id), name, email, gender, date, occupation


def ratings():
    for row in csv_rows("ratings.csv"):
        yield int(row["userId"]), int(row["movieId"]), float(row["rating"]), int(row["timestamp"])


def tags():
    for row in csv_rows("tags.csv"):
        yield int(row["userId"]), int(row["movieId"]), row["tag"], int(row["timestamp"])


def sql_value(value):
    if value is None:
        return "NULL"
    if isinstance(value, str):
        return "'" + value.replace("'", "''") + "'"
    return str(value)


def write_inserts(output, table, columns, rows):
    column_list = ", ".join(columns)
    for row in rows:
        values = ", ".join(map(sql_value, row))
        output.write(f"INSERT INTO {table} ({column_list}) VALUES ({values});\n")


def main():
    with (ROOT / "db_init.sql").open("w", encoding="utf-8", newline="\n") as output:
        output.write(SCHEMA)
        write_inserts(output, "movies", ("id", "title", "year", "genres"), movies())
        write_inserts(output, "users", ("id", "name", "email", "gender", "register_date", "occupation"), users())
        write_inserts(output, "ratings", ("user_id", "movie_id", "rating", "timestamp"), ratings())
        write_inserts(output, "tags", ("user_id", "movie_id", "tag", "timestamp"), tags())
        output.write("\nCOMMIT;\n")


if __name__ == "__main__":
    main()
