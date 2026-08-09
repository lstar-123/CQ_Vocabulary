"""One-time database setup: create databases, schemas, tables, and import vocabulary."""
import os
import sys
import re
import psycopg2
from dotenv import load_dotenv

load_dotenv()
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


def connect_db(cfg):
    """Connect to a database using parsed config."""
    return psycopg2.connect(
        host=cfg['host'], port=cfg['port'], user=cfg['user'],
        password=cfg['password'], dbname=cfg['dbname']
    )


def create_database(cfg):
    """Create a database if it doesn't exist."""
    conn = psycopg2.connect(
        host=cfg['host'], port=cfg['port'], user=cfg['user'],
        password=cfg['password'], dbname='postgres'
    )
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (cfg['dbname'],))
    if cur.fetchone():
        print(f'  Database "{cfg["dbname"]}" already exists.')
    else:
        cur.execute(f'CREATE DATABASE "{cfg["dbname"]}"')
        print(f'  Database "{cfg["dbname"]}" created.')
    cur.close()
    conn.close()


def parse_markdown(filepath):
    """Parse vocabulary markdown file. Returns list of {name, words}.

    Handles both the new table format (BeiJing edition) and the original
    markdown format with ## Unit headers.
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Detect BeiJing table format: "| 序号 |"
    if re.search(r'\|\s*序号\s*\|', content):
        return _parse_table_format(content)

    # Original format with ## Unit headers
    return _parse_unit_format(content)


def _parse_table_format(content):
    """Parse table-format vocabulary (BeiJing Normal University edition)."""
    units = []
    unit_name = None
    in_table = False
    table_header_skipped = False

    for line in content.split('\n'):
        stripped = line.strip()
        if not stripped:
            continue

        title_match = re.match(r'^#\s+(.+)$', stripped)
        if title_match and not in_table:
            unit_name = title_match.group(1).strip()
            unit_name = re.sub(r'\s*单词表.*$', '', unit_name)
            continue

        if re.match(r'^\|\s*序号\s*\|', stripped):
            in_table = True
            table_header_skipped = False
            continue

        if in_table and not table_header_skipped and re.match(r'^\|[\s\-|]+$', stripped):
            table_header_skipped = True
            continue

        if in_table and table_header_skipped:
            parts = [p.strip() for p in stripped.split('|') if p.strip()]
            if len(parts) >= 5:
                english = parts[3].strip()
                chinese = parts[4].strip()
            elif len(parts) >= 2:
                english = parts[-2].strip()
                chinese = parts[-1].strip()
            else:
                continue

            if english:
                if unit_name is None:
                    unit_name = 'Vocabulary'
                if not units:
                    units.append({'name': unit_name, 'words': []})
                units[0]['words'].append({'english': english, 'chinese': chinese})

    return units


def _parse_unit_format(content):
    """Parse original markdown format with ## Unit headers."""
    units = []
    current_unit = None
    in_table = False
    table_header_skipped = False

    for line in content.split('\n'):
        stripped = line.strip()
        if not stripped:
            in_table = False
            table_header_skipped = False
            continue

        # Section header: ## UNIT N or ### Lesson N etc.
        section_match = re.match(r'^#+\s+(.+)$', stripped)
        if section_match:
            in_table = False
            table_header_skipped = False
            section_name = section_match.group(1).strip()

            # Skip top-level title lines
            if not re.match(r'^(Unit\s+\d+|Topic\s+Talk|Lesson|Unit)', section_name):
                continue

            current_unit = {'name': section_name, 'words': []}
            units.append(current_unit)
            continue

        # Table header in unit format: | 单词/短语 | 中文意思 |
        if re.match(r'^\|\s*单词', stripped) or re.match(r'^\|\s*英语', stripped):
            in_table = True
            table_header_skipped = False
            continue

        # Table separator: | --- | --- |
        if in_table and not table_header_skipped and re.match(r'^\|[\s\-|]+$', stripped):
            table_header_skipped = True
            continue

        # Table data row: | english | chinese |
        table_row = re.match(r'^\|\s*(.+?)\s*\|\s*(.+?)\s*\|', stripped)
        if table_row and current_unit is not None:
            english = table_row.group(1).strip()
            chinese = table_row.group(2).strip()
            current_unit['words'].append({'english': english, 'chinese': chinese})
            continue

        # Legacy indented list: "  - english  chinese"
        word_match = re.match(r'^\s+-\s+(.+?)\s{2,}(.+?)\s*$', line)
        if word_match and current_unit is not None:
            current_unit['words'].append({
                'english': word_match.group(1).strip(),
                'chinese': word_match.group(2).strip()
            })

    return units


