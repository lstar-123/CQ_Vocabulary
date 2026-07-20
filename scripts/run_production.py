"""Production orchestrator for generating phonics data across all schemas.

Features:
- Batch generation with resume support
- Saves each word to data/phonics_cache/<schema>/<word>.json as permanent backup
- Tracks failed words to failed_words.json
- Tracks latency and progress
- Post-generation spot-check against PHONICS_ANNOTATION_SPEC.md

Usage:
    python scripts/run_production.py
    python scripts/run_production.py --batch-size 20 --schema grade6_vol1
"""
import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import psycopg2
from dotenv import load_dotenv

load_dotenv()

# Import from sibling script
import generate_phonics_dataset as gen_mod

SYSTEM_PROMPT = gen_mod.SYSTEM_PROMPT
build_batch_prompt = gen_mod.build_batch_prompt
validate_phonics_entry = gen_mod.validate_phonics_entry

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
WORDS_URL = os.getenv('WORDS_DATABASE_URL', '')
ANTHROPIC_API_KEY = (
    os.getenv('ANTHROPIC_AUTH_TOKEN', '') or
    os.getenv('ANTHROPIC_API_KEY', '')
)
ANTHROPIC_BASE_URL = os.getenv('ANTHROPIC_BASE_URL', None)
DEFAULT_MODEL = os.getenv('ANTHROPIC_MODEL') or os.getenv('PHONICS_MODEL', 'claude-sonnet-5')

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE_ROOT = os.path.join(PROJECT_ROOT, 'data', 'phonics_cache')
MANUAL_OVERRIDES_PATH = os.path.join(PROJECT_ROOT, 'data', 'manual_overrides.json')
FAILED_WORDS_PATH = os.path.join(PROJECT_ROOT, 'data', 'failed_words.json')
SPEC_PATH = os.path.join(PROJECT_ROOT, 'docs', 'PHONICS_ANNOTATION_SPEC.md')

BATCH_SIZE = 20


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


def get_schemas(cur, filter_schema=None):
    cur.execute("""
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name NOT IN (
            'public', 'information_schema', 'pg_catalog', 'pg_toast'
        ) ORDER BY schema_name
    """)
    all_schemas = [r[0] for r in cur.fetchall()]
    if filter_schema:
        return [s for s in all_schemas if s == filter_schema]
    return all_schemas


# ---------------------------------------------------------------------------
# Cache helpers
# ---------------------------------------------------------------------------
def save_cache(schema: str, word: str, data: dict):
    """Save phonics_data to cache file as permanent backup."""
    safe_word = word.replace('/', '_').replace('\\', '_').replace(' ', '_')
    schema_dir = os.path.join(CACHE_ROOT, schema)
    os.makedirs(schema_dir, exist_ok=True)
    filepath = os.path.join(schema_dir, f'{safe_word}.json')
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


# ---------------------------------------------------------------------------
# Claude API
# ---------------------------------------------------------------------------
def call_claude_batch(words: list[str], model: str) -> list[dict]:
    """Send a batch of words to Claude, return parsed JSON list."""
    import anthropic

    if not ANTHROPIC_API_KEY:
        raise RuntimeError(
            'No API key found. Set ANTHROPIC_API_KEY or ANTHROPIC_AUTH_TOKEN in .env'
        )

    client_kwargs = {'api_key': ANTHROPIC_API_KEY}
    if ANTHROPIC_BASE_URL:
        client_kwargs['base_url'] = ANTHROPIC_BASE_URL
    client = anthropic.Anthropic(**client_kwargs)
    prompt = build_batch_prompt(words)

    t0 = time.time()
    message = client.messages.create(
        model=model,
        max_tokens=8192,
        temperature=0.3,
        thinking={"type": "disabled"},
        system=SYSTEM_PROMPT,
        messages=[{'role': 'user', 'content': prompt}],
    )
    latency = time.time() - t0

    # Extract text
    text = ''
    input_tokens = 0
    output_tokens = 0
    if hasattr(message, 'usage'):
        input_tokens = message.usage.input_tokens
        output_tokens = message.usage.output_tokens
    for block in message.content:
        if hasattr(block, 'text'):
            text += block.text

    # Parse JSON
    text = text.strip()
    if text.startswith('```'):
        lines = text.split('\n')
        if lines[0].startswith('```'):
            lines = lines[1:]
        if lines and lines[-1].startswith('```'):
            lines = lines[:-1]
        text = '\n'.join(lines)

    try:
        result = json.loads(text)
    except json.JSONDecodeError as e:
        import re
        match = re.search(r'\[.*\]', text, re.DOTALL)
        if match:
            result = json.loads(match.group())
        else:
            raise RuntimeError(
                f'Failed to parse Claude response as JSON: {e}\n'
                f'First 500 chars: {text[:500]}'
            ) from e

    if not isinstance(result, list):
        raise RuntimeError(f'Expected JSON array, got {type(result).__name__}')

    return result, latency, input_tokens, output_tokens


