"""Write v2 format data for 6 remaining punctuation-heavy words."""
import psycopg2, os, json; from dotenv import load_dotenv; load_dotenv()
from datetime import datetime, timezone

with open('data/manual_overrides.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# v2 format entries
entries = {
    'p.m.': {
        'word': 'p.m.', 'ipa': '/piːɛm/', 'arpabet': 'P IY1 EH1 M',
        'syllables': [
            {'text': 'p', 'stress': 1, 'segments': [{'text': 'p', 'silent': False, 'rule': 'consonant-p'}]},
            {'text': 'm', 'stress': 1, 'segments': [{'text': 'm', 'silent': False, 'rule': 'consonant-m'}]}
        ]
    },
    'a.m.': {
        'word': 'a.m.', 'ipa': '/eɪɛm/', 'arpabet': 'EY1 EH1 M',
        'syllables': [
            {'text': 'a', 'stress': 1, 'segments': [{'text': 'a', 'silent': False, 'rule': 'vowel-a'}]},
            {'text': 'm', 'stress': 1, 'segments': [{'text': 'm', 'silent': False, 'rule': 'consonant-m'}]}
        ]
    },
    'leave ... alone': {
        'word': 'leave ... alone', 'ipa': '/liːv əˈloʊn/', 'arpabet': 'L IY1 V AH0 L OW1 N',
        'syllables': [
            {'text': 'leave', 'stress': 1, 'segments': [
                {'text': 'l', 'silent': False, 'rule': 'consonant-l'},
                {'text': 'ea', 'silent': False, 'rule': 'ea'},
                {'text': 'v', 'silent': False, 'rule': 'consonant-v'},
                {'text': 'e', 'silent': True, 'rule': 'magic-e'}
            ]},
            {'text': 'a', 'stress': 0, 'segments': [
                {'text': 'a', 'silent': False, 'rule': 'schwa'}
            ]},
            {'text': 'lone', 'stress': 1, 'segments': [
                {'text': 'l', 'silent': False, 'rule': 'consonant-l'},
                {'text': 'o', 'silent': False, 'rule': 'vowel-o'},
                {'text': 'n', 'silent': False, 'rule': 'consonant-n'},
                {'text': 'e', 'silent': True, 'rule': 'magic-e'}
            ]}
        ]
    },
    'extra-curricular': {
        'word': 'extra-curricular', 'ipa': '/ˌɛkstrəkəˈrɪkjələr/',
        'arpabet': 'EH2 K S T R AH0 K AH0 R IH1 K Y AH0 L ER0',
        'syllables': [
            {'text': 'ex', 'stress': 2, 'segments': [
                {'text': 'e', 'silent': False, 'rule': 'vowel-e'},
                {'text': 'x', 'silent': False, 'rule': 'consonant-x'}
            ]},
            {'text': 'tra', 'stress': 0, 'segments': [
                {'text': 't', 'silent': False, 'rule': 'consonant-t'},
                {'text': 'r', 'silent': False, 'rule': 'consonant-r'},
                {'text': 'a', 'silent': False, 'rule': 'schwa'}
            ]},
            {'text': 'cur', 'stress': 0, 'segments': [
                {'text': 'c', 'silent': False, 'rule': 'consonant-c'},
                {'text': 'ur', 'silent': False, 'rule': 'ur'}
            ]},
            {'text': 'ri', 'stress': 0, 'segments': [
                {'text': 'r', 'silent': False, 'rule': 'consonant-r'},
                {'text': 'i', 'silent': False, 'rule': 'vowel-i'}
            ]},
            {'text': 'cu', 'stress': 0, 'segments': [
                {'text': 'c', 'silent': False, 'rule': 'consonant-c'},
                {'text': 'u', 'silent': False, 'rule': 'vowel-u'}
            ]},
            {'text': 'lar', 'stress': 0, 'segments': [
                {'text': 'l', 'silent': False, 'rule': 'consonant-l'},
                {'text': 'ar', 'silent': False, 'rule': 'ar'}
            ]}
        ]
    },
    'push-up': {
        'word': 'push-up', 'ipa': '/ˈpʊʃʌp/', 'arpabet': 'P UH1 SH AH2 P',
        'syllables': [
            {'text': 'push', 'stress': 1, 'segments': [
                {'text': 'p', 'silent': False, 'rule': 'consonant-p'},
                {'text': 'u', 'silent': False, 'rule': 'vowel-u'},
                {'text': 'sh', 'silent': False, 'rule': 'sh'}
            ]},
            {'text': 'up', 'stress': 2, 'segments': [
                {'text': 'u', 'silent': False, 'rule': 'vowel-u'},
                {'text': 'p', 'silent': False, 'rule': 'consonant-p'}
            ]}
        ]
    },
    'cut ... out': {
        'word': 'cut ... out', 'ipa': '/kʌt aʊt/', 'arpabet': 'K AH1 T AW1 T',
        'syllables': [
            {'text': 'cut', 'stress': 1, 'segments': [
                {'text': 'c', 'silent': False, 'rule': 'consonant-c'},
                {'text': 'u', 'silent': False, 'rule': 'vowel-u'},
                {'text': 't', 'silent': False, 'rule': 'consonant-t'}
            ]},
            {'text': 'out', 'stress': 1, 'segments': [
                {'text': 'ou', 'silent': False, 'rule': 'ou'},
                {'text': 't', 'silent': False, 'rule': 'consonant-t'}
            ]}
        ]
    },
}

for key, pd in entries.items():
    data[key]['phonics_data'] = pd

with open('data/manual_overrides.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('Manual overrides updated')

# Sync to DB
db = os.getenv('WORDS_DATABASE_URL')
conn = psycopg2.connect(db)
cur = conn.cursor()
for word_key in entries:
    pd = entries[word_key]
    for s in ['grade6_vol1', 'senior_compulsory_1']:
        cur.execute('SELECT id FROM ' + s + '.words WHERE english = %s', (word_key,))
        row = cur.fetchone()
        if row:
            cur.execute(
                'UPDATE ' + s + '.words SET phonics_data = %s, phonics_version = 2,'
                ' generated_by = %s, generated_at = %s, reviewed = TRUE WHERE id = %s',
                (json.dumps(pd), 'manual_v2', datetime.now(timezone.utc), row[0]))
            conn.commit()
            print('OK ' + word_key + ' [' + s + ']')
            break

for s in ['grade6_vol1', 'senior_compulsory_1']:
    cur.execute('SELECT COUNT(*) FROM ' + s + '.words')
    t = cur.fetchone()[0]
    cur.execute('SELECT COUNT(*) FROM ' + s + '.words WHERE phonics_data IS NOT NULL')
    d = cur.fetchone()[0]
    print(s + ': ' + str(d) + '/' + str(t))

cur.close()
conn.close()
