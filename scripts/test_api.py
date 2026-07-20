"""Debug test: verify Claude API response parsing."""
import os, json, sys
from dotenv import load_dotenv; load_dotenv()
sys.path.insert(0, 'scripts')
import anthropic
import generate_phonics_dataset as g

key = os.getenv('ANTHROPIC_AUTH_TOKEN','')
url = os.getenv('ANTHROPIC_BASE_URL','')
model = os.getenv('ANTHROPIC_MODEL','')

kwargs = {'api_key': key}
if url: kwargs['base_url'] = url
c = anthropic.Anthropic(**kwargs)

msg = c.messages.create(
    model=model, max_tokens=2048, temperature=0.3,
    system=g.SYSTEM_PROMPT,
    messages=[{'role':'user','content': g.build_batch_prompt(['cat','dog','bus'])}],
)

text = ''
for block in msg.content:
    if hasattr(block, 'text'):
        text += block.text

# Save raw response for debugging
os.makedirs('data', exist_ok=True)
with open('data/debug_response.txt', 'w', encoding='utf-8') as f:
    f.write(text)
print(f'Response: {len(text)} chars written to data/debug_response.txt')

# Try parsing like the generator does
text = text.strip()
if text.startswith('```'):
    lines = text.split('\n')
    if lines[0].startswith('```'):
        lines = lines[1:]
    if lines and lines[-1].startswith('```'):
        lines = lines[:-1]
    text = '\n'.join(lines)

try:
    data = json.loads(text)
    print(f'Parsed OK: {len(data)} words')
    for entry in data:
        errors = g.validate_phonics_entry(entry, entry['word'])
        status = 'OK' if not errors else f'{len(errors)} errors: {errors[0]}'
        print(f'  {entry["word"]}: IPA={entry["ipa"]}, segs={len(entry["segments"])}, {status}')
except json.JSONDecodeError as e:
    print(f'JSON parse error: {e}')
    print(f'First 400 chars: {repr(text[:400])}')
except Exception as e:
    print(f'Error: {e}')
