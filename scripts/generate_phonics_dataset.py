"""Offline phonics dataset generator using Claude API.

Iterates over all words in the vocabulary database and generates
phonics annotations (IPA, ARPABET, syllables, grapheme-phoneme segments)
via Claude. Results are written directly to the database.

Usage:
    # Generate for all schemas, all words (resume-safe)
    python scripts/generate_phonics_dataset.py --resume

    # Generate for a single schema, limit to 100 words
    python scripts/generate_phonics_dataset.py --schema grade6_vol1 --limit 100 --resume

    # Regenerate all non-reviewed words
    python scripts/generate_phonics_dataset.py --overwrite --batch-size 30

    # Dry-run: see what would be generated without calling Claude
    python scripts/generate_phonics_dataset.py --dry-run --limit 50

Flags:
    --schema       Book schema to process (default: all)
    --limit        Max total words to process (0 = all)
    --resume       Skip words that already have phonics_data
    --overwrite    Regenerate words that have phonics_data (skips reviewed=true)
    --batch-size   Words per Claude API call (default: 30, max: 50)
    --dry-run      Print what would be done without calling Claude
    --model        Claude model to use (default: from PHONICS_MODEL env or claude-sonnet-5)
"""
import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
from dotenv import load_dotenv

load_dotenv()

# ---------------------------------------------------------------------------
# Configuration — supports both Anthropic official API and compatible providers
# ---------------------------------------------------------------------------
WORDS_URL = os.getenv('WORDS_DATABASE_URL', '')

