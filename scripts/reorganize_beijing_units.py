"""Reorganize senior_compulsory_1_beijing vocabulary into 12 units (~30 words each).

Reads vocabulary_10_1_BeiJing_words.md for unit groupings and
vocabulary_10_1_BeiJing.md for English-Chinese mappings.

PRESERVES all existing column data (phonics_data, phonics_version,
generated_by, generated_at, reviewed) by using UPDATE instead of
DELETE + INSERT. Only reassigns unit_id and updates english/chinese.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
from dotenv import load_dotenv

load_dotenv()

DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'data')
SCHEMA = 'senior_compulsory_1_beijing'
WORDS_FILE = os.path.join(DATA_DIR, 'vocabulary_10_1_BeiJing_words.md')
TABLE_FILE = os.path.join(DATA_DIR, 'vocabulary_10_1_BeiJing.md')


def parse_units_file(filepath):
    """Parse vocabulary_10_1_BeiJing_words.md into {unit_name: [english_words]}."""
    units = {}
    current_unit = None

    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            stripped = line.strip()
            if not stripped:
                continue

            unit_match = re.match(r'^#\s*Unit\s+(\d+)', stripped)
            if unit_match:
                unit_num = int(unit_match.group(1))
                current_unit = f'Unit {unit_num}'
                units[current_unit] = []
                continue

            if current_unit is not None:
                english = stripped.lower().strip()
                units[current_unit].append(english)

    return units


def parse_table_file(filepath):
    """Parse vocabulary_10_1_BeiJing.md to get {english_lower: chinese} mapping."""
    mapping = {}

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    in_table = False
    header_skipped = False

    for line in content.split('\n'):
        stripped = line.strip()
        if not stripped:
            continue

        if re.match(r'^\|\s*序号\s*\|', stripped):
            in_table = True
            header_skipped = False
            continue

        if in_table and not header_skipped and re.match(r'^\|[\s\-|]+$', stripped):
            header_skipped = True
            continue

        if in_table and header_skipped:
            parts = [p.strip() for p in stripped.split('|') if p.strip()]
            if len(parts) >= 5:
                english = parts[3].strip().lower()
                chinese = parts[4].strip()
            elif len(parts) >= 2:
                english = parts[-2].strip().lower()
                chinese = parts[-1].strip()
            else:
                continue
            mapping[english] = chinese

    return mapping


def normalize_key(s):
    """Normalize a string for fuzzy matching."""
    return re.sub(r'\s+', ' ', s.lower().strip())


def main():
    print(f"Parsing {WORDS_FILE}...")
    units = parse_units_file(WORDS_FILE)
    total_words = sum(len(w) for w in units.values())
    print(f"Found {len(units)} units, {total_words} total words.")

    print(f"\nParsing {TABLE_FILE} for Chinese meanings...")
    en_to_cn = parse_table_file(TABLE_FILE)
    print(f"Found {len(en_to_cn)} English-Chinese pairs.")

    # Build normalized lookup
    normalized_lookup = {normalize_key(k): v for k, v in en_to_cn.items()}

    # Build word → unit mapping (lowercased english → unit_order_num)
    word_to_unit = {}
    for unit_name, words in units.items():
        unit_num = int(re.search(r'\d+', unit_name).group())
        for word in words:
            word_to_unit[normalize_key(word)] = unit_num

    # Build english → chinese mapping
    word_to_cn = {}
    for unit_name, words in units.items():
        for word in words:
            norm = normalize_key(word)
            if norm in normalized_lookup:
                word_to_cn[norm] = normalized_lookup[norm]
            else:
                for orig_key, cn in en_to_cn.items():
                    if normalize_key(orig_key) == norm:
                        word_to_cn[norm] = cn
                        break
                if norm not in word_to_cn:
                    word_to_cn[norm] = ''

    # Connect to DB
    db_url = os.getenv('WORDS_DATABASE_URL')
    if not db_url:
        print('ERROR: WORDS_DATABASE_URL not set in .env', file=sys.stderr)
        sys.exit(1)

    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    try:
        # Check current state
        cur.execute(f'SELECT COUNT(*) FROM {SCHEMA}.units')
        existing_units = cur.fetchone()[0]
        cur.execute(f'SELECT COUNT(*) FROM {SCHEMA}.words')
        existing_words = cur.fetchone()[0]
        print(f"\nCurrent DB state: {existing_units} units, {existing_words} words.")

        if existing_words == 0:
            print("No words in DB — performing fresh import.")
            _fresh_import(cur, units, en_to_cn, normalized_lookup)
        else:
            print("Words exist — using UPDATE to reassign units (preserving phonics_data).")
            _update_units(cur, word_to_unit, word_to_cn)

        conn.commit()

        # Verify
        cur.execute(
            f'SELECT u.id, u.name, u.order_num, COUNT(w.id) '
            f'FROM {SCHEMA}.units u '
            f'LEFT JOIN {SCHEMA}.words w ON w.unit_id = u.id '
            f'GROUP BY u.id, u.name, u.order_num '
            f'ORDER BY u.order_num'
        )
        print("\nFinal state:")
        for r in cur.fetchall():
            print(f"  id={r[0]}, {r[1]}, order={r[2]}, words={r[3]}")

        # Check phonics_data
        cur.execute(
            f'SELECT COUNT(*) FROM {SCHEMA}.words WHERE phonics_data IS NOT NULL'
        )
        phonics_count = cur.fetchone()[0]
        print(f"\nWords with phonics_data: {phonics_count}/{existing_words}")

        print("\nDone!")

    except Exception as e:
        conn.rollback()
        print(f"Error: {e}", file=sys.stderr)
        raise
    finally:
        cur.close()
        conn.close()


def _update_units(cur, word_to_unit, word_to_cn):
    """Update existing words: reassign unit_id, update english/chinese if needed.
    Preserves phonics_data and all other columns."""
    from psycopg2.extras import execute_values

    SCHEMA = 'senior_compulsory_1_beijing'

    # 1. Ensure units table has all 12 units
    cur.execute(f'SELECT id, order_num FROM {SCHEMA}.units ORDER BY order_num')
    existing = {r[1]: r[0] for r in cur.fetchall()}  # order_num → id

    for order_num in range(1, 13):
        if order_num not in existing:
            cur.execute(
                f'INSERT INTO {SCHEMA}.units (name, order_num) VALUES (%s, %s) RETURNING id',
                (f'Unit {order_num}', order_num)
            )
            unit_id = cur.fetchone()[0]
            existing[order_num] = unit_id
            print(f"  Created Unit {order_num} (id={unit_id})")
        else:
            # Ensure name is correct
            cur.execute(
                f'UPDATE {SCHEMA}.units SET name = %s WHERE id = %s',
                (f'Unit {order_num}', existing[order_num])
            )

    # 2. Get all words from DB
    cur.execute(f'SELECT id, english FROM {SCHEMA}.words')
    db_words = cur.fetchall()

    # 3. Match and update each word
    updated = 0
    unmatched = []
    for word_id, english in db_words:
        norm = normalize_key(english)
        if norm in word_to_unit:
            unit_order = word_to_unit[norm]
            new_unit_id = existing[unit_order]
            new_chinese = word_to_cn.get(norm, '')

            cur.execute(
                f'UPDATE {SCHEMA}.words SET unit_id = %s, chinese = %s WHERE id = %s',
                (new_unit_id, new_chinese, word_id)
            )
            updated += 1
        else:
            unmatched.append(english)

    print(f"  Updated {updated} words with new unit assignments.")
    if unmatched:
        print(f"  WARNING: {len(unmatched)} words could not be matched:")
        for w in unmatched[:10]:
            print(f"    - {w}")
        if len(unmatched) > 10:
            print(f"    ... and {len(unmatched) - 10} more")

    # 4. Remove any extra units (beyond 1-12)
    cur.execute(f"DELETE FROM {SCHEMA}.units WHERE order_num > 12 OR order_num < 1")


def _fresh_import(cur, units, en_to_cn, normalized_lookup):
    """Full DELETE + INSERT when no existing data to preserve."""
    SCHEMA = 'senior_compulsory_1_beijing'

    cur.execute(f'DELETE FROM {SCHEMA}.words')
    cur.execute(f'DELETE FROM {SCHEMA}.units')

    total = 0
    for i, (unit_name, words) in enumerate(units.items()):
        cur.execute(
            f'INSERT INTO {SCHEMA}.units (name, order_num) VALUES (%s, %s) RETURNING id',
            (unit_name, i + 1)
        )
        unit_id = cur.fetchone()[0]

        for word in words:
            norm = normalize_key(word)
            cn = normalized_lookup.get(norm, '')
            if not cn:
                for orig_key, cn_val in en_to_cn.items():
                    if normalize_key(orig_key) == norm:
                        cn = cn_val
                        break
            cur.execute(
                f'INSERT INTO {SCHEMA}.words (unit_id, english, chinese) VALUES (%s, %s, %s)',
                (unit_id, word, cn)
            )
            total += 1
        print(f"  {unit_name}: {len(words)} words")

    print(f"  Total: {total} words in {len(units)} units.")


if __name__ == '__main__':
    main()