def main():
    main_cfg = parse_db_url(MAIN_URL)
    words_cfg = parse_db_url(WORDS_URL)

    print('=' * 60)
    print('Vocabulary Memorization — Full Database Setup')
    print('=' * 60)

    # ----------------------------------------------------------------
    # Step 1: Create databases
    # ----------------------------------------------------------------
    print('\n[1/5] Creating databases...')
    create_database(main_cfg)
    create_database(words_cfg)

    # ----------------------------------------------------------------
    # Step 2: Create schemas in vocab_quiz_words
    # ----------------------------------------------------------------
    print('\n[2/5] Creating schemas in vocab_quiz_words...')
    w_conn = connect_db(words_cfg)
    w_conn.autocommit = True
    w_cur = w_conn.cursor()

    for schema in ['grade6_vol1', 'senior_compulsory_1', 'senior_compulsory_1_beijing']:
        w_cur.execute(f'CREATE SCHEMA IF NOT EXISTS {schema}')
        print(f'  Schema "{schema}" ready.')

    # ----------------------------------------------------------------
    # Step 3: Create tables in vocab_quiz (main database)
    # ----------------------------------------------------------------
    print('\n[3/5] Creating tables in vocab_quiz...')
    m_conn = connect_db(main_cfg)
    m_cur = m_conn.cursor()

    main_tables = [
        '''CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            current_book VARCHAR(50),
            note TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''',
        '''CREATE TABLE IF NOT EXISTS teachers (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''',
        '''CREATE TABLE IF NOT EXISTS quiz_sessions (
            id SERIAL PRIMARY KEY,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            unit_ids VARCHAR(100) NOT NULL,
            total_count INTEGER NOT NULL,
            correct_count INTEGER NOT NULL,
            score_pct NUMERIC(5,2) NOT NULL,
            duration_seconds INTEGER,
            book_schema VARCHAR(50),
            completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''',
        '''CREATE TABLE IF NOT EXISTS quiz_answers (
            id SERIAL PRIMARY KEY,
            session_id INTEGER NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
            word_id INTEGER NOT NULL,
            user_answer VARCHAR(500) NOT NULL,
            is_correct BOOLEAN NOT NULL,
            book_schema VARCHAR(50)
        )''',
    ]

    for sql in main_tables:
        try:
            m_cur.execute(sql)
        except Exception as e:
            print(f'  ERROR creating table: {e}')
            m_conn.rollback()
            m_cur.close()
            m_conn.close()
            w_cur.close()
            w_conn.close()
            sys.exit(1)

    m_conn.commit()
    print('  Tables created in vocab_quiz.')

    # ----------------------------------------------------------------
    # Step 4: Create tables in vocab_quiz_words schemas
    # ----------------------------------------------------------------
    print('\n[4/5] Creating tables in vocab_quiz_words...')
    words_tables = [
        '''CREATE TABLE IF NOT EXISTS {schema}.units (
            id SERIAL PRIMARY KEY,
            name VARCHAR(50) UNIQUE NOT NULL,
            order_num INTEGER NOT NULL DEFAULT 0
        )''',
        '''CREATE TABLE IF NOT EXISTS {schema}.words (
            id SERIAL PRIMARY KEY,
            unit_id INTEGER NOT NULL REFERENCES {schema}.units(id) ON DELETE CASCADE,
            english VARCHAR(255) NOT NULL,
            chinese VARCHAR(255) NOT NULL,
            phonics_data JSONB DEFAULT NULL,
            phonics_version INTEGER DEFAULT 1,
            generated_by VARCHAR(100) DEFAULT NULL,
            generated_at TIMESTAMP DEFAULT NULL,
            reviewed BOOLEAN DEFAULT FALSE
        )''',
    ]

    for schema in ['grade6_vol1', 'senior_compulsory_1', 'senior_compulsory_1_beijing']:
        for sql in words_tables:
            try:
                w_cur.execute(sql.format(schema=schema))
            except Exception as e:
                print(f'  ERROR creating table in {schema}: {e}')
                w_conn.rollback()
                sys.exit(1)
        print(f'  Tables created in {schema}.')

    w_conn.commit()
    w_cur.close()
    w_conn.close()

    # ----------------------------------------------------------------
    # Step 5: Import vocabulary from markdown files
    # ----------------------------------------------------------------
    print('\n[5/5] Importing vocabulary data...')

    data_dir = os.path.join(os.path.dirname(__file__), '..', 'data')
    book_files = [
        ('vocabulary_6_1.md', 'grade6_vol1', '六年级上册'),
        ('vocabulary_10_1.md', 'senior_compulsory_1', '高中必修一'),
        ('vocabulary_10_1_BeiJing.md', 'senior_compulsory_1_beijing', '北师大必修一'),
    ]

    for filename, schema, display_name in book_files:
        filepath = os.path.join(data_dir, filename)
        if not os.path.exists(filepath):
            print(f'  [{display_name}] File not found: {filepath}, skipping.')
            continue

        units = parse_markdown(filepath)
        if not units:
            print(f'  [{display_name}] No units found in {filename}, skipping.')
            continue

        w_conn = connect_db(words_cfg)
        w_cur = w_conn.cursor()

        # Clear existing data in this schema
        w_cur.execute(f'DELETE FROM {schema}.words')
        w_cur.execute(f'DELETE FROM {schema}.units')

        total_words = 0
        for i, unit_data in enumerate(units):
            w_cur.execute(
                f'INSERT INTO {schema}.units (name, order_num) VALUES (%s, %s) RETURNING id',
                (unit_data['name'], i + 1)
            )
            unit_id = w_cur.fetchone()[0]
            for word in unit_data['words']:
                w_cur.execute(
                    f'INSERT INTO {schema}.words (unit_id, english, chinese) VALUES (%s, %s, %s)',
                    (unit_id, word['english'], word['chinese'])
                )
                total_words += 1
            print(f'    {unit_data["name"]}: {len(unit_data["words"])} words')

        w_conn.commit()
        w_cur.close()
        w_conn.close()
        print(f'  [{display_name}] Imported {len(units)} units, {total_words} words into {schema}.')

    m_cur.close()
    m_conn.close()

    print('\n' + '=' * 60)
    print('Setup complete!')
    print('=' * 60)
    print(f'\nDatabases:')
    print(f'  vocab_quiz        — users, teachers, quiz_sessions, quiz_answers')
    print(f'  vocab_quiz_words  — grade6_vol1 (units, words), senior_compulsory_1 (units, words)')


if __name__ == '__main__':
    main()
