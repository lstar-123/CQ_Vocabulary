"""Parse a vocabulary markdown file and import words into PostgreSQL.

Usage:
    python import_words.py                           # default: grade6_vol1, vocabulary_6_1.md
    python import_words.py --schema senior_compulsory_1 --file data/vocabulary_10_1.md
"""
import os
import re
import sys
import argparse

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
from dotenv import load_dotenv

load_dotenv()


def parse_markdown(filepath):
    """Parse vocabulary markdown file into structured data.

    Returns:
        list of { 'unit_name': str, 'words': [{ 'english': str, 'chinese': str }] }
    """
    units = []
    current_unit = None

    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line_stripped = line.strip()

            # Skip empty lines
            if not line_stripped:
                continue

            # Detect unit header: "- Unit N" (at start of line, no leading spaces)
            unit_match = re.match(r'^#+\s*(Unit\s+\d+.*)$', line_stripped)
            if unit_match:
                current_unit = {'unit_name': unit_match.group(1).strip(), 'words': []}
                units.append(current_unit)
                continue

            # Detect word line: indented "- english  chinese"
            # English and Chinese are separated by 2+ spaces
            word_match = re.match(r'^\s+-\s+(.+?)\s{2,}(.+?)\s*$', line)
            if word_match and current_unit is not None:
                english = word_match.group(1).strip()
                chinese = word_match.group(2).strip()
                current_unit['words'].append({'english': english, 'chinese': chinese})

    return units


def import_to_db(units, schema_name):
    """Insert parsed units and words into vocab_quiz_words.<schema>."""
    db_url = os.getenv('WORDS_DATABASE_URL')
    if not db_url:
        print('ERROR: WORDS_DATABASE_URL not set in .env', file=sys.stderr)
        sys.exit(1)

    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    try:
        # Clear existing data for this schema
        cur.execute(f'DELETE FROM {schema_name}.words')
        cur.execute(f'DELETE FROM {schema_name}.units')

        total_words = 0
        for i, unit_data in enumerate(units):
            # Insert unit
            cur.execute(
                f'INSERT INTO {schema_name}.units (name, order_num) VALUES (%s, %s) ON CONFLICT (name) DO UPDATE SET order_num = EXCLUDED.order_num RETURNING id',
                (unit_data['unit_name'], i + 1)
            )
            unit_id = cur.fetchone()[0]

            # Insert words for this unit
            for word in unit_data['words']:
                cur.execute(
                    f'INSERT INTO {schema_name}.words (unit_id, english, chinese) VALUES (%s, %s, %s)',
                    (unit_id, word['english'], word['chinese'])
                )
                total_words += 1

            print(f"  {unit_data['unit_name']}: {len(unit_data['words'])} words")

        conn.commit()
        print(f"\nDone. {len(units)} units, {total_words} words imported into {schema_name}.")

    except Exception as e:
        conn.rollback()
        print(f"Error: {e}", file=sys.stderr)
        raise
    finally:
        cur.close()
        conn.close()


def main():
    parser = argparse.ArgumentParser(description='Import vocabulary from markdown into a word book schema.')
    parser.add_argument('--schema', default='grade6_vol1',
                        choices=['grade6_vol1', 'senior_compulsory_1'],
                        help='Target schema in vocab_quiz_words (default: grade6_vol1)')
    parser.add_argument('--file', default=None,
                        help='Path to markdown file (default: data/vocabulary_6_1.md for grade6_vol1)')
    args = parser.parse_args()

    # Resolve default file path based on schema
    if args.file:
        filepath = args.file
        if not os.path.isabs(filepath):
            filepath = os.path.join(os.path.dirname(__file__), '..', filepath)
    else:
        default_files = {
            'grade6_vol1': 'data/vocabulary_6_1.md',
            'senior_compulsory_1': 'data/vocabulary_10_1.md',
        }
        filepath = os.path.join(
            os.path.dirname(__file__), '..',
            default_files.get(args.schema, 'data/vocabulary_6_1.md')
        )

    if not os.path.exists(filepath):
        print(f'ERROR: File not found: {filepath}', file=sys.stderr)
        sys.exit(1)

    print(f"Parsing {filepath}...")
    units = parse_markdown(filepath)

    if not units:
        print("No units found in markdown file.", file=sys.stderr)
        sys.exit(1)

    print(f"Found {len(units)} units:")
    for u in units:
        print(f"  {u['unit_name']}: {len(u['words'])} words")

    print(f"\nImporting to vocab_quiz_words.{args.schema}...")
    import_to_db(units, args.schema)


if __name__ == '__main__':
    main()
