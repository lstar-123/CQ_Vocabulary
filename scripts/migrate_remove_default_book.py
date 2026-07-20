"""Migration: Remove default book constraint from users, quiz_sessions, quiz_answers.

- Make current_book nullable (was NOT NULL DEFAULT 'grade6_vol1')
- Make book_schema nullable in quiz_sessions and quiz_answers
- Remove DEFAULT values
"""
import os
import sys
import psycopg2
from dotenv import load_dotenv

load_dotenv()
MAIN_URL = os.getenv('DATABASE_URL')

if not MAIN_URL:
    print('ERROR: DATABASE_URL must be set in .env', file=sys.stderr)
    sys.exit(1)


def parse_db_url(url):
    stripped = url.replace('postgresql://', '')
    parts = stripped.split('@')
    user_pass = parts[0].split(':')
    user = user_pass[0]
    password = user_pass[1] if len(user_pass) > 1 else ''
    host_port = parts[1].split('/')[0].split(':')
    host = host_port[0]
    port = int(host_port[1]) if len(host_port) > 1 else 5432
    dbname = parts[1].split('/')[1] if '/' in parts[1] else 'vocab_quiz'
    return {'host': host, 'port': port, 'user': user, 'password': password, 'dbname': dbname}


def main():
    cfg = parse_db_url(MAIN_URL)
    conn = psycopg2.connect(
        host=cfg['host'], port=cfg['port'], user=cfg['user'],
        password=cfg['password'], dbname=cfg['dbname']
    )
    conn.autocommit = True
    cur = conn.cursor()

    migrations = [
        # users table
        "ALTER TABLE users ALTER COLUMN current_book DROP NOT NULL",
        "ALTER TABLE users ALTER COLUMN current_book DROP DEFAULT",
        # quiz_sessions table
        "ALTER TABLE quiz_sessions ALTER COLUMN book_schema DROP NOT NULL",
        "ALTER TABLE quiz_sessions ALTER COLUMN book_schema DROP DEFAULT",
        # quiz_answers table
        "ALTER TABLE quiz_answers ALTER COLUMN book_schema DROP NOT NULL",
        "ALTER TABLE quiz_answers ALTER COLUMN book_schema DROP DEFAULT",
    ]

    print('Running migration: Remove default book constraints...')
    for sql in migrations:
        try:
            cur.execute(sql)
            print(f'  OK: {sql}')
        except Exception as e:
            print(f'  SKIP (already applied?): {e}')

    cur.close()
    conn.close()
    print('\nMigration complete.')


if __name__ == '__main__':
    main()
