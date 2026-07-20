"""One-time migration: add phonics columns to all schema word tables.

Adds to each {schema}.words table:
  - phonics_data JSONB
  - phonics_version INTEGER DEFAULT 1
  - generated_by VARCHAR(100)
  - generated_at TIMESTAMP
  - reviewed BOOLEAN DEFAULT FALSE

Usage:
    python scripts/migrate_phonics.py
    python scripts/migrate_phonics.py --schema grade6_vol1
"""
import os
import sys
import argparse
import psycopg2
from dotenv import load_dotenv

load_dotenv()

WORDS_URL = os.getenv('WORDS_DATABASE_URL')
if not WORDS_URL:
    print('ERROR: WORDS_DATABASE_URL not set in .env', file=sys.stderr)
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
    dbname = parts[1].split('/')[1] if '/' in parts[1] else 'vocab_quiz_words'
    return {'host': host, 'port': port, 'user': user, 'password': password, 'dbname': dbname}


def get_schemas(cur, filter_schema=None):
    """Discover all schemas in vocab_quiz_words that have a 'words' table."""
    cur.execute("""
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name NOT IN ('public', 'information_schema', 'pg_catalog', 'pg_toast')
        ORDER BY schema_name
    """)
    all_schemas = [row[0] for row in cur.fetchall()]

    if filter_schema:
        if filter_schema in all_schemas:
            return [filter_schema]
        else:
            print(f'WARNING: Schema "{filter_schema}" not found.', file=sys.stderr)
            return []

    return all_schemas


def column_exists(cur, schema, table, column):
    """Check if a column exists in a table."""
    cur.execute("""
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = %s AND table_name = %s AND column_name = %s
    """, (schema, table, column))
    return cur.fetchone() is not None


def migrate_schema(cur, schema):
    """Add phonics columns to {schema}.words if they don't exist."""
    table = f'{schema}.words'

    # Check if words table exists
    cur.execute("""
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = %s AND table_name = 'words'
    """, (schema,))
    if not cur.fetchone():
        print(f'  [{schema}] No words table found, skipping.')
        return False

    columns_to_add = [
        ('phonics_data', 'JSONB DEFAULT NULL'),
        ('phonics_version', 'INTEGER DEFAULT 1'),
        ('generated_by', 'VARCHAR(100) DEFAULT NULL'),
        ('generated_at', 'TIMESTAMP DEFAULT NULL'),
        ('reviewed', 'BOOLEAN DEFAULT FALSE'),
    ]

    added = 0
    for col_name, col_def in columns_to_add:
        if column_exists(cur, schema, 'words', col_name):
            print(f'  [{schema}] Column "{col_name}" already exists, skipping.')
        else:
            try:
                cur.execute(f'ALTER TABLE {table} ADD COLUMN {col_name} {col_def}')
                print(f'  [{schema}] Added column "{col_name}".')
                added += 1
            except Exception as e:
                print(f'  [{schema}] ERROR adding "{col_name}": {e}', file=sys.stderr)
                return False

    if added == 0:
        print(f'  [{schema}] All columns already exist, nothing to migrate.')
    else:
        print(f'  [{schema}] {added} column(s) added successfully.')

    return True


def main():
    parser = argparse.ArgumentParser(description='Add phonics columns to word tables.')
    parser.add_argument('--schema', default=None,
                        help='Migrate only a specific schema (default: all)')
    args = parser.parse_args()

    cfg = parse_db_url(WORDS_URL)

    print('=' * 60)
    print('Phonics Schema Migration')
    print('=' * 60)
    print(f'Database: {cfg["dbname"]}')
    print()

    conn = psycopg2.connect(**cfg)
    cur = conn.cursor()

    schemas = get_schemas(cur, args.schema)

    if not schemas:
        print('No schemas found to migrate.')
        cur.close()
        conn.close()
        return

    print(f'Found {len(schemas)} schema(s): {", ".join(schemas)}')
    print()

    all_ok = True
    for schema in schemas:
        if not migrate_schema(cur, schema):
            all_ok = False
            conn.rollback()
        else:
            conn.commit()

    cur.close()
    conn.close()

    print()
    print('=' * 60)
    if all_ok:
        print('Migration complete.')
    else:
        print('Migration completed with errors. Check output above.')
    print('=' * 60)


if __name__ == '__main__':
    main()
