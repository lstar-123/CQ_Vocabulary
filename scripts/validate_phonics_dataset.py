"""Comprehensive phonics_data v2 schema validator and dataset report generator.

Scans all 441 words, validates v2 schema compliance, and produces:
  1. Error report (any schema violations)
  2. Dataset statistics report → docs/PHONICS_DATASET_REPORT.md

Usage:
    python scripts/validate_phonics_dataset.py
    python scripts/validate_phonics_dataset.py --fix    # auto-fix minor issues
    python scripts/validate_phonics_dataset.py --sample 50  # spot-check N random words
"""
import argparse
import json
import os
import random
import sys
from collections import Counter
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
from dotenv import load_dotenv

load_dotenv()

WORDS_URL = os.getenv('WORDS_DATABASE_URL', '')
REPORT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'docs', 'PHONICS_DATASET_REPORT.md'
)

# ---------------------------------------------------------------------------
# Schema definition
# ---------------------------------------------------------------------------
TOP_KEYS = {'word', 'ipa', 'arpabet', 'syllables'}
SYL_KEYS = {'text', 'stress', 'segments'}
SEG_KEYS = {'text', 'silent', 'rule'}


def validate_entry(word: str, data: dict) -> list[str]:
    """Validate a single v2 phonics entry. Returns list of error messages."""
    errors = []

    if not isinstance(data, dict):
        return ['data is not a dict']

    # ---- Top-level keys ----
    actual_top = set(data.keys())
    extra_top = actual_top - TOP_KEYS
    missing_top = TOP_KEYS - actual_top
    if missing_top:
        errors.append(f'missing top-level keys: {missing_top}')
    if extra_top:
        errors.append(f'extra top-level keys: {extra_top}')

    if missing_top:
        return errors

    # Null checks
    for k in TOP_KEYS:
        if data[k] is None:
            errors.append(f'{k} is null')
    if data.get('ipa', '') == '':
        errors.append('ipa is empty')
    if data.get('arpabet', '') == '':
        errors.append('arpabet is empty')

    # ---- Syllables ----
    syllables = data.get('syllables')
    if not isinstance(syllables, list) or len(syllables) == 0:
        errors.append('syllables is empty or not a list')
        return errors

    for si, syl in enumerate(syllables):
        if not isinstance(syl, dict):
            errors.append(f'syl[{si}]: not an object')
            continue

        syl_keys = set(syl.keys())
        if syl_keys - SYL_KEYS:
            errors.append(f'syl[{si}]: extra keys {syl_keys - SYL_KEYS}')
        if SYL_KEYS - syl_keys:
            errors.append(f'syl[{si}]: missing keys {SYL_KEYS - syl_keys}')
            continue

        # Null/empty checks
        if not syl.get('text', ''):
            errors.append(f'syl[{si}]: text is empty')
        if syl.get('stress') is None:
            errors.append(f'syl[{si}]: stress is null')
        stress = syl.get('stress', 0)
        if stress not in (0, 1, 2):
            errors.append(f'syl[{si}]: stress={stress}, must be 0/1/2')

        segs = syl.get('segments')
        if not isinstance(segs, list) or len(segs) == 0:
            errors.append(f'syl[{si}]: segments empty or not a list')
            continue

        syl_text = syl['text']
        reconstructed = ''

        for sgi, seg in enumerate(segs):
            if not isinstance(seg, dict):
                errors.append(f'syl[{si}].seg[{sgi}]: not an object')
                continue

            seg_keys = set(seg.keys())
            if seg_keys - SEG_KEYS:
                errors.append(f'syl[{si}].seg[{sgi}]: extra keys {seg_keys - SEG_KEYS}')
            if SEG_KEYS - seg_keys:
                errors.append(f'syl[{si}].seg[{sgi}]: missing keys {SEG_KEYS - seg_keys}')
                continue

            # Type checks
            text = seg.get('text')
            if text is None or text == '':
                errors.append(f'syl[{si}].seg[{sgi}]: text is null/empty')
            if not isinstance(seg.get('silent'), bool):
                stype = type(seg.get('silent')).__name__
                errors.append(f'syl[{si}].seg[{sgi}]: silent must be bool, got {stype}')
            rule = seg.get('rule')
            if rule is None or rule == '':
                errors.append(f'syl[{si}].seg[{sgi}]: rule is null/empty')

            if text:
                reconstructed += text

        # Syllable text must match segment reconstruction
        if reconstructed != syl_text:
            errors.append(
                f'syl[{si}]: segs reconstruct to "{reconstructed}", '
                f'expected "{syl_text}"'
            )

    # ---- Full-word reconstruction ----
    all_syl_texts = [s.get('text', '') for s in syllables]
    full_recon = ''.join(all_syl_texts)
    # For parenthetical textbook entries like "recognise (NAmE -ize)",
    # only the pre-parenthesis part is segmented. Compare against that.
    compare_word = word
    if '(' in compare_word:
        compare_word = compare_word.split('(')[0]
    # Strip separators for comparison
    expected_word = compare_word.replace(' ', '').replace('-', '').replace('.', '').replace('/', '')
    if full_recon != expected_word:
        errors.append(
            f'word reconstruction: "{full_recon}" vs expected "{expected_word}"'
        )

    return errors


