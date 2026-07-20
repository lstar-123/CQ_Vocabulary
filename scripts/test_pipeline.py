"""Quick test: generate 5 words and verify the full pipeline."""
import os, json, sys
from dotenv import load_dotenv; load_dotenv()
sys.path.insert(0, 'scripts')
import anthropic
import generate_phonics_dataset as g

key = os.getenv('ANTHROPIC_AUTH_TOKEN','')
url = os.getenv('ANTHROPIC_BASE_URL','')
model = os.getenv('ANTHROPIC_MODEL','')

words = ['video', 'tennis', 'surf', 'sports day', 'last']
print(f'Testing with {len(words)} words: {words}')
print(f'Model: {model}')
print(f'Max tokens: 8192')

kwargs = {'api_key': key}
if url: kwargs['base_url'] = url
c = anthropic.Anthropic(**kwargs)

msg = c.messages.create(
    model=model, max_tokens=8192, temperature=0.3,
    system=g.SYSTEM_PROMPT,
    messages=[{'role':'user','content': g.build_batch_prompt(words)}],
)

text = ''
for block in msg.content:
    if hasattr(block, 'text'):
        text += block.text

print(f'Response: {len(text)} chars')

# Parse
import re
orig = text
text = text.strip()
if text.startswith('```'):
    lines = text.split('\n')
    if lines[0].startswith('```'): lines = lines[1:]
    if lines and lines[-1].startswith('```'): lines = lines[:-1]
    text = '\n'.join(lines)

try:
    data = json.loads(text)
except json.JSONDecodeError:
    m = re.search(r'\[.*\]', text, re.DOTALL)
    if m:
        data = json.loads(m.group())
    else:
        print(f'FAILED to parse. Raw: {repr(orig[:300])}')
        sys.exit(1)

print(f'Parsed: {len(data)} words')
for entry in data:
    errors = g.validate_phonics_entry(entry, entry['word'])
    status = 'OK' if not errors else '; '.join(errors[:3])
    print(f'  {entry["word"]}: {len(entry["segments"])} segs, {entry["ipa"]} — {status}')

if hasattr(msg, 'usage'):
    print(f'Tokens: {msg.usage.input_tokens} in, {msg.usage.output_tokens} out')
