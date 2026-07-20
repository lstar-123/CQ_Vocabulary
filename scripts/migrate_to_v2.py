"""One-time migration: split vocab_quiz into vocab_quiz + vocab_quiz_words.

Steps:
1. Create vocab_quiz_words database
2. Create grade6_vol1 and senior_compulsory_1 schemas
3. Create units + words tables in each schema
4. Copy existing units/words data to vocab_quiz_words.grade6_vol1
5. Add book_schema column to quiz_sessions and quiz_answers
6. Drop FK constraint on quiz_answers.word_id (cross-database)
7. Add current_book column to users
"""
import os
import sys
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# Parse DATABASE_URLs
MAIN_URL = os.getenv('DATABASE_URL')
WORDS_URL = os.getenv('WORDS_DATABASE_URL')

if not MAIN_URL or not WORDS_URL:
    print('ERROR: DATABASE_URL and WORDS_DATABASE_URL must be set in .env', file=sys.stderr)
    sys.exit(1)


def parse_db_url(url):
    """Parse postgresql://user:pass@host:port/dbname into components."""
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


def create_database(host, port, user, password, dbname):
    """Create a database if it doesn't exist."""
    conn = psycopg2.connect(host=host, port=port, user=user, password=password, dbname='postgres')
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (dbname,))
    if cur.fetchone():
        print(f'  Database "{dbname}" already exists, skipping.')
    else:
        cur.execute(f'CREATE DATABASE "{dbname}"')
        print(f'  Database "{dbname}" created.')
    cur.close()
    conn.close()