# Anthropic-compatible providers: use AUTH_TOKEN as api_key, BASE_URL as base_url
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
# Claude Prompt
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """\
You are an English phonics teacher annotating words for Chinese primary and \
middle school students (ages 8–16). Your annotations populate a vocabulary \
learning app that helps students connect spelling to pronunciation.

## CRITICAL: You MUST follow the CamelliaQuill Phonics Annotation Specification

This project has a single authoritative annotation standard at
`docs/PHONICS_ANNOTATION_SPEC.md`. Every annotation you produce MUST conform
to that specification. You are NOT allowed to invent alternative segmentation
strategies. The rules below are extracted from the spec — follow them exactly.

---

## ABSOLUTE GRAPHEME INTEGRITY RULES (Never Split These)

These multi-letter graphemes are ALWAYS one segment — NEVER split them:

sh→SH  ch→CH/K/SH  th→TH/DH  ph→F  ng→NG  nk→NG K  ck→K  qu→K W
igh→AY  eigh→EY  ough→(varies)  augh→AO/AE F
tion→SH AH N  sion→ZH AH N/SH AH N  cian→SH AH N
ture→CH ER  sure→ZH ER  tial→SH AH L  cial→SH AH L
cious→SH AH S  tious→SH AH S
ai→EY  ay→EY  ea→IY/EH/EY  ee→IY  ei→EY/IY/AY  ey→EY/IY
ie→IY/AY/IH  oa→OW  oe→OW  oi→OY  oy→OY  oo→UW/UH
ou→AW/OW/UW/UH  ow→AW/OW  au→AO  aw→AO  ew→UW/Y UW  ui→UW/IH  ue→UW/Y UW
ar→AA R  er→ER  ir→ER  ur→ER  or→AO R  air→EH R  are→EH R
ear→IH R/EH R/ER  ire→AY ER  ore→AO R  ure→Y UH R/UH R

## ABSOLUTE SILENT LETTER RULES (Always Split These)

EVERY silent letter MUST be its own segment with "silent":true. Never merge
a silent letter with an adjacent grapheme:

- kn- at word start: k(silent) + n→N    NEVER kn→N
- wr- at word start: w(silent) + r→R    NEVER wr→R
- gn- at word start: g(silent) + n→N    NEVER gn→N
- pn- at word start: p(silent) + n→N    NEVER pn→N
- ps- at word start: p(silent) + s→S    NEVER ps→S
- rh- at word start: r→R + h(silent)    NEVER rh→R
- -mb at word end:  m→M + b(silent)     NEVER mb→M
- -bt:              b(silent) + t→T     NEVER bt→T
- dge:              d(silent) + ge→JH   NEVER dge→JH
- tch:              t(silent) + ch→CH   NEVER tch→CH
- -stle: s→S + t(silent) + le→AH L     NEVER stle→S AH L
- -sten: s→S + t(silent) + en→AH N     NEVER sten→S AH N
- -ften: f→F + t(silent) + en→AH N     NEVER ften→F AH N
- Word-final silent e: always its own segment e(silent)
- wh- before o (who):  w(silent) + h→HH
- wh- other vowels:    w→W + h(silent)
- h- before o (honest, hour): h(silent)

Note: When gh is inside igh/eigh/ough/augh, the entire trigraph/tetragraph
is kept whole. Do NOT split out the gh as silent segments.

## SYLLABLE RULES

- Compound words: split between words (sun·set)
- Prefixes/suffixes in §5.3-5.4 of the spec: split at affix boundary
- Consonant-le (-ble, -ple, -dle, -gle, -tle, -cle): always its own syllable
- -tion/-sion/-cian: always its own syllable, split before it
- syllables[i] is a SUBSTRING of word, NOT IPA

## IPA & ARPABET CONVENTIONS

Use standard IPA with /.../ delimiters. Stress: ˈ primary, ˌ secondary.
ARPABET: space-separated, every vowel has stress digit (0/1/2).
Schwa /ə/ = AH in ARPABET.

Refer to §8 of the spec for the full IPA↔ARPABET mapping table.

## OUTPUT FORMAT

Return ONLY a JSON array — no markdown, no explanation, no code fences.
Each word is one object. Segments are nested inside their parent syllable.
There is NO top-level "segments" array — segments live under syllables.

```json
{
  "word": "knowledge",
  "ipa": "/ˈnɒlɪdʒ/",
  "arpabet": "N AA1 L AH0 JH",
  "syllables": [
    {
      "text": "know",
      "stress": 1,
      "segments": [
        {"text": "k", "silent": true,  "rule": "silent-k"},
        {"text": "n", "silent": false, "rule": "consonant-n"},
        {"text": "o", "silent": false, "rule": "vowel-o"},
        {"text": "w", "silent": true,  "rule": "silent-w"}
      ]
    },
    {
      "text": "ledge",
      "stress": 0,
      "segments": [
        {"text": "l",  "silent": false, "rule": "consonant-l"},
        {"text": "e",  "silent": false, "rule": "schwa"},
        {"text": "d",  "silent": true,  "rule": "silent-d-in-dge"},
        {"text": "ge", "silent": false, "rule": "dge"}
      ]
    }
  ]
}
```

### CRITICAL RULES

1. Each syllable has: "text" (substring of word), "stress" (0/1/2), "segments" (array)
2. Within each syllable: "".join(seg.text for seg in segments) MUST equal syllable.text
3. All syllable.text joined together MUST equal the original word (spaces/punctuation between words are omitted from syllables)
4. EVERY silent letter is its own segment with "silent":true
5. Multi-letter graphemes (sh,ch,th,ph,ck,ng,nk,qu,igh,eigh,ough,augh,tion,sion,cian,ture,sure) are ONE segment
6. Each segment has EXACTLY three fields: "text", "silent", "rule"
7. "rule" is a stable identifier like "silent-k", "sh", "igh", "magic-e", "consonant-n", "vowel-a"
8. There is NO top-level "segments" or "stress" array — those live inside syllables only

## MOST IMPORTANT

If the spec says a grapheme is NEVER split or a silent letter is ALWAYS
separate, you MUST follow that rule. Consistency across all words in the
dataset is more important than linguistic optimality for any single word.

These rules are ABSOLUTE. There are NO exceptions for "edge cases."
"""


def build_batch_prompt(words: list[str]) -> str:
    """Build the user prompt for a batch of words."""
    word_list = '\n'.join(f'- {w}' for w in words)
    return f"""Annotate these {len(words)} English words with phonics data.

Words:
{word_list}

Return a JSON array with one object per word. Each object must follow the
format specified in the system prompt."""


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

