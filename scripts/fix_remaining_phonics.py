"""Insert manually-crafted phonics data for words DeepSeek consistently fails on."""
import os, sys, json
from datetime import datetime, timezone
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv()
import psycopg2

url = os.getenv('WORDS_DATABASE_URL')
s = url.replace('postgresql://', '')
p = s.split('@')
up = p[0].split(':')
hp = p[1].split('/')[0].split(':')
dbn = p[1].split('/')[1] if '/' in p[1] else 'vocab_quiz_words'

conn = psycopg2.connect(
    host=hp[0], port=int(hp[1]) if len(hp) > 1 else 5432,
    user=up[0], password=up[1] if len(up) > 1 else '',
    dbname=dbn
)
cur = conn.cursor()

MANUAL_PHONICS = {
    'tough': {
        'word': 'tough', 'ipa': '/tʌf/', 'arpabet': 'T AH1 F',
        'syllables': [{'text': 'tough', 'stress': 1, 'segments': [
            {'text': 't', 'silent': False, 'rule': 'consonant-t'},
            {'text': 'ough', 'silent': False, 'rule': 'ough-f'}
        ]}]
    },
    'voluntary': {
        'word': 'voluntary', 'ipa': '/ˈvɒləntəri/', 'arpabet': 'V AA1 L AH0 N T EH0 R IY0',
        'syllables': [
            {'text': 'vol', 'stress': 1, 'segments': [
                {'text': 'v', 'silent': False, 'rule': 'consonant-v'},
                {'text': 'o', 'silent': False, 'rule': 'vowel-o-short'},
                {'text': 'l', 'silent': False, 'rule': 'consonant-l'}
            ]},
            {'text': 'un', 'stress': 0, 'segments': [
                {'text': 'u', 'silent': False, 'rule': 'schwa'},
                {'text': 'n', 'silent': False, 'rule': 'consonant-n'}
            ]},
            {'text': 'ta', 'stress': 0, 'segments': [
                {'text': 't', 'silent': False, 'rule': 'consonant-t'},
                {'text': 'a', 'silent': False, 'rule': 'schwa'}
            ]},
            {'text': 'ry', 'stress': 0, 'segments': [
                {'text': 'r', 'silent': False, 'rule': 'consonant-r'},
                {'text': 'y', 'silent': False, 'rule': 'vowel-y'}
            ]}
        ]
    },
    'tend to do sth': {
        'word': 'tend to do sth', 'ipa': '/tɛnd tə duː ˈsʌmθɪŋ/',
        'arpabet': 'T EH1 N D T AH0 D UW1 S AH1 M TH IH0 NG',
        'syllables': [
            {'text': 'tend', 'stress': 1, 'segments': [
                {'text': 't', 'silent': False, 'rule': 'consonant-t'},
                {'text': 'e', 'silent': False, 'rule': 'vowel-e-short'},
                {'text': 'n', 'silent': False, 'rule': 'consonant-n'},
                {'text': 'd', 'silent': False, 'rule': 'consonant-d'}
            ]},
            {'text': 'to', 'stress': 0, 'segments': [
                {'text': 't', 'silent': False, 'rule': 'consonant-t'},
                {'text': 'o', 'silent': False, 'rule': 'schwa'}
            ]},
            {'text': 'do', 'stress': 1, 'segments': [
                {'text': 'd', 'silent': False, 'rule': 'consonant-d'},
                {'text': 'o', 'silent': False, 'rule': 'vowel-oo-long'}
            ]},
            {'text': 'sth', 'stress': 1, 'segments': [
                {'text': 's', 'silent': False, 'rule': 'consonant-s'},
                {'text': 't', 'silent': False, 'rule': 'consonant-t'},
                {'text': 'h', 'silent': False, 'rule': 'consonant-h'}
            ]}
        ]
    },
    'muddy': {
        'word': 'muddy', 'ipa': '/ˈmʌdi/', 'arpabet': 'M AH1 D IY0',
        'syllables': [
            {'text': 'mud', 'stress': 1, 'segments': [
                {'text': 'm', 'silent': False, 'rule': 'consonant-m'},
                {'text': 'u', 'silent': False, 'rule': 'vowel-u-short'},
                {'text': 'd', 'silent': False, 'rule': 'consonant-d'}
            ]},
            {'text': 'dy', 'stress': 0, 'segments': [
                {'text': 'd', 'silent': False, 'rule': 'consonant-d-doubled'},
                {'text': 'y', 'silent': False, 'rule': 'vowel-y'}
            ]}
        ]
    },
    'adapt to sth': {
        'word': 'adapt to sth', 'ipa': '/əˈdæpt tə ˈsʌmθɪŋ/',
        'arpabet': 'AH0 D AE1 P T T AH0 S AH1 M TH IH0 NG',
        'syllables': [
            {'text': 'a', 'stress': 0, 'segments': [
                {'text': 'a', 'silent': False, 'rule': 'schwa'}
            ]},
            {'text': 'dapt', 'stress': 1, 'segments': [
                {'text': 'd', 'silent': False, 'rule': 'consonant-d'},
                {'text': 'a', 'silent': False, 'rule': 'vowel-a-short'},
                {'text': 'p', 'silent': False, 'rule': 'consonant-p'},
                {'text': 't', 'silent': False, 'rule': 'consonant-t'}
            ]},
            {'text': 'to', 'stress': 0, 'segments': [
                {'text': 't', 'silent': False, 'rule': 'consonant-t'},
                {'text': 'o', 'silent': False, 'rule': 'schwa'}
            ]},
            {'text': 'sth', 'stress': 1, 'segments': [
                {'text': 's', 'silent': False, 'rule': 'consonant-s'},
                {'text': 't', 'silent': False, 'rule': 'consonant-t'},
                {'text': 'h', 'silent': False, 'rule': 'consonant-h'}
            ]}
        ]
    },
    'look forward to (doing) sth': {
        'word': 'look forward to (doing) sth',
        'ipa': '/lʊk ˈfɔːwəd tə ˈduːɪŋ ˈsʌmθɪŋ/',
        'arpabet': 'L UH1 K F AO1 R W ER0 D T AH0 D UW1 IH0 NG S AH1 M TH IH0 NG',
        'syllables': [
            {'text': 'look', 'stress': 1, 'segments': [
                {'text': 'l', 'silent': False, 'rule': 'consonant-l'},
                {'text': 'oo', 'silent': False, 'rule': 'oo-short'},
                {'text': 'k', 'silent': False, 'rule': 'consonant-k'}
            ]},
            {'text': 'for', 'stress': 1, 'segments': [
                {'text': 'f', 'silent': False, 'rule': 'consonant-f'},
                {'text': 'or', 'silent': False, 'rule': 'or'}
            ]},
            {'text': 'ward', 'stress': 0, 'segments': [
                {'text': 'w', 'silent': False, 'rule': 'consonant-w'},
                {'text': 'ar', 'silent': False, 'rule': 'ar'},
                {'text': 'd', 'silent': False, 'rule': 'consonant-d'}
            ]},
            {'text': 'to', 'stress': 0, 'segments': [
                {'text': 't', 'silent': False, 'rule': 'consonant-t'},
                {'text': 'o', 'silent': False, 'rule': 'schwa'}
            ]},
            {'text': 'doing', 'stress': 1, 'segments': [
                {'text': 'd', 'silent': False, 'rule': 'consonant-d'},
                {'text': 'oi', 'silent': False, 'rule': 'oi'},
                {'text': 'ng', 'silent': False, 'rule': 'ng'}
            ]},
            {'text': 'sth', 'stress': 1, 'segments': [
                {'text': 's', 'silent': False, 'rule': 'consonant-s'},
                {'text': 't', 'silent': False, 'rule': 'consonant-t'},
                {'text': 'h', 'silent': False, 'rule': 'consonant-h'}
            ]}
        ]
    },
    'scare': {
        'word': 'scare', 'ipa': '/skɛər/', 'arpabet': 'S K EH1 R',
        'syllables': [{'text': 'scare', 'stress': 1, 'segments': [
            {'text': 's', 'silent': False, 'rule': 'consonant-s'},
            {'text': 'c', 'silent': False, 'rule': 'consonant-c'},
            {'text': 'are', 'silent': False, 'rule': 'are'},
            {'text': 'e', 'silent': True, 'rule': 'silent-e'}
        ]}]
    },
    'scare sb / sth away': {
        'word': 'scare sb / sth away',
        'ipa': '/skɛər ˈsʌmθɪŋ əˈweɪ/',
        'arpabet': 'S K EH1 R S AH1 M TH IH0 NG AH0 W EY1',
        'syllables': [
            {'text': 'scare', 'stress': 1, 'segments': [
                {'text': 's', 'silent': False, 'rule': 'consonant-s'},
                {'text': 'c', 'silent': False, 'rule': 'consonant-c'},
                {'text': 'are', 'silent': False, 'rule': 'are'},
                {'text': 'e', 'silent': True, 'rule': 'silent-e'}
            ]},
            {'text': 'sb', 'stress': 1, 'segments': [
                {'text': 's', 'silent': False, 'rule': 'consonant-s'},
                {'text': 'b', 'silent': False, 'rule': 'consonant-b'}
            ]},
            {'text': 'sth', 'stress': 1, 'segments': [
                {'text': 's', 'silent': False, 'rule': 'consonant-s'},
                {'text': 't', 'silent': False, 'rule': 'consonant-t'},
                {'text': 'h', 'silent': False, 'rule': 'consonant-h'}
            ]},
            {'text': 'away', 'stress': 0, 'segments': [
                {'text': 'a', 'silent': False, 'rule': 'schwa'},
                {'text': 'w', 'silent': False, 'rule': 'consonant-w'},
                {'text': 'ay', 'silent': False, 'rule': 'ay'}
            ]}
        ]
    },
}

