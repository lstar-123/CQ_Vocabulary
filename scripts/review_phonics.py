"""Interactive human review tool for phonics annotations.

Randomly samples words with reviewed=FALSE and lets a teacher
accept, reject, or regenerate each annotation.

Usage:
    # Review 20 random words
    python scripts/review_phonics.py

    # Review 50 words from a specific schema
    python scripts/review_phonics.py --schema grade6_vol1 --count 50

    # Use a fixed random seed for reproducibility
    python scripts/review_phonics.py --seed 42 --count 30

Accepted words: reviewed → TRUE (preserved from future overwrites)
Rejected words: kept as-is (data preserved for manual correction)
Regenerated:   Claude re-generates, reviewed stays FALSE
"""
import argparse
import json
import os
import random
import sys
import textwrap
from datetime import datetime, timezone
from typing import Any

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
from dotenv import load_dotenv

load_dotenv()

WORDS_URL = os.getenv('WORDS_DATABASE_URL', '')
ANTHROPIC_API_KEY = (
    os.getenv('ANTHROPIC_AUTH_TOKEN', '') or
    os.getenv('ANTHROPIC_API_KEY', '')
)
ANTHROPIC_BASE_URL = os.getenv('ANTHROPIC_BASE_URL', None)
DEFAULT_MODEL = os.getenv('ANTHROPIC_MODEL') or os.getenv('PHONICS_MODEL', 'claude-sonnet-5')

MANUAL_OVERRIDES_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'data', 'manual_overrides.json'
)

# ---------------------------------------------------------------------------
# Display helpers
# ---------------------------------------------------------------------------

DIVIDER = '═' * 56
THIN = '─' * 56


def show_entry(entry: dict):
    """Pretty-print a phonics entry for review."""
    print(DIVIDER)
    print(f'Word:      {entry["word"]}')
    print(f'IPA:       {entry["ipa"]}')
    print(f'ARPABET:   {entry["arpabet"]}')
    print(DIVIDER)

    syllables = entry.get('syllables', [])
    stress = entry.get('stress', [])
    syl_str = ' · '.join(syllables)
    stress_str = '    '.join(str(s) for s in stress)
    print(f'Syllables: {syl_str}')
    if stress:
        print(f'Stress:    {stress_str}')

    # Validate reconstruction
    syl_joined = ''.join(syllables)
    if syl_joined.lower().strip() != entry['word'].lower().strip():
        print(f'  !! WARNING: syllables reconstruct to "{syl_joined}" — MISMATCH with word')
    print()

    # Segments display
    silent_found = []
    seg_parts = []
    for seg in entry.get('segments', []):
        text = seg.get('text', seg.get('letters', ''))
        silent = seg.get('silent', False)
        if silent:
            silent_found.append(text)
            seg_parts.append(f'[{text}]')
        else:
            seg_parts.append(text)

    print(f'Segments: {" ".join(seg_parts)}')
    print()

    # Validate segment reconstruction
    joined = ''.join(s.get('text', s.get('letters', '')) for s in entry.get('segments', []))
    if joined != entry['word']:
        print(f'  !! WARNING: segments reconstruct to "{joined}" — MISMATCH with word')
    else:
        print(f'  OK: segments reconstruct to word correctly')
    print()

    if silent_found:
        print(f'Silent: {", ".join(silent_found)}')
    else:
        print('Silent: (none)')
    print(DIVIDER)


def show_menu():
    """Print action menu."""
    print('[a]ccept    — confirm and mark reviewed')
    print('[r]eject    — keep data, mark as needing manual fix')
    print('[g]enerate  — re-call Claude for this word')
    print('[s]kip      — move to next word without changes')
    print('[q]uit      — exit and show summary')
    print()
    print('Choice > ', end='', flush=True)


# ---------------------------------------------------------------------------
# Claude regeneration
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """\
You are an English phonics teacher annotating a single English word for \
Chinese primary and middle school students.

## CRITICAL: Follow the CamelliaQuill Phonics Annotation Spec

### Silent letter rules
Every silent letter MUST be its own segment with "silent":true:
- kn-: k(silent)+n    wr-: w(silent)+r    gn-: g(silent)+n
- dge: d(silent)+ge   tch: t(silent)+ch
- -mb: m+b(silent)    -bt: b(silent)+t
- -stle: s+t(silent)+le   word-final silent e: e(silent)

### Grapheme integrity (NEVER split these)
sh, ch, th, ph, ng, nk, ck, qu, igh, eigh, ough, augh
tion, sion, cian, ture, sure, tial, cial, cious, tious
Vowel digraphs: ai, ay, ea, ee, oa, oo, ou, ow, oi, oy — never split
R-controlled: ar, er, ir, ur, or, air, ear — never split

### Segment format
Each segment has ONLY two fields: "text" and "silent".
"".join(seg.text) MUST equal the original word.

Return ONLY a single JSON object (not an array), no markdown, no explanation:
{
  "word": "...",
  "ipa": "/.../",
  "arpabet": "...",
  "syllables": ["...", "..."],
  "stress": [1, 0],
  "segments": [
    {"text": "k", "silent": true},
    {"text": "n", "silent": false}
  ]
}"""