def validate_phonics_entry(entry: dict, expected_word: str) -> list[str]:
    """Validate a v2 phonics entry. Returns list of error messages."""
    errors = []

    # Required top-level keys (v2: no top-level segments or stress)
    for key in ['word', 'ipa', 'arpabet', 'syllables']:
        if key not in entry:
            errors.append(f'missing key: {key}')

    if errors:
        return errors

    # Word match
    entry_word = (entry.get('word') or '').lower().strip()
    if entry_word != expected_word.lower().strip():
        errors.append(f'word mismatch: expected "{expected_word}", got "{entry["word"]}"')

    syllables = entry.get('syllables', [])
    if not isinstance(syllables, list) or len(syllables) == 0:
        errors.append('syllables must be a non-empty array')
        return errors

    # Validate each syllable
    all_seg_texts = []
    for si, syl in enumerate(syllables):
        if not isinstance(syl, dict):
            errors.append(f'syllable[{si}]: must be an object')
            continue

        syl_text = syl.get('text', '')
        if not syl_text:
            errors.append(f'syllable[{si}]: missing "text"')

        if 'stress' not in syl:
            errors.append(f'syllable[{si}]: missing "stress"')

        segs = syl.get('segments', [])
        if not isinstance(segs, list) or len(segs) == 0:
            errors.append(f'syllable[{si}]: "segments" must be a non-empty array')
            continue

        # Validate segments within syllable
        for sgi, seg in enumerate(segs):
            for field in ['text', 'silent', 'rule']:
                if field not in seg:
                    errors.append(f'syllable[{si}].segment[{sgi}]: missing "{field}"')
            if not seg.get('rule', '').strip():
                errors.append(f'syllable[{si}].segment[{sgi}]: rule is empty')
            for extra in set(seg.keys()) - {'text', 'silent', 'rule'}:
                errors.append(f'syllable[{si}].segment[{sgi}]: unexpected field "{extra}"')

        # Syllable segments must reconstruct to syllable text
        syl_joined = ''.join(s.get('text', '') for s in segs)
        if syl_joined != syl_text:
            errors.append(
                f'syllable[{si}]: segments join to "{syl_joined}", '
                f'expected "{syl_text}"'
            )

        all_seg_texts.append(syl_joined)

    # All syllable texts joined must reconstruct to word (without separators)
    full_joined = ''.join(all_seg_texts)
    word_compact = expected_word.replace(' ', '').replace('-', '').replace('.', '').replace('/', '')
    joined_compact = full_joined.replace(' ', '').replace('-', '').replace('.', '').replace('/', '')
    if joined_compact != word_compact:
        errors.append(
            f'all syllables reconstruct to "{full_joined}", expected "{expected_word}"'
        )

    return errors


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


def get_schemas(cur, filter_schema: str | None = None) -> list[str]:
    """Discover all book schemas."""
    cur.execute("""
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name NOT IN (
            'public', 'information_schema', 'pg_catalog', 'pg_toast'
        )
        ORDER BY schema_name
    """)
    all_schemas = [r[0] for r in cur.fetchall()]
    if filter_schema:
        return [s for s in all_schemas if s == filter_schema]
    return all_schemas


