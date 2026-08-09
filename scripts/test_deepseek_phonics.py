"""Quick test: verify DeepSeek API can generate valid phonics annotations."""
import os, sys, json, re
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv()

import anthropic

API_KEY = os.getenv('ANTHROPIC_AUTH_TOKEN', '') or os.getenv('ANTHROPIC_API_KEY', '')
BASE_URL = os.getenv('ANTHROPIC_BASE_URL', None)
MODEL = os.getenv('ANTHROPIC_MODEL', '') or 'claude-sonnet-5'

client_kwargs = {'api_key': API_KEY}
if BASE_URL:
    client_kwargs['base_url'] = BASE_URL
client = anthropic.Anthropic(**client_kwargs)

SYSTEM_PROMPT = """You are an English phonics teacher. Annotate words with phonics data.

## ABSOLUTE RULES
- sh->SH, ch->CH, th->TH, ck->K, ng->NG, ph->F, qu->K W (ONE segment, never split)
- Silent letters ALWAYS their OWN segment with "silent":true:
  kn-: k(silent), n; wr-: w(silent), r; -mb: m, b(silent); word-final silent e: e(silent)
- Syllable text is a SUBSTRING of the original word
- Each segment has: "text", "silent" (bool), "rule" (kebab-case identifier)
- Segments are nested inside syllables, NOT at top level

Return ONLY a JSON array. Format:
[{
  "word": "patience",
  "ipa": "/'peI.S@ns/",
  "arpabet": "P EY1 SH AH0 N S",
  "syllables": [{
    "text": "pa",
    "stress": 1,
    "segments": [
      {"text": "p", "silent": false, "rule": "consonant-p"},
      {"text": "a", "silent": false, "rule": "vowel-a-long"}
    ]
  }, {
    "text": "tience",
    "stress": 0,
    "segments": [
      {"text": "t", "silent": false, "rule": "consonant-t"},
      {"text": "ie", "silent": false, "rule": "ie"},
      {"text": "n", "silent": false, "rule": "consonant-n"},
      {"text": "c", "silent": false, "rule": "consonant-c"},
      {"text": "e", "silent": true, "rule": "silent-e"}
    ]
  }]
}]"""

test_words = ['patience', 'confident', 'challenge']

print(f'Testing phonics generation for {len(test_words)} words...')
print(f'Endpoint: {BASE_URL}')
print(f'Model: {MODEL}')
print()

try:
    message = client.messages.create(
        model=MODEL,
        max_tokens=4096,
        temperature=0.3,
        thinking={'type': 'disabled'},
        system=SYSTEM_PROMPT,
        messages=[{'role': 'user', 'content': f'Annotate: {json.dumps(test_words)}'}],
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

    try:
        result = json.loads(text)
    except json.JSONDecodeError:
        match = re.search(r'\[.*\]', text, re.DOTALL)
        if match:
            result = json.loads(match.group())
        else:
            raise RuntimeError(f'Failed to parse JSON. Raw: {text[:500]}')

    if not isinstance(result, list):
        raise RuntimeError(f'Expected JSON array, got {type(result).__name__}')

    print(f'SUCCESS! Got {len(result)} word(s) back:')
    all_valid = True
    for entry in result:
        w = entry.get('word', '?')
        ipa = entry.get('ipa', '?')
        syls = entry.get('syllables', [])
        syl_count = len(syls)
        seg_count = sum(len(s.get('segments', [])) for s in syls)
        # Use ASCII-safe rendering to avoid Windows console encoding issues
        ipa_ascii = ipa.encode('ascii', errors='replace').decode('ascii')
        print(f'  {w}: IPA={ipa_ascii}, syllables={syl_count}, segments={seg_count}')

        # Validate structure
        for si, syl in enumerate(syls):
            segs = syl.get('segments', [])
            joined = ''.join(s.get('text', '') for s in segs)
            if joined != syl.get('text', ''):
                print(f'    WARNING: syllable[{si}] segments mismatch: "{joined}" vs "{syl.get("text", "")}"')
                all_valid = False
            for sgi, seg in enumerate(segs):
                for field in ['text', 'silent', 'rule']:
                    if field not in seg:
                        print(f'    WARNING: missing field "{field}" in syllable[{si}].segment[{sgi}]')
                        all_valid = False

        # All syllable texts join to word
        full = ''.join(s.get('text', '') for s in syls)
        if full.lower() != w.lower():
            print(f'    WARNING: syllables reconstruct to "{full}" vs expected "{w}"')
            all_valid = False

    print()
    if all_valid:
        print('ALL VALIDATIONS PASSED.')
        print()
        print('>>> Ready to run full generation for senior_compulsory_1_beijing.')
    else:
        print('SOME VALIDATIONS FAILED — check warnings above.')

except Exception as e:
    print(f'FAILED: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