# ---------------------------------------------------------------------------
# Dataset statistics
# ---------------------------------------------------------------------------

def compute_stats(all_data: list[tuple[str, str, dict]]) -> dict:
    """Compute aggregate statistics across the dataset."""
    stats = {
        'total_words': len(all_data),
        'total_syllables': 0,
        'total_segments': 0,
        'total_silent_segments': 0,
        'rule_counts': Counter(),
        'multi_syllable_count': 0,
        'max_syllables': 0,
        'max_segments_per_word': 0,
    }

    for schema, word, data in all_data:
        syls = data.get('syllables', [])
        n_syl = len(syls)
        stats['total_syllables'] += n_syl
        if n_syl > 1:
            stats['multi_syllable_count'] += 1
        if n_syl > stats['max_syllables']:
            stats['max_syllables'] = n_syl

        word_segs = 0
        for syl in syls:
            segs = syl.get('segments', [])
            n_seg = len(segs)
            stats['total_segments'] += n_seg
            word_segs += n_seg
            for seg in segs:
                if seg.get('silent'):
                    stats['total_silent_segments'] += 1
                rule = seg.get('rule', '')
                if rule:
                    stats['rule_counts'][rule] += 1

        if word_segs > stats['max_segments_per_word']:
            stats['max_segments_per_word'] = word_segs

    if stats['total_words'] > 0:
        stats['avg_syllables'] = round(stats['total_syllables'] / stats['total_words'], 2)
        stats['avg_segments'] = round(stats['total_segments'] / stats['total_words'], 2)

    return stats


def generate_report(stats: dict, errors: list):
    """Write PHONICS_DATASET_REPORT.md."""
    os.makedirs(os.path.dirname(REPORT_PATH), exist_ok=True)

    with open(REPORT_PATH, 'w', encoding='utf-8') as f:
        f.write('# Phonics Dataset Report\n\n')
        f.write(f'> Auto-generated: {datetime.now(timezone.utc).isoformat()}\n\n')

        f.write('## Summary\n\n')
        f.write(f'| Metric | Value |\n|--------|-------|\n')
        f.write(f'| Total words | {stats["total_words"]} |\n')
        f.write(f'| Total syllables | {stats["total_syllables"]} |\n')
        f.write(f'| Total segments | {stats["total_segments"]} |\n')
        f.write(f'| Silent segments | {stats["total_silent_segments"]} |\n')
        f.write(f'| Multi-syllable words | {stats["multi_syllable_count"]} |\n')
        f.write(f'| Avg syllables/word | {stats.get("avg_syllables", 0)} |\n')
        f.write(f'| Avg segments/word | {stats.get("avg_segments", 0)} |\n')
        f.write(f'| Max syllables | {stats["max_syllables"]} |\n')
        f.write(f'| Max segments/word | {stats["max_segments_per_word"]} |\n\n')

        # Rule distribution
        f.write('## Rule Distribution\n\n')
        f.write(f'| Rule | Count |\n|------|-------|\n')
        for rule, count in stats['rule_counts'].most_common(50):
            f.write(f'| `{rule}` | {count} |\n')

        # Errors
        f.write(f'\n## Validation Errors\n\n')
        if errors:
            f.write(f'**{len(errors)} error(s) found.**\n\n')
            for schema, word, word_errors in errors:
                f.write(f'- **{word}** [{schema}]\n')
                for e in word_errors:
                    f.write(f'  - {e}\n')
        else:
            f.write('✅ No validation errors.\n')

    print(f'Report written to: {REPORT_PATH}')


# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

def parse_db_url(url: str) -> dict:
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


def main():
    parser = argparse.ArgumentParser(description='Validate phonics_data v2 schema.')
    parser.add_argument('--sample', type=int, default=0, help='Only check N random words')
    parser.add_argument('--fix', action='store_true', help='Auto-fix minor issues')
    parser.add_argument('--schema', default=None, help='Filter by schema')
    args = parser.parse_args()

    if not WORDS_URL:
        print('ERROR: WORDS_DATABASE_URL not set', file=sys.stderr)
        sys.exit(1)

    cfg = parse_db_url(WORDS_URL)
    conn = psycopg2.connect(**cfg)
    cur = conn.cursor()

    # Discover schemas
    cur.execute("""
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name NOT IN ('public', 'information_schema', 'pg_catalog', 'pg_toast')
        ORDER BY schema_name
    """)
    all_schemas = [r[0] for r in cur.fetchall()]
    schemas = [s for s in all_schemas if not args.schema or s == args.schema]

    # Collect all data
    all_data = []
    for schema in schemas:
        cur.execute(
            f'SELECT english, phonics_data FROM {schema}.words'
            ' WHERE phonics_data IS NOT NULL ORDER BY id'
        )
        for english, pd in cur.fetchall():
            if isinstance(pd, str):
                pd = json.loads(pd)
            all_data.append((schema, english, pd))

    print(f'Loaded {len(all_data)} words from {len(schemas)} schema(s).')

    # Sample if requested
    if args.sample and args.sample > 0:
        all_data = random.sample(all_data, min(args.sample, len(all_data)))
        print(f'Sampled {len(all_data)} words.')

    # Validate
    errors = []
    fixes_applied = 0
    for schema, word, data in all_data:
        word_errors = validate_entry(word, data)
        if word_errors:
            errors.append((schema, word, word_errors))

    # Report
    print(f'\n{"=" * 60}')
    if errors:
        print(f'VALIDATION FAILED: {len(errors)} word(s) with errors')
        for schema, word, word_errors in errors:
            print(f'\n  {word} [{schema}]:')
            for e in word_errors:
                print(f'    - {e}')
    else:
        print('ALL WORDS VALID — no schema violations.')
    print(f'{"=" * 60}')

    # Statistics
    stats = compute_stats(all_data)
    print(f'\nTotal words:       {stats["total_words"]}')
    print(f'Total syllables:   {stats["total_syllables"]}')
    print(f'Total segments:    {stats["total_segments"]}')
    print(f'Silent segments:   {stats["total_silent_segments"]}')
    print(f'Avg syllables:     {stats.get("avg_syllables", 0)}')
    print(f'Avg segments:      {stats.get("avg_segments", 0)}')
    print(f'Unique rules:      {len(stats["rule_counts"])}')
    print(f'Top rules:         {dict(stats["rule_counts"].most_common(10))}')

    # Generate report
    generate_report(stats, errors)

    cur.close()
    conn.close()

    if errors:
        sys.exit(1)


if __name__ == '__main__':
    main()
