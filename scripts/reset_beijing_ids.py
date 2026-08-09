"""Reset IDs in senior_compulsory_1_beijing: units 1-12, words 1-358."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
from dotenv import load_dotenv

load_dotenv()

SCHEMA = 'senior_compulsory_1_beijing'


def main():
    db_url = os.getenv('WORDS_DATABASE_URL')
    if not db_url:
        print('ERROR: WORDS_DATABASE_URL not set', file=sys.stderr)
        sys.exit(1)

    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    try:
        # 1. Find the FK constraint name
        cur.execute(f"""
            SELECT conname FROM pg_constraint
            WHERE conrelid = '{SCHEMA}.words'::regclass
              AND confrelid = '{SCHEMA}.units'::regclass
              AND contype = 'f'
        """)
        fk_name = cur.fetchone()
        if fk_name:
            fk_name = fk_name[0]
            print(f"Dropping FK: {fk_name}")
            cur.execute(f'ALTER TABLE {SCHEMA}.words DROP CONSTRAINT {fk_name}')

        # 2. Drop all PKs (FK already dropped in step 1)
        cur.execute(f"""
            SELECT conname FROM pg_constraint
            WHERE conrelid = '{SCHEMA}.words'::regclass AND contype = 'p'
        """)
        words_pk = cur.fetchone()[0]
        print(f"Dropping words PK: {words_pk}")
        cur.execute(f'ALTER TABLE {SCHEMA}.words DROP CONSTRAINT {words_pk}')

        cur.execute(f"""
            SELECT conname FROM pg_constraint
            WHERE conrelid = '{SCHEMA}.units'::regclass AND contype = 'p'
        """)
        units_pk = cur.fetchone()[0]
        print(f"Dropping units PK: {units_pk}")
        cur.execute(f'ALTER TABLE {SCHEMA}.units DROP CONSTRAINT {units_pk}')

        # 3. Renumber units: id = order_num (1-12)
        cur.execute(f'SELECT id, order_num FROM {SCHEMA}.units ORDER BY order_num')
        unit_map = {old: new for old, new in cur.fetchall()}
        print(f"Unit ID mapping: {unit_map}")

        for old_uid, new_uid in unit_map.items():
            cur.execute(
                f'UPDATE {SCHEMA}.words SET unit_id = %s WHERE unit_id = %s',
                (new_uid, old_uid)
            )

        cur.execute(f'UPDATE {SCHEMA}.units SET id = order_num')
        print("Units renumbered to 1-12.")

        # 4. Renumber words: sequential 1-358
        cur.execute(f'SELECT id FROM {SCHEMA}.words ORDER BY unit_id, id')
        old_word_ids = [r[0] for r in cur.fetchall()]

        for new_id, old_id in enumerate(old_word_ids, 1):
            cur.execute(
                f'UPDATE {SCHEMA}.words SET id = %s WHERE id = %s',
                (new_id, old_id)
            )
        print(f"Words renumbered to 1-{len(old_word_ids)}.")

        # 5. Re-add constraints
        cur.execute(f'ALTER TABLE {SCHEMA}.units ADD PRIMARY KEY (id)')
        cur.execute(f'ALTER TABLE {SCHEMA}.words ADD PRIMARY KEY (id)')
        cur.execute(f"""
            ALTER TABLE {SCHEMA}.words
            ADD CONSTRAINT {fk_name}
            FOREIGN KEY (unit_id) REFERENCES {SCHEMA}.units(id) ON DELETE CASCADE
        """)

        # 5. Reset sequences
        cur.execute(f"SELECT setval('{SCHEMA}.units_id_seq', 12)")
        cur.execute(f"SELECT setval('{SCHEMA}.words_id_seq', 358)")
        print("Sequences reset.")

        conn.commit()

        # Verify
        cur.execute(f'SELECT id, name, order_num FROM {SCHEMA}.units ORDER BY id')
        print("\nUnits:")
        for r in cur.fetchall():
            cur.execute(f'SELECT COUNT(*) FROM {SCHEMA}.words WHERE unit_id = %s', (r[0],))
            print(f"  id={r[0]}, {r[1]}, order={r[2]}, words={cur.fetchone()[0]}")

        cur.execute(f'SELECT COUNT(*) FROM {SCHEMA}.words')
        print(f"\nTotal words: {cur.fetchone()[0]}")
        cur.execute(f"SELECT MIN(id), MAX(id) FROM {SCHEMA}.words")
        mn, mx = cur.fetchone()
        print(f"Word ID range: {mn} - {mx}")

        print("\nDone!")

    except Exception as e:
        conn.rollback()
        print(f"Error: {e}", file=sys.stderr)
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == '__main__':
    main()