def regenerate_word(word: str, model: str) -> dict:
    """Call Claude to regenerate phonics for a single word."""
    import anthropic

    if not ANTHROPIC_API_KEY:
        raise RuntimeError(
            'No API key found. Set ANTHROPIC_API_KEY or ANTHROPIC_AUTH_TOKEN in .env'
        )

    client_kwargs = {'api_key': ANTHROPIC_API_KEY}
    if ANTHROPIC_BASE_URL:
        client_kwargs['base_url'] = ANTHROPIC_BASE_URL
    client = anthropic.Anthropic(**client_kwargs)

    message = client.messages.create(
        model=model,
        max_tokens=2048,
        temperature=0.3,
        thinking={"type": "disabled"},
        system=SYSTEM_PROMPT,
        messages=[{
            'role': 'user',
            'content': f'Annotate this word: "{word}"',
        }],
    )

    text = ''
    for block in message.content:
        if hasattr(block, 'text'):
            text += block.text

    text = text.strip()
    if text.startswith('```'):
        lines = text.split('\n')
        if lines[0].startswith('```'):
            lines = lines[1:]
        if lines and lines[-1].startswith('```'):
            lines = lines[:-1]
        text = '\n'.join(lines)

    return json.loads(text)


# ---------------------------------------------------------------------------
# Database helpers
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
    return {
        'host': host, 'port': port, 'user': user,
        'password': password, 'dbname': dbname,
    }