def main():
    main_cfg = parse_db_url(MAIN_URL)
    words_cfg = parse_db_url(WORDS_URL)

    print('=' * 60)
    print('Vocabulary Memorization — Database Migration v2')
    print('=' * 60)

    # ----------------------------------------------------------------
    # Step 1: Create vocab_quiz_words database
    # ----------------------------------------------------------------
    print('\n[1/7] Creating vocab_quiz_words database...')
    create_database(words_cfg['host'], words_cfg['port'], words_cfg['user'],
                    words_cfg['password'], words_cfg['dbname'])

    # ----------------------------------------------------------------
    # Step 2: Create schemas in vocab_quiz_words
    # ----------------------------------------------------------------
    print('\n[2/7] Creating schemas in vocab_quiz_words...')
    words_conn = psycopg2.connect(**{k: v for k, v in words_cfg.items() if k != 'dbname'},
                                  dbname=words_cfg['dbname'])
    words_conn.autocommit = True
    w_cur = words_conn.cursor()

    for schema in ['grade6_vol1', 'senior_compulsory_1']:
        w_cur.execute(f'CREATE SCHEMA IF NOT EXISTS {schema}')
        print(f'  Schema "{schema}" ready.')

    # ----------------------------------------------------------------
    # Step 3: Create tables in vocab_quiz_words
    # ----------------------------------------------------------------
    print('\n[3/7] Creating tables in vocab_quiz_words schemas...')
    table_sqls = [
        '''CREATE TABLE IF NOT EXISTS {schema}.units (
            id SERIAL PRIMARY KEY,
            name VARCHAR(50) UNIQUE NOT NULL,
            order_num INTEGER NOT NULL DEFAULT 0
        )''',
        '''CREATE TABLE IF NOT EXISTS {schema}.words (
            id SERIAL PRIMARY KEY,
            unit_id INTEGER NOT NULL REFERENCES {schema}.units(id) ON DELETE CASCADE,
            english VARCHAR(255) NOT NULL,
            chinese VARCHAR(255) NOT NULL
        )''',
    ]

    for schema in ['grade6_vol1', 'senior_compulsory_1']:
        for sql in table_sqls:
            try:
                w_cur.execute(sql.format(schema=schema))
            except Exception as e:
                print(f'  ERROR creating table in {schema}: {e}')
                words_conn.rollback()
                sys.exit(1)
        print(f'  Tables created in {schema}.')

    w_cur.close()
    words_conn.close()

    # ----------------------------------------------------------------
    # Step 4: Migrate existing data to vocab_quiz_words.grade6_vol1
    # ----------------------------------------------------------------
    print('\n[4/7] Migrating units & words data...')
    main_conn = psycopg2.connect(**{k: v for k, v in main_cfg.items() if k != 'dbname'},
                                 dbname=main_cfg['dbname'])

    # Check if source tables have data
    m_cur = main_conn.cursor()
    m_cur.execute('SELECT COUNT(*) FROM units')
    unit_count = m_cur.fetchone()[0]
    m_cur.execute('SELECT COUNT(*) FROM words')
    word_count = m_cur.fetchone()[0]

    if unit_count == 0 and word_count == 0:
        print('  No existing data to migrate, skipping.')
    else:
        print(f'  Found {unit_count} units, {word_count} words to migrate.')

        # Copy to vocab_quiz_words.grade6_vol1
        words_conn = psycopg2.connect(**{k: v for k, v in words_cfg.items() if k != 'dbname'},
                                      dbname=words_cfg['dbname'])
        w_cur = words_conn.cursor()

        # Check if target already has data
        w_cur.execute('SELECT COUNT(*) FROM grade6_vol1.units')
        if w_cur.fetchone()[0] > 0:
            print('  WARNING: grade6_vol1.units already has data. Skipping migration.')
            print('  If you need to re-migrate, truncate grade6_vol1.units and grade6_vol1.words first.')
        else:
            # Copy units (keeping original IDs for word FK consistency)
            m_cur.execute('SELECT id, name, order_num FROM units ORDER BY id')
            units_data = m_cur.fetchall()
            for uid, name, order_num in units_data:
                w_cur.execute(
                    'INSERT INTO grade6_vol1.units (id, name, order_num) VALUES (%s, %s, %s)',
                    (uid, name, order_num)
                )
            # Advance the sequence past the max id
            if units_data:
                max_uid = max(u[0] for u in units_data)
                w_cur.execute(f"SELECT setval('grade6_vol1.units_id_seq', {max_uid})")

            # Copy words
            m_cur.execute('SELECT id, unit_id, english, chinese FROM words ORDER BY id')
            words_data = m_cur.fetchall()
            for wid, unit_id, english, chinese in words_data:
                w_cur.execute(
                    'INSERT INTO grade6_vol1.words (id, unit_id, english, chinese) VALUES (%s, %s, %s, %s)',
                    (wid, unit_id, english, chinese)
                )
            if words_data:
                max_wid = max(w[0] for w in words_data)
                w_cur.execute(f"SELECT setval('grade6_vol1.words_id_seq', {max_wid})")

            words_conn.commit()
            print(f'  Migrated {len(units_data)} units, {len(words_data)} words to grade6_vol1.')

        w_cur.close()
        words_conn.close()

    # ----------------------------------------------------------------
    # Step 5: Add book_schema columns to quiz tables
    # ----------------------------------------------------------------
    print('\n[5/7] Adding book_schema columns to quiz tables...')
    main_conn.rollback()  # Reset any prior transaction
    m_cur = main_conn.cursor()

    alter_sqls = [
        "ALTER TABLE quiz_sessions ADD COLUMN IF NOT EXISTS book_schema VARCHAR(50) DEFAULT 'grade6_vol1'",
        "ALTER TABLE quiz_answers ADD COLUMN IF NOT EXISTS book_schema VARCHAR(50) DEFAULT 'grade6_vol1'",
    ]
    for sql in alter_sqls:
        try:
            m_cur.execute(sql)
            print(f'  OK: {sql[:70]}...')
        except Exception as e:
            print(f'  ERROR: {e}')
            main_conn.rollback()
            m_cur.close()
            main_conn.close()
            sys.exit(1)

    main_conn.commit()

    # Update existing rows to set the default explicitly
    m_cur.execute("UPDATE quiz_sessions SET book_schema = 'grade6_vol1' WHERE book_schema IS NULL")
    m_cur.execute("UPDATE quiz_answers SET book_schema = 'grade6_vol1' WHERE book_schema IS NULL")
    main_conn.commit()

    # ----------------------------------------------------------------
    # Step 6: Drop FK constraint on quiz_answers.word_id
    # ----------------------------------------------------------------
    print('\n[6/7] Dropping FK constraint on quiz_answers.word_id...')
    # Find the constraint name
    m_cur.execute("""
        SELECT tc.constraint_name
        FROM information_schema.table_constraints tc
        WHERE tc.table_name = 'quiz_answers'
          AND tc.table_schema = 'public'
          AND tc.constraint_type = 'FOREIGN KEY'
          AND EXISTS (
              SELECT 1 FROM information_schema.key_column_usage kcu
              WHERE kcu.constraint_name = tc.constraint_name
                AND kcu.column_name = 'word_id'
          )
    """)
    fk_row = m_cur.fetchone()
    if fk_row:
        fk_name = fk_row[0]
        m_cur.execute(f'ALTER TABLE quiz_answers DROP CONSTRAINT IF EXISTS "{fk_name}"')
        main_conn.commit()
        print(f'  Dropped FK constraint: {fk_name}')
    else:
        print('  No FK constraint found on quiz_answers.word_id (already removed or never existed).')

    # ----------------------------------------------------------------
    # Step 7: Add current_book column to users
    # ----------------------------------------------------------------
    print('\n[7/7] Adding current_book column to users...')
    try:
        m_cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS current_book VARCHAR(50) DEFAULT 'grade6_vol1'")
        m_cur.execute("UPDATE users SET current_book = 'grade6_vol1' WHERE current_book IS NULL")
        main_conn.commit()
        print('  OK: current_book column added.')
    except Exception as e:
        print(f'  ERROR: {e}')
        main_conn.rollback()

    # ----------------------------------------------------------------
    # Done
    # ----------------------------------------------------------------
    print('\n' + '=' * 60)
    print('Migration complete!')
    print('=' * 60)
    print(f'\nNext steps:')
    print(f'  1. Restart the application')
    print(f'  2. Verify units/words load correctly')
    print(f'  3. (Optional) Drop old units/words tables from vocab_quiz.public')
    print(f'     DROP TABLE IF EXISTS vocab_quiz.public.quiz_answers CASCADE; -- careful!')
    print(f'     Then: DROP TABLE IF EXISTS vocab_quiz.public.words CASCADE;')
    print(f'     Then: DROP TABLE IF EXISTS vocab_quiz.public.units CASCADE;')

    m_cur.close()
    main_conn.close()


if __name__ == '__main__':
    main()
