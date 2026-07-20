"""Test if disabling thinking allows larger batches."""
import os, json, sys, re
from dotenv import load_dotenv; load_dotenv()
sys.path.insert(0, 'scripts')
import generate_phonics_dataset as g
import anthropic

key = os.getenv('ANTHROPIC_AUTH_TOKEN','')
url = os.getenv('ANTHROPIC_BASE_URL','')
model = os.getenv('ANTHROPIC_MODEL','')

kwargs = {'api_key': key}
if url: kwargs['base_url'] = url
c = anthropic.Anthropic(**kwargs)

# Test with 15 words, thinking disabled
words = [
    'video','tennis','surf','famous','building','trip','thousand',
    'museum','fresh','ago','computer','newspaper','supermarket',
    'forest','plane'
]
print(f'Testing {len(words)} words with thinking=disabled')

try:
    msg = c.messages.create(
        model=model, max_tokens=8192, temperature=0.3,
        thinking={"type": "disabled"},
        system=g.SYSTEM_PROMPT,
        messages=[{'role':'user','content': g.build_batch_prompt(words)}],
    )
    text = ''
    for b in msg.content:
        if hasattr(b, 'text'):
            text += b.text

    print(f'TextBlocks text: {len(text)} chars')
    for i, b in enumerate(msg.content):
        t = type(b).__name__
        thinking = getattr(b, 'thinking', '')
        txt = getattr(b, 'text', '')
        print(f'  Block {i}: {t} (thinking={len(thinking)}ch, text={len(txt)}ch)')

    if len(text) > 50:
        t = text.strip()
        if t.startswith('```'):
            lines = t.split('\n')
            lines = lines[1:] if lines[0].startswith('```') else lines
            lines = lines[:-1] if lines and lines[-1].startswith('```') else lines
            t = '\n'.join(lines)
        try:
            data = json.loads(t)
        except json.JSONDecodeError:
            m = re.search(r'\[.*\]', t, re.DOTALL)
            if m: data = json.loads(m.group())
            else:
                print(f'Parse error: {repr(t[:200])}')
                sys.exit(1)
        ok = sum(1 for e in data if not g.validate_phonics_entry(e, e.get('word','')))
        print(f'Parsed: {ok}/{len(data)} words OK')
    else:
        print('EMPTY response')

except Exception as e:
    print(f'Error with thinking=disabled: {e}')
    print('Trying without thinking param...')
