#!/bin/bash
python3 make_db_init.py || exit $?
sqlite3 movies_rating.db < db_init.sql