def load_manual_overrides() -> dict:
    try:
        with open(MANUAL_OVERRIDES_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


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

    message = client.messages.create(
        model=model,
        max_tokens=8192,
        temperature=0.3,
        thinking={"type": "disabled"},
        system=SYSTEM_PROMPT,
        messages=[{'role': 'user', 'content': prompt}],
    )

    # Extract text from response
    text = ''
    for block in message.content:
        if hasattr(block, 'text'):
            text += block.text

    # Parse JSON — handle possible markdown code fences
    text = text.strip()
    if text.startswith('```'):
        # Remove code fences
        lines = text.split('\n')
        if lines[0].startswith('```'):
            lines = lines[1:]
        if lines and lines[-1].startswith('```'):
            lines = lines[:-1]
        text = '\n'.join(lines)

    try:
        result = json.loads(text)
    except json.JSONDecodeError as e:
        # Try to find JSON array in the text
        import re
        match = re.search(r'\[.*\]', text, re.DOTALL)
        if match:
            result = json.loads(match.group())
        else:
            raise RuntimeError(
                f'Failed to parse Claude response as JSON: {e}\n'
                f'Raw response (first 500 chars): {text[:500]}'
            ) from e

    if not isinstance(result, list):
        raise RuntimeError(
            f'Expected JSON array, got {type(result).__name__}'
        )

    return result


# ---------------------------------------------------------------------------
# Main generator
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Generate phonics data for vocabulary words via Claude API.'
    )
    parser.add_argument('--schema', default=None, help='Book schema (default: all)')
    parser.add_argument('--limit', type=int, default=0, help='Max words to process (0=all)')
    parser.add_argument('--resume', action='store_true', help='Skip words with existing phonics_data')
    parser.add_argument('--overwrite', action='store_true', help='Regenerate existing phonics_data (skips reviewed)')
    parser.add_argument('--batch-size', type=int, default=30, help='Words per Claude call (default: 30)')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be done without calling Claude')
    parser.add_argument('--model', default=None, help=f'Claude model (default: {DEFAULT_MODEL})')
    args = parser.parse_args()

    model = args.model or DEFAULT_MODEL
    batch_size = min(args.batch_size, 50)

    if args.dry_run:
        print('[DRY RUN] No Claude API calls will be made.\n')

    if not WORDS_URL:
        print('ERROR: WORDS_DATABASE_URL not set in .env', file=sys.stderr)
        sys.exit(1)

    # -----------------------------------------------------------------------
    # Load manual overrides
    # -----------------------------------------------------------------------
    manual_overrides = load_manual_overrides()
    override_words = {
        w.lower() for w, entry in manual_overrides.items()
        if entry.get('reviewed')
    }
    if override_words:
        print(f'Manual overrides loaded: {len(override_words)} word(s) will be skipped.\n')

    # -----------------------------------------------------------------------
    # Connect to DB and discover schemas
    # -----------------------------------------------------------------------
    cfg = parse_db_url(WORDS_URL)
    conn = psycopg2.connect(**cfg)
    cur = conn.cursor()

    schemas = get_schemas(cur, args.schema)
    if not schemas:
        print('No schemas found.')
        cur.close()
        conn.close()
        return

    print(f'Schemas: {", ".join(schemas)}')
    print(f'Model: {model}')
    print(f'Batch size: {batch_size}')
    print()

    # -----------------------------------------------------------------------
    # Collect words to process per schema
    # -----------------------------------------------------------------------
    total_processed = 0
    total_skipped = 0
    total_errors = 0
    total_overridden = 0

    for schema in schemas:
        # Check if words table has phonics columns
        cur.execute("""
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = %s AND table_name = 'words' AND column_name = 'phonics_data'
        """, (schema,))
        if not cur.fetchone():
            print(f'[{schema}] phonics_data column does not exist. Run migrate_phonics.py first.')
            continue

        # Count total words
        cur.execute(f'SELECT COUNT(*) FROM {schema}.words')
        schema_total = cur.fetchone()[0]
        print(f'[{schema}] {schema_total} total words in database.')

        # Build query
        conditions = []
        params = []

        if args.resume or not args.overwrite:
            # Skip words that already have phonics_data
            cur.execute(
                f'SELECT COUNT(*) FROM {schema}.words WHERE phonics_data IS NOT NULL'
            )
            existing = cur.fetchone()[0]
            if existing > 0 and not args.overwrite:
                print(f'[{schema}] {existing} words already have phonics_data (will skip).')

        # Query words
        query = f'SELECT id, english FROM {schema}.words'
        if args.resume:
            query += ' WHERE phonics_data IS NULL'
        elif args.overwrite:
            # Overwrite non-reviewed words
            query += ' WHERE (reviewed IS NULL OR reviewed = FALSE)'

        query += ' ORDER BY id'

        cur.execute(query)
        all_words = cur.fetchall()

        # Apply limit
        if args.limit and args.limit > 0:
            all_words = all_words[:args.limit]

        # Filter out manual overrides
        words_to_process = []
        skipped_overrides = 0
        for word_id, english in all_words:
            if english.lower().strip() in override_words:
                skipped_overrides += 1
                continue
            words_to_process.append((word_id, english))

        if skipped_overrides:
            print(f'[{schema}] {skipped_overrides} word(s) skipped (manual overrides).')

        total_words = len(words_to_process)
        if total_words == 0:
            print(f'[{schema}] No words to process.\n')
            continue

        print(f'[{schema}] {total_words} words to generate.\n')

        if args.dry_run:
            batches = (total_words + batch_size - 1) // batch_size
            print(f'[{schema}] Would process in {batches} batch(es).')
            for i in range(min(3, batches)):
                start = i * batch_size
                end = min(start + batch_size, total_words)
                batch_words = [w[1] for w in words_to_process[start:end]]
                print(f'  Batch {i+1}: {len(batch_words)} words — {", ".join(batch_words[:5])}...')
            continue

        # -------------------------------------------------------------------
        # Process batches
        # -------------------------------------------------------------------
        schema_processed = 0
        schema_skipped = 0
        schema_errors = 0

        for batch_start in range(0, total_words, batch_size):
            batch_end = min(batch_start + batch_size, total_words)
            batch = words_to_process[batch_start:batch_end]
            batch_words_en = [w[1] for w in batch]
            batch_word_ids = {w[1].lower().strip(): w[0] for w in batch}

            preview = ', '.join(batch_words_en[:3])
            print(
                f'[{schema}] Batch {batch_start//batch_size + 1}: '
                f'words {batch_start+1}-{batch_end}/{total_words} '
                f'({preview}...)',
                end=' ', flush=True
            )

            try:
                results = call_claude_batch(batch_words_en, model)
            except Exception as e:
                print(f'\n  ERROR calling Claude: {e}')
                print(f'  Saving progress and continuing...')
                schema_errors += len(batch)
                total_errors += len(batch)
                conn.commit()
                # Wait a moment before next batch on error
                time.sleep(2)
                continue

            # Validate and write
            results_by_word = {}
            for entry in results:
                w = entry.get('word', '').lower().strip()
                results_by_word[w] = entry

            batch_ok = 0
            for english, word_id in [(w[1], w[0]) for w in batch]:
                key = english.lower().strip()
                if key not in results_by_word:
                    print(f'\n  WARNING: Claude did not return data for "{english}"')
                    schema_errors += 1
                    total_errors += 1
                    continue

                entry = results_by_word[key]
                errors = validate_phonics_entry(entry, english)
                if errors:
                    print(f'\n  VALIDATION FAILED for "{english}":')
                    for err in errors:
                        print(f'    - {err}')
                    schema_errors += 1
                    total_errors += 1
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
                        word_id,
                    )
                )
                batch_ok += 1

            conn.commit()
            schema_processed += batch_ok
            total_processed += batch_ok
            print(f'OK ({batch_ok}/{len(batch)} committed)')

            # Rate limiting — small delay between batches
            time.sleep(1)

        print(
            f'\n[{schema}] Done: {schema_processed} generated, '
            f'{schema_skipped} skipped, {schema_errors} errors.\n'
        )

    cur.close()
    conn.close()

    # -----------------------------------------------------------------------
    # Summary
    # -----------------------------------------------------------------------
    print('=' * 60)
    print('GENERATION COMPLETE')
    print('=' * 60)
    print(f'  Generated: {total_processed}')
    print(f'  Skipped:   {total_skipped}')
    print(f'  Overrides: {total_overridden}')
    print(f'  Errors:    {total_errors}')
    print()

    if total_processed > 0:
        print('Next step: run review tool to verify quality.')
        print('  python scripts/review_phonics.py --count 20')


if __name__ == '__main__':
    main()