# ---------------------------------------------------------------------------
# Spot-check
# ---------------------------------------------------------------------------
def spot_check(cur, schemas: list[str], count: int = 20):
    """Randomly sample generated words and verify against spec rules."""
    import random

    # Collect all generated words
    pool = []
    for schema in schemas:
        cur.execute(
            f"SELECT english, phonics_data FROM {schema}.words"
            " WHERE phonics_data IS NOT NULL"
        )
        for english, phonics_data in cur.fetchall():
            if isinstance(phonics_data, str):
                phonics_data = json.loads(phonics_data)
            pool.append((schema, english, phonics_data))

    if not pool:
        print('\nNo generated words to spot-check.')
        return

    sample_size = min(count, len(pool))
    sample = random.sample(pool, sample_size)

    print(f'\n{"="*60}')
    print(f'SPOT-CHECK: {sample_size} randomly selected words')
    print(f'{"="*60}')

    violations = []
    for schema, word, data in sample:
        issues = check_spec_compliance(word, data)
        if issues:
            violations.append({'word': word, 'schema': schema, 'issues': issues})
            print(f'\nFAIL {word} [{schema}]')
            for issue in issues:
                print(f'  - {issue}')
        else:
            print(f'\nOK {word} [{schema}] — OK')

    print(f'\n{"="*60}')
    if violations:
        print(f'VIOLATIONS FOUND: {len(violations)} word(s)')
    else:
        print(f'ALL {sample_size} WORDS PASS spec compliance check')
    print(f'{"="*60}')

    return violations