def load_manual_overrides() -> dict:
    try:
        with open(MANUAL_OVERRIDES_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_manual_overrides(overrides: dict):
    os.makedirs(os.path.dirname(MANUAL_OVERRIDES_PATH), exist_ok=True)
    with open(MANUAL_OVERRIDES_PATH, 'w', encoding='utf-8') as f:
        json.dump(overrides, f, ensure_ascii=False, indent=2)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Review phonics annotations and accept/reject/regenerate.'
    )
    parser.add_argument('--schema', default=None, help='Book schema filter')
    parser.add_argument('--count', type=int, default=20, help='Words to review (default: 20)')
    parser.add_argument('--seed', type=int, default=None, help='Random seed')
    parser.add_argument('--model', default=None, help=f'Claude model (default: {DEFAULT_MODEL})')
    args = parser.parse_args()

    model = args.model or DEFAULT_MODEL

    if args.seed is not None:
        random.seed(args.seed)

    if not WORDS_URL:
        print('ERROR: WORDS_DATABASE_URL not set in .env', file=sys.stderr)
        sys.exit(1)

    cfg = parse_db_url(WORDS_URL)
    conn = psycopg2.connect(**cfg)
    cur = conn.cursor()

    # Discover schemas
    cur.execute("""
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name NOT IN (
            'public', 'information_schema', 'pg_catalog', 'pg_toast'
        )
        ORDER BY schema_name
    """)
    all_schemas = [r[0] for r in cur.fetchall()]
    schemas = [s for s in all_schemas if not args.schema or s == args.schema]

    if not schemas:
        print('No schemas found.')
        cur.close()
        conn.close()
        return

    # Collect unreviewed words with phonics_data
    words_pool = []
    for schema in schemas:
        try:
            cur.execute(
                f'SELECT id, english, phonics_data FROM {schema}.words'
                ' WHERE phonics_data IS NOT NULL AND (reviewed IS NULL OR reviewed = FALSE)'
            )
            for row in cur.fetchall():
                words_pool.append((schema, row[0], row[1], row[2]))
        except Exception as e:
            print(f'[{schema}] ERROR: {e}', file=sys.stderr)

    if not words_pool:
        print('No unreviewed words with phonics data found.')
        print('Run generate_phonics_dataset.py first.')
        cur.close()
        conn.close()
        return

    # Sample
    sample_size = min(args.count, len(words_pool))
    sample = random.sample(words_pool, sample_size)

    print(f'Reviewing {sample_size} of {len(words_pool)} unreviewed word(s).\n')

    manual_overrides = load_manual_overrides()
    stats = {'accepted': 0, 'rejected': 0, 'regenerated': 0, 'skipped': 0}

    for idx, (schema, word_id, english, phonics_data) in enumerate(sample):
        # phonics_data is already a dict (JSONB auto-parsed by psycopg2)
        if isinstance(phonics_data, str):
            phonics_data = json.loads(phonics_data)

        print(f'\n[{idx+1}/{sample_size}] Schema: {schema}')
        show_entry(phonics_data)

        while True:
            show_menu()
            try:
                choice = input().strip().lower()
            except (EOFError, KeyboardInterrupt):
                print('\n\nInterrupted.')
                choice = 'q'

            if choice == 'a':
                # Accept: set reviewed=true in DB
                cur.execute(
                    f'UPDATE {schema}.words SET reviewed = TRUE WHERE id = %s',
                    (word_id,)
                )
                conn.commit()
                stats['accepted'] += 1
                print('  ✓ Accepted (reviewed = true)\n')
                break

            elif choice == 'r':
                # Reject: leave data as-is, mark with negative version
                cur.execute(
                    f'UPDATE {schema}.words SET reviewed = FALSE, phonics_version = -1 WHERE id = %s',
                    (word_id,)
                )
                conn.commit()
                stats['rejected'] += 1
                print('  ✗ Rejected (data preserved, needs manual fix)\n')
                break

            elif choice == 'g':
                # Regenerate: call Claude for single word
                print(f'  Regenerating "{english}" via Claude...', end=' ', flush=True)
                try:
                    new_data = regenerate_word(english, model)
                    # Validate basic structure
                    if 'word' not in new_data or 'segments' not in new_data:
                        print('FAILED (invalid response format)')
                        break
                    cur.execute(
                        f'UPDATE {schema}.words SET'
                        '  phonics_data = %s,'
                        '  generated_by = %s,'
                        '  generated_at = %s,'
                        '  reviewed = FALSE'
                        ' WHERE id = %s',
                        (
                            json.dumps(new_data),
                            f'claude:{model}',
                            datetime.now(timezone.utc),
                            word_id,
                        )
                    )
                    conn.commit()
                    stats['regenerated'] += 1
                    print('OK')
                    # Show new data
                    show_entry(new_data)
                    # Ask whether to accept
                    print('[a]ccept regenerated result? [any other key] keep as unreviewed')
                    second = input('> ').strip().lower()
                    if second == 'a':
                        cur.execute(
                            f'UPDATE {schema}.words SET reviewed = TRUE WHERE id = %s',
                            (word_id,)
                        )
                        conn.commit()
                        stats['accepted'] += 1
                        stats['regenerated'] -= 1
                        print('  ✓ Accepted (reviewed = true)\n')
                    else:
                        print('  Kept as unreviewed.\n')
                except Exception as e:
                    print(f'FAILED: {e}')
                break

            elif choice == 's':
                stats['skipped'] += 1
                print('  → Skipped\n')
                break

            elif choice == 'q':
                print('\n')
                break

            else:
                print('  Invalid choice. Please type a, r, g, s, or q.')

        if choice == 'q':
            break

    # -------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------
    cur.close()
    conn.close()

    print()
    print('=' * 56)
    print('REVIEW SESSION SUMMARY')
    print('=' * 56)
    print(f'  Accepted:    {stats["accepted"]}')
    print(f'  Rejected:    {stats["rejected"]}')
    print(f'  Regenerated: {stats["regenerated"]}')
    print(f'  Skipped:     {stats["skipped"]}')
    print(f'  Total:       {sum(stats.values())}')

    # Count remaining unreviewed
    remaining = len(words_pool) - sum(
        1 for s, wid, e, pd in sample
        if any(
            stats['accepted'] and s == sample[i][0] and wid == sample[i][1]
            for i in range(len(sample))
        )
    )
    # Actually recount from DB
    conn2 = psycopg2.connect(**cfg)
    cur2 = conn2.cursor()
    total_unreviewed = 0
    for schema in schemas:
        try:
            cur2.execute(
                f'SELECT COUNT(*) FROM {schema}.words'
                ' WHERE phonics_data IS NOT NULL AND (reviewed IS NULL OR reviewed = FALSE)'
            )
            total_unreviewed += cur2.fetchone()[0]
        except Exception:
            pass
    cur2.close()
    conn2.close()

    print(f'\nRemaining unreviewed: {total_unreviewed} word(s)')
    print()
    print('Tip: Run again to review more words.')
    print('  python scripts/review_phonics.py --count 50')


if __name__ == '__main__':
    main()