inserted = 0
for word_key, data in MANUAL_PHONICS.items():
    # Validate
    syl_texts = ''.join(s['text'] for s in data['syllables'])
    word_compact = data['word'].replace(' ', '').replace('-', '').replace('.', '').replace('/', '')
    syl_compact = syl_texts.replace(' ', '').replace('-', '').replace('.', '').replace('/', '')

    if syl_compact != word_compact:
        print(f'SKIP "{word_key}": syllables join to "{syl_compact}" != "{word_compact}"')
        continue

    ok = True
    for si, syl in enumerate(data['syllables']):
        seg_join = ''.join(seg['text'] for seg in syl['segments'])
        if seg_join != syl['text']:
            print(f'SKIP "{word_key}" syl[{si}]: "{seg_join}" != "{syl["text"]}"')
            ok = False
    if not ok:
        continue

    cur.execute(
        '''UPDATE senior_compulsory_1_beijing.words
           SET phonics_data = %s, phonics_version = 1,
               generated_by = %s, generated_at = %s, reviewed = TRUE
           WHERE english = %s AND phonics_data IS NULL''',
        (json.dumps(data), 'manual:deepseek-fallback', datetime.now(timezone.utc), word_key)
    )
    if cur.rowcount > 0:
        print(f'OK: "{word_key}"')
        inserted += 1
    else:
        print(f'SKIP "{word_key}": not found or already has phonics_data')

conn.commit()
print(f'\nInserted {inserted} manual phonics entries.')

# Final count
cur.execute('SELECT COUNT(*) FROM senior_compulsory_1_beijing.words WHERE phonics_data IS NULL')
remaining = cur.fetchone()[0]
print(f'Remaining without phonics: {remaining}')

cur.close()
conn.close()
