"""Migrate phonics_data from v1 (flat segments) to v2 (nested syllables.segments).

v1 format:
    {word, ipa, arpabet, syllables: [str], stress: [int],
     segments: [{text, silent}, ...]}

v2 format:
    {word, ipa, arpabet,
     syllables: [{text, stress, segments: [{text, silent, rule}]}]}

Algorithm: walk flat segments[] and syllable strings[] in parallel,
distributing segments into their parent syllables by character count.
Rule is inferred from grapheme text + silent status.

Usage:
    python scripts/migrate_phonics_v2.py          # migrate all schemas
    python scripts/migrate_phonics_v2.py --dry-run  # preview only
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
from dotenv import load_dotenv

load_dotenv()

WORDS_URL = os.getenv('WORDS_DATABASE_URL', '')

# ---------------------------------------------------------------------------
# Rule inference — maps grapheme text + silent flag to a stable rule name
# ---------------------------------------------------------------------------

KNOWN_GRAPHEMES = {
    # Consonant digraphs
    'sh': 'sh', 'ch': 'ch', 'th': 'th', 'ph': 'ph', 'ng': 'ng', 'nk': 'nk',
    'ck': 'ck', 'qu': 'qu', 'wh': 'wh',
    # Trigraphs/tetragraphs
    'igh': 'igh', 'eigh': 'eigh', 'ough': 'ough', 'augh': 'augh',
    # Suffixes
    'tion': 'tion', 'sion': 'sion', 'cian': 'cian',
    'ture': 'ture', 'sure': 'sure',
    'tial': 'tial', 'cial': 'cial',
    'cious': 'cious', 'tious': 'tious',
    # Vowel digraphs
    'ai': 'ai', 'ay': 'ay', 'ea': 'ea', 'ee': 'ee', 'ei': 'ei', 'ey': 'ey',
    'ie': 'ie', 'oa': 'oa', 'oe': 'oe', 'oi': 'oi', 'oy': 'oy',
    'oo': 'oo', 'ou': 'ou', 'ow': 'ow', 'au': 'au', 'aw': 'aw',
    'ew': 'ew', 'ui': 'ui', 'ue': 'ue',
    # R-controlled
    'ar': 'ar', 'er': 'er', 'ir': 'ir', 'ur': 'ur', 'or': 'or',
    'air': 'air', 'are': 'are', 'ear': 'ear', 'ire': 'ire', 'ore': 'ore',
    'ure': 'ure',
    # Silent-letter splits (these should appear as non-silent after silent letter removed)
    'ge': 'dge',  # ge after silent d
    # Other
    'dge': 'dge', 'tch': 'tch',
    'sten': 'sten', 'stle': 'stle', 'ften': 'ften',
}

SINGLE_VOWELS = set('aeiouy')
SINGLE_CONSONANTS = set('bcdfghjklmnpqrstvwxz')


def infer_rule(text: str, silent: bool) -> str:
    """Infer a stable rule name for a segment."""
    text_lower = text.lower().strip()

    # Silence
    if silent and len(text_lower) == 1:
        return f'silent-{text_lower}'
    if silent:
        return f'silent-{text_lower}'

    # Known multi-letter grapheme
    if text_lower in KNOWN_GRAPHEMES:
        return KNOWN_GRAPHEMES[text_lower]

    # Space / punctuation
    if text_lower in (' ', '-', '.', '/', "'", '…'):
        return 'separator'

    # Single letter
    if len(text_lower) == 1:
        if text_lower in SINGLE_VOWELS:
            return f'vowel-{text_lower}'
        if text_lower in SINGLE_CONSONANTS:
            return f'consonant-{text_lower}'
        return f'letter-{text_lower}'

    # Multi-letter grapheme not in the known list (e.g., rare digraph)
    return text_lower


# ---------------------------------------------------------------------------
# Migration logic
# ---------------------------------------------------------------------------

def migrate_entry(old_data: dict) -> dict | None:
    """Convert v1 phonics_data to v2. Returns None on failure."""
    if not old_data:
        return None

    old_segments = old_data.get('segments', [])
    old_syllables = old_data.get('syllables', [])
    old_stress = old_data.get('stress', [])

    # Normalize old_syllables: if dicts, extract text
    old_syl_texts = []
    for s in old_syllables:
        if isinstance(s, dict):
            old_syl_texts.append(s.get('text', ''))
        else:
            old_syl_texts.append(s)

    if not old_segments or not old_syl_texts:
        return None

    # Normalize old_segments: accept either {text, silent} or {letters, silent}
    norm_segs = []
    for seg in old_segments:
        norm_segs.append({
            'text': seg.get('text', seg.get('letters', '')),
            'silent': seg.get('silent', False),
        })

    # Walk segments into syllables, splitting segments that span boundaries.
    # Separator segments (space, punctuation) between words are inter-syllable
    # and belong to neither the preceding nor following syllable.
    SEPARATORS = {' ', '-', '.', '/', '…', '(', ')', "'"}
    seg_idx = 0
    seg_remainder = ''
    seg_remainder_silent = False
    new_syllables = []

    for syl_i, syl_text in enumerate(old_syl_texts):
        consumed = ''
        syl_segs = []

        # First, consume any remainder from a previously split segment
        if seg_remainder:
            syl_segs.append({
                'text': seg_remainder,
                'silent': seg_remainder_silent,
                'rule': infer_rule(seg_remainder, seg_remainder_silent),
            })
            consumed += seg_remainder
            seg_remainder = ''

        # Skip leading separators before a syllable
        while seg_idx < len(norm_segs) and norm_segs[seg_idx]['text'] in SEPARATORS:
            seg_idx += 1

        while seg_idx < len(norm_segs) and len(consumed) < len(syl_text):
            seg = norm_segs[seg_idx]
            seg_text = seg['text']

            # If we hit a separator mid-syllable, skip it (it's between words)
            if seg_text in SEPARATORS:
                seg_idx += 1
                continue

            remaining = len(syl_text) - len(consumed)

            if len(seg_text) <= remaining:
                syl_segs.append({
                    'text': seg_text,
                    'silent': seg['silent'],
                    'rule': infer_rule(seg_text, seg['silent']),
                })
                consumed += seg_text
                seg_idx += 1
            else:
                part = seg_text[:remaining]
                remainder = seg_text[remaining:]
                syl_segs.append({
                    'text': part,
                    'silent': seg['silent'],
                    'rule': infer_rule(part, seg['silent']),
                })
                consumed += part
                seg_remainder = remainder
                seg_remainder_silent = seg['silent']
                seg_idx += 1

        joined = ''.join(s['text'] for s in syl_segs)
        if joined != syl_text:
            return None

        stress_val = old_stress[syl_i] if syl_i < len(old_stress) else 0
        new_syllables.append({
            'text': syl_text,
            'stress': stress_val,
            'segments': syl_segs,
        })

    # Verify full reconstruction (allow separators to be omitted for multi-word phrases)
    full_joined = ''.join(
        ''.join(s['text'] for s in syl['segments'])
        for syl in new_syllables
    )
    word = old_data.get('word', '')
    # Strip spaces and common separators for comparison
    word_compact = word.replace(' ', '').replace('-', '').replace('.', '').replace('/', '').replace('…', '')
    full_compact = full_joined.replace(' ', '').replace('-', '').replace('.', '').replace('/', '').replace('…', '')
    if full_compact != word_compact:
        return None

    return {
        'word': word,
        'ipa': old_data.get('ipa', ''),
        'arpabet': old_data.get('arpabet', ''),
        'syllables': new_syllables,
    }


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
    parser = argparse.ArgumentParser(description='Migrate phonics_data v1 → v2.')
    parser.add_argument('--dry-run', action='store_true', help='Preview only, no writes')
    parser.add_argument('--schema', default=None, help='Single schema to migrate')
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

    print('=' * 60)
    print('PHONICS DATA MIGRATION: v1 → v2')
    print('=' * 60)
    if args.dry_run:
        print('[DRY RUN — no database writes]\n')

    total_migrated = 0
    total_failed = 0
    total_skipped = 0

    for schema in schemas:
        cur.execute(
            f'SELECT id, english, phonics_data FROM {schema}.words'
            ' WHERE phonics_data IS NOT NULL ORDER BY id'
        )
        rows = cur.fetchall()

        if not rows:
            print(f'[{schema}] No phonics_data found.')
            continue

        print(f'\n[{schema}] {len(rows)} words to migrate.')

        migrated = 0
        failed = 0
        skipped = 0

        for word_id, english, phonics_data in rows:
            if isinstance(phonics_data, str):
                phonics_data = json.loads(phonics_data)

            # Check if already v2 (has syllables as objects with segments)
            syls = phonics_data.get('syllables', [])
            if syls and isinstance(syls[0], dict) and 'segments' in syls[0]:
                skipped += 1
                continue

            new_data = migrate_entry(phonics_data)

            if new_data is None:
                failed += 1
                print(f'  FAIL: {english} — cannot align segments to syllables')
                continue

            if args.dry_run:
                migrated += 1
                continue

            # Write back
            cur.execute(
                f'UPDATE {schema}.words SET phonics_data = %s, phonics_version = 2 WHERE id = %s',
                (json.dumps(new_data), word_id),
            )
            migrated += 1

        if not args.dry_run and migrated > 0:
            conn.commit()

        print(f'  Migrated: {migrated}  Failed: {failed}  Skipped (already v2): {skipped}')
        total_migrated += migrated
        total_failed += failed
        total_skipped += skipped

    cur.close()
    conn.close()

    print(f'\n{"=" * 60}')
    if args.dry_run:
        print(f'DRY RUN — would migrate {total_migrated}, {total_failed} fail, {total_skipped} skip')
    else:
        print(f'Migration complete: {total_migrated} migrated, {total_failed} failed, {total_skipped} skipped')
    print(f'{"=" * 60}')

    if total_failed > 0:
        print('\nFailed words need Claude regeneration. Run:')
        print('  python scripts/generate_phonics_dataset.py --overwrite --schema <schema>')


if __name__ == '__main__':
    main()