def check_spec_compliance(word: str, data: dict) -> list[str]:
    """Check a v2 phonics entry against spec rules."""
    issues = []

    if not isinstance(data, dict):
        return ['data is not a dict']

    syllables = data.get('syllables', [])

    # Word match
    if data.get('word', '').lower() != word.lower():
        issues.append(f'word mismatch: {data.get("word")} vs {word}')

    # Check v2 structure: syllables must be objects with segments
    if not isinstance(syllables, list) or len(syllables) == 0:
        issues.append('syllables is empty or not an array')
        return issues

    total_seg_count = 0
    stress_vals = []
    all_seg_texts = []

    for si, syl in enumerate(syllables):
        if not isinstance(syl, dict):
            issues.append(f'syllable[{si}]: not an object')
            continue
        stress_vals.append(syl.get('stress', 0))
        segs = syl.get('segments', [])
        if not isinstance(segs, list):
            issues.append(f'syllable[{si}]: segments not an array')
            continue

        # Check syllable segments reconstruct to syllable text
        syl_text = syl.get('text', '')
        syl_joined = ''.join(s.get('text', '') for s in segs)
        if syl_joined != syl_text:
            issues.append(f'syllable[{si}]: segs join to "{syl_joined}", expected "{syl_text}"')

        for sgi, seg in enumerate(segs):
            total_seg_count += 1
            text = seg.get('text', '')
            # Silent letter: must be single letter
            if seg.get('silent') and len(text) > 1:
                if text not in ('gh',):
                    issues.append(f'syl[{si}].seg[{sgi}] "{text}": multi-letter silent')
            # Known anti-patterns
            if not seg.get('silent') and text in ('kn','wr','gn','pn','ps','dge','tch','mb','bt'):
                issues.append(f'syl[{si}].seg[{sgi}] "{text}": should split silent letter')
            # Rule must exist
            if not seg.get('rule', '').strip():
                issues.append(f'syl[{si}].seg[{sgi}]: rule is empty')

        all_seg_texts.append(syl_joined)

    # Stress validation
    if stress_vals.count(1) != 1:
        issues.append(f'stress has {stress_vals.count(1)} primary, expected 1')

    # Full reconstruction
    full = ''.join(all_seg_texts)
    wc = word.replace(' ','').replace('-','').replace('.','').replace('/','')
    fc = full.replace(' ','').replace('-','').replace('.','').replace('/','')
    if fc != wc:
        issues.append(f'full reconstruct to "{full}", expected "{word}"')

    # IPA check
    ipa = data.get('ipa', '')
    if ipa and not ipa.startswith('/'):
        issues.append('ipa missing /')

    return issues


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description='Production phonics data generator.')
    parser.add_argument('--batch-size', type=int, default=BATCH_SIZE,
                        help=f'Words per batch (default: {BATCH_SIZE})')
    parser.add_argument('--schema', default=None,
                        help='Process only one schema')
    parser.add_argument('--spot-check-only', action='store_true',
                        help='Only run spot-check, no generation')
    args = parser.parse_args()

    # -------------------------------------------------------------------
    # Pre-flight checks
    # -------------------------------------------------------------------
    if not WORDS_URL:
        print('ERROR: WORDS_DATABASE_URL not set', file=sys.stderr)
        sys.exit(1)

    if not args.spot_check_only and not ANTHROPIC_API_KEY:
        print('ERROR: ANTHROPIC_API_KEY not set in .env', file=sys.stderr)
        print('Add: ANTHROPIC_API_KEY=sk-ant-... to .env', file=sys.stderr)
        sys.exit(1)

    model = DEFAULT_MODEL
    batch_size = min(args.batch_size, 50)

    cfg = parse_db_url(WORDS_URL)
    conn = psycopg2.connect(**cfg)
    cur = conn.cursor()

    schemas = get_schemas(cur, args.schema)
    if not schemas:
        print('No schemas found.')
        cur.close(); conn.close()
        return

    # -------------------------------------------------------------------
    # Spot-check only mode
    # -------------------------------------------------------------------
    if args.spot_check_only:
        spot_check(cur, schemas, count=20)
        cur.close(); conn.close()
        return

    # -------------------------------------------------------------------
    # Load manual overrides
    # -------------------------------------------------------------------
    overrides = {}
    try:
        with open(MANUAL_OVERRIDES_PATH, 'r', encoding='utf-8') as f:
            raw = json.load(f)
            overrides = {
                k.lower(): v for k, v in raw.items()
                if isinstance(v, dict) and v.get('reviewed')
            }
    except (FileNotFoundError, json.JSONDecodeError):
        pass

    if overrides:
        print(f'Manual overrides: {len(overrides)} word(s) protected.\n')

    # -------------------------------------------------------------------
    # Production run
    # -------------------------------------------------------------------
    print(f'{"="*60}')
    print(f'PRODUCTION PHONICS GENERATION')
    print(f'{"="*60}')
    print(f'Model:      {model}')
    print(f'Batch size: {batch_size}')
    print(f'Schemas:    {", ".join(schemas)}')
    print(f'Cache:      {CACHE_ROOT}')
    print()

    total_start = time.time()
    all_stats = {
        'generated': 0, 'skipped': 0, 'failed': 0,
        'total_input_tokens': 0, 'total_output_tokens': 0,
        'total_latency': 0.0,
    }
    failed_words = []

    for schema in schemas:
        # Count words
        cur.execute(f'SELECT COUNT(*) FROM {schema}.words')
        schema_total = cur.fetchone()[0]
        cur.execute(
            f'SELECT COUNT(*) FROM {schema}.words WHERE phonics_data IS NOT NULL'
        )
        already_done = cur.fetchone()[0]

        # Fetch words to process
        cur.execute(
            f'SELECT id, english FROM {schema}.words'
            ' WHERE phonics_data IS NULL'
            ' ORDER BY id'
        )
        pending = cur.fetchall()

        # Filter out manual overrides
        words_to_process = []
        for wid, en in pending:
            if en.lower().strip() in overrides:
                continue
            words_to_process.append((wid, en))

        if not words_to_process:
            print(f'[{schema}] {schema_total} words, {already_done} done, 0 pending.\n')
            continue

        print(f'[{schema}] {schema_total} total, {already_done} done, '
              f'{len(pending)-len(words_to_process)} protected, '
              f'{len(words_to_process)} to generate.\n')

        # Process batches
        total = len(words_to_process)
        for batch_start in range(0, total, batch_size):
            batch_end = min(batch_start + batch_size, total)
            batch = words_to_process[batch_start:batch_end]
            batch_words = [w[1] for w in batch]

            batch_num = batch_start // batch_size + 1
            total_batches = (total + batch_size - 1) // batch_size
            preview = ', '.join(batch_words[:4])
            print(
                f'[{schema}] Batch {batch_num}/{total_batches} '
                f'({batch_start+1}-{batch_end}/{total}): '
                f'{preview}...',
                end=' ', flush=True
            )

            try:
                results, latency, in_tok, out_tok = call_claude_batch(
                    batch_words, model
                )
                all_stats['total_latency'] += latency
                all_stats['total_input_tokens'] += in_tok
                all_stats['total_output_tokens'] += out_tok
            except Exception as e:
                print(f'\n  CLAUDE ERROR: {e}')
                print(f'  Recording {len(batch_words)} word(s) as failed.')
                for wid, en in batch:
                    failed_words.append({
                        'word': en, 'schema': schema,
                        'reason': f'Claude API error: {str(e)[:200]}'
                    })
                    all_stats['failed'] += len(batch)
                conn.commit()
                time.sleep(2)
                continue

            # Validate and write
            results_by_word = {}
            for entry in results:
                w = entry.get('word', '').lower().strip()
                results_by_word[w] = entry

            batch_ok = 0
            for wid, en in batch:
                key = en.lower().strip()
                if key not in results_by_word:
                    failed_words.append({
                        'word': en, 'schema': schema,
                        'reason': 'Claude did not return this word'
                    })
                    all_stats['failed'] += 1
                    continue

                entry = results_by_word[key]
                errors = validate_phonics_entry(entry, en)
                if errors:
                    failed_words.append({
                        'word': en, 'schema': schema,
                        'reason': f'Validation: {"; ".join(errors[:5])}'
                    })
                    all_stats['failed'] += 1
                    print(f'\n  VALIDATION FAILED: {en} — {errors[0]}')
                    continue

                # Write to DB
                cur.execute(
                    f'UPDATE {schema}.words SET'
                    '  phonics_data = %s,'
                    '  phonics_version = 1,'
                    '  generated_by = %s,'
                    '  generated_at = %s,'
                    '  reviewed = FALSE'
                    ' WHERE id = %s',
                    (
                        json.dumps(entry),
                        f'claude:{model}',
                        datetime.now(timezone.utc),
                        wid,
                    )
                )

                # Save to cache file
                try:
                    save_cache(schema, en, entry)
                except Exception as e:
                    print(f'\n  WARNING: cache save failed for {en}: {e}')

                batch_ok += 1

            conn.commit()
            all_stats['generated'] += batch_ok

            avg_lat = all_stats['total_latency'] / batch_num if batch_num > 0 else 0
            print(
                f'OK ({batch_ok}/{len(batch)}) '
                f'| {all_stats["generated"]}/{total} done '
                f'| {latency:.1f}s | '
                f'Σ{all_stats["total_input_tokens"]}/{all_stats["total_output_tokens"]} tok'
            )

            time.sleep(1)  # Rate limiting

        print()

    # -------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------
    total_elapsed = time.time() - total_start
    cur.close(); conn.close()

    print(f'\n{"="*60}')
    print(f'GENERATION COMPLETE')
    print(f'{"="*60}')

    # Per-schema stats
    conn2 = psycopg2.connect(**cfg); cur2 = conn2.cursor()
    grand_total = 0; grand_done = 0
    for schema in schemas:
        cur2.execute(f'SELECT COUNT(*) FROM {schema}.words')
        st = cur2.fetchone()[0]
        cur2.execute(
            f'SELECT COUNT(*) FROM {schema}.words WHERE phonics_data IS NOT NULL'
        )
        sd = cur2.fetchone()[0]
        grand_total += st; grand_done += sd
        print(f'  {schema}: {st} words, {sd} with phonics_data')
    cur2.close(); conn2.close()

    print(f'\n  Total words:        {grand_total}')
    print(f'  Generated this run:  {all_stats["generated"]}')
    print(f'  Skipped (existing):  {all_stats["skipped"]}')
    print(f'  Failed:              {all_stats["failed"]}')
    print(f'  Coverage:            {grand_done}/{grand_total} '
          f'({100*grand_done//grand_total if grand_total else 0}%)')

    print(f'\n  Elapsed:      {total_elapsed:.0f}s '
          f'({total_elapsed/60:.1f} min)')
    if all_stats['generated'] > 0:
        print(f'  Avg latency:  {all_stats["total_latency"]/max(1, all_stats["generated"]//batch_size):.1f}s/batch')
    print(f'  Input tokens:  {all_stats["total_input_tokens"]}')
    print(f'  Output tokens: {all_stats["total_output_tokens"]}')

    # Save failed words
    if failed_words:
        with open(FAILED_WORDS_PATH, 'w', encoding='utf-8') as f:
            json.dump(failed_words, f, ensure_ascii=False, indent=2)
        print(f'\n  Failed words saved to: {FAILED_WORDS_PATH}')
        for fw in failed_words:
            print(f'    FAIL {fw["word"]} [{fw["schema"]}]: {fw["reason"][:80]}')

    # Count cache files
    cache_count = 0
    for schema in schemas:
        schema_dir = os.path.join(CACHE_ROOT, schema)
        if os.path.isdir(schema_dir):
            cache_count += len([
                f for f in os.listdir(schema_dir) if f.endswith('.json')
            ])
    print(f'\n  Cache files:   {cache_count}')

    print(f'{"="*60}')

    # -------------------------------------------------------------------
    # Spot-check
    # -------------------------------------------------------------------
    if all_stats['generated'] > 0:
        conn3 = psycopg2.connect(**cfg); cur3 = conn3.cursor()
        violations = spot_check(cur3, schemas, count=20)
        cur3.close(); conn3.close()

        if violations:
            print(f'\nWARNING: {len(violations)} word(s) have spec violations.')
            print('   Review these manually before marking as reviewed.')
        else:
            print('\nOK  All spot-checked words pass spec compliance.')


if __name__ == '__main__':
    main()
