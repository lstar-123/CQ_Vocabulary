"""Parse a vocabulary markdown file and import words into PostgreSQL.

Usage:
    python import_words.py                           # default: grade6_vol1, vocabulary_6_1.md
    python import_words.py --schema senior_compulsory_1 --file data/vocabulary_10_1.md
    python import_words.py --schema senior_compulsory_1_beijing --file data/vocabulary_10_1_BeiJing.md
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
    """Parse vocabulary markdown file (list format) into structured data.

    Expected format:
        ## UNIT 1 LIFE CHOICES
        ### Topic Talk
        | 单词/短语     | 中文意思                         |
        | ------------- | -------------------------------- |
        | senior        | 较高的，高级的                   |

    Also supports older indented-list format:
        # Unit 1
          - english  chinese

    Returns:
        list of { 'unit_name': str, 'words': [{ 'english': str, 'chinese': str }] }
    """
    units = []
    current_unit = None

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Detect format: if file has "| 序号 |" table header, use table parser
    if re.search(r'\|\s*序号\s*\|', content):
        return parse_table_markdown(filepath)

    lines = content.split('\n')

    # State machine for the markdown table format with #/##/### headers
    in_table = False
    table_header_skipped = False

    for line in lines:
        line_stripped = line.strip()

        if not line_stripped:
            in_table = False
            table_header_skipped = False
            continue

        # Detect section header: ## UNIT N or ### Lesson N etc.
        section_match = re.match(r'^#+\s+(.+)$', line_stripped)
        if section_match:
            in_table = False
            table_header_skipped = False
            section_name = section_match.group(1).strip()

            # Skip the top-level title (e.g., "# 高中英语必修一 单词表")
            if not re.match(r'^Unit\s+\d+', section_name) and not re.match(r'^(Topic\s+Talk|Lesson|Unit)', section_name):
                continue

            current_unit = {'unit_name': section_name, 'words': []}
            units.append(current_unit)
            continue

        # Detect table header line: | 单词/短语 | 中文意思 |
        if re.match(r'^\|\s*单词', line_stripped) or re.match(r'^\|\s*英语', line_stripped):
            in_table = True
            table_header_skipped = False
            continue

        # Detect table separator: | --- | --- |
        if in_table and not table_header_skipped and re.match(r'^\|[\s\-|]+$', line_stripped):
            table_header_skipped = True
            continue

        # Detect table data row: | english | chinese |
        table_row = re.match(r'^\|\s*(.+?)\s*\|\s*(.+?)\s*\|', line_stripped)
        if table_row and current_unit is not None:
            english = table_row.group(1).strip()
            chinese = table_row.group(2).strip()
            current_unit['words'].append({'english': english, 'chinese': chinese})
            continue

        # Legacy indented list format: "  - english  chinese"
        word_match = re.match(r'^\s+-\s+(.+?)\s{2,}(.+?)\s*$', line)
        if word_match and current_unit is not None:
            english = word_match.group(1).strip()
            chinese = word_match.group(2).strip()
            current_unit['words'].append({'english': english, 'chinese': chinese})

    return units


def parse_table_markdown(filepath):
    """Parse table-format vocabulary markdown (BeiJing Normal University format).

    Format:
        # Title
        | 序号 | 核心词排序 | 词频 | 单词 | 释义 |
        |------|------|------|------|------|
        | 1 | 41 | 36 | patience | 耐心 |

    Since there are no unit divisions, all words go into a single unit
    named after the file's title.

    Returns:
        list of { 'unit_name': str, 'words': [{ 'english': str, 'chinese': str }] }
    """
    units = []
    unit_name = None

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    in_table = False
    table_header_skipped = False

    for line in lines:
        line_stripped = line.strip()

        if not line_stripped:
            continue

        # Title line: "# 高中英语必修一 单词表（北师大版）"
        title_match = re.match(r'^#\s+(.+)$', line_stripped)
        if title_match and not in_table:
            unit_name = title_match.group(1).strip()
            # Remove "单词表" suffix for cleaner name
            unit_name = re.sub(r'\s*单词表.*$', '', unit_name)
            continue

        # Table header: | 序号 | 核心词排序 | 词频 | 单词 | 释义 |
        if re.match(r'^\|\s*序号\s*\|', line_stripped):
            in_table = True
            table_header_skipped = False
            continue

        # Table separator: |------|------|------|------|------|
        if in_table and not table_header_skipped and re.match(r'^\|[\s\-|]+$', line_stripped):
            table_header_skipped = True
            continue

        # Data row: | 1 | 41 | 36 | patience | 耐心 |
        # Some rows have empty columns: | 145 | | | secondary | 中等教育；中级的；次要的 |
        if in_table and table_header_skipped:
            parts = line_stripped.split('|')
            # parts: ['', ' 1 ', ' 41 ', ' 36 ', ' patience ', ' 耐心 ', '']
            # Filter out empty first/last from split
            parts = [p.strip() for p in parts if p.strip()]
            if len(parts) >= 5:
                # Format: 序号, 核心词排序, 词频, 单词, 释义
                english = parts[3].strip()
                chinese = parts[4].strip()
            elif len(parts) >= 2:
                # Fallback: assume last two non-empty are english and chinese
                english = parts[-2].strip()
                chinese = parts[-1].strip()
            else:
                continue

            if english:
                if unit_name is None:
                    unit_name = 'Vocabulary'
                # Create unit on first word
                if not units:
                    units.append({'unit_name': unit_name, 'words': []})
                units[0]['words'].append({'english': english, 'chinese': chinese})

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
                        choices=['grade6_vol1', 'senior_compulsory_1', 'senior_compulsory_1_beijing'],
                        help='Target schema in vocab_quiz_words (default: grade6_vol1)')
    parser.add_argument('--file', default=None,
                        help='Path to markdown file (default: auto-detected from schema)')
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
            'senior_compulsory_1_beijing': 'data/vocabulary_10_1_BeiJing.md',
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
