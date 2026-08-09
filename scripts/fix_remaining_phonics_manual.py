"""Fix the 6 remaining words where the model consistently fails validation.
Manually crafted phonics data for words DeepSeek can't handle correctly.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
from datetime import datetime, timezone
from dotenv import load_dotenv

load_dotenv()

MANUAL_PHONICS = {
    "tough": {
        "word": "tough",
        "ipa": "/tʌf/",
        "arpabet": "T AH1 F",
        "syllables": [{
            "text": "tough",
            "stress": 1,
            "segments": [
                {"text": "t", "silent": False, "rule": "consonant-t"},
                {"text": "ough", "silent": False, "rule": "ough-f"}
            ]
        }]
    },
    "be responsible for": {
        "word": "be responsible for",
        "ipa": "/bi rɪˈspɒnsəbəl fɔːr/",
        "arpabet": "B IY0 R IH0 S P AA1 N S AH0 B AH0 L F AO1 R",
        "syllables": [
            {"text": "be", "stress": 0, "segments": [
                {"text": "b", "silent": False, "rule": "consonant-b"},
                {"text": "e", "silent": False, "rule": "vowel-e"}
            ]},
            {"text": "res", "stress": 1, "segments": [
                {"text": "r", "silent": False, "rule": "consonant-r"},
                {"text": "e", "silent": False, "rule": "vowel-e"},
                {"text": "s", "silent": False, "rule": "consonant-s"}
            ]},
            {"text": "pon", "stress": 0, "segments": [
                {"text": "p", "silent": False, "rule": "consonant-p"},
                {"text": "o", "silent": False, "rule": "vowel-o"},
                {"text": "n", "silent": False, "rule": "consonant-n"}
            ]},
            {"text": "si", "stress": 0, "segments": [
                {"text": "s", "silent": False, "rule": "consonant-s"},
                {"text": "i", "silent": False, "rule": "schwa"}
            ]},
            {"text": "ble", "stress": 0, "segments": [
                {"text": "b", "silent": False, "rule": "consonant-b"},
                {"text": "l", "silent": False, "rule": "consonant-l"},
                {"text": "e", "silent": True, "rule": "silent-e-in-ble"}
            ]},
            {"text": "for", "stress": 1, "segments": [
                {"text": "f", "silent": False, "rule": "consonant-f"},
                {"text": "or", "silent": False, "rule": "or"}
            ]}
        ]
    },
    "attractive": {
        "word": "attractive",
        "ipa": "/əˈtræktɪv/",
        "arpabet": "AH0 T R AE1 K T IH0 V",
        "syllables": [
            {"text": "a", "stress": 0, "segments": [
                {"text": "a", "silent": False, "rule": "schwa"}
            ]},
            {"text": "ttrac", "stress": 1, "segments": [
                {"text": "t", "silent": False, "rule": "consonant-t"},
                {"text": "t", "silent": True, "rule": "silent-double-t"},
                {"text": "r", "silent": False, "rule": "consonant-r"},
                {"text": "a", "silent": False, "rule": "vowel-a"},
                {"text": "c", "silent": False, "rule": "consonant-c"}
            ]},
            {"text": "tive", "stress": 0, "segments": [
                {"text": "t", "silent": False, "rule": "consonant-t"},
                {"text": "i", "silent": False, "rule": "vowel-i"},
                {"text": "v", "silent": False, "rule": "consonant-v"},
                {"text": "e", "silent": True, "rule": "silent-e"}
            ]}
        ]
    },
    "adapt to sth": {
        "word": "adapt to sth",
        "ipa": "/əˈdæpt tuː ˈsʌmθɪŋ/",
        "arpabet": "AH0 D AE1 P T T UW0 S AH1 M TH IH0 NG",
        "syllables": [
            {"text": "a", "stress": 0, "segments": [
                {"text": "a", "silent": False, "rule": "schwa"}
            ]},
            {"text": "dapt", "stress": 1, "segments": [
                {"text": "d", "silent": False, "rule": "consonant-d"},
                {"text": "a", "silent": False, "rule": "vowel-a"},
                {"text": "p", "silent": False, "rule": "consonant-p"},
                {"text": "t", "silent": False, "rule": "consonant-t"}
            ]},
            {"text": "to", "stress": 0, "segments": [
                {"text": "t", "silent": False, "rule": "consonant-t"},
                {"text": "o", "silent": False, "rule": "vowel-o"}
            ]},
            {"text": "sth", "stress": 1, "segments": [
                {"text": "s", "silent": False, "rule": "consonant-s"},
                {"text": "th", "silent": False, "rule": "th-voiceless"}
            ]}
        ]
    },
    "look forward to (doing) sth": {
        "word": "look forward to (doing) sth",
        "ipa": "/lʊk ˈfɔːrwərd tuː ˈduːɪŋ ˈsʌmθɪŋ/",
        "arpabet": "L UH1 K F AO1 R W ER0 D T UW0 D UW1 IH0 NG S AH1 M TH IH0 NG",
        "syllables": [
            {"text": "look", "stress": 1, "segments": [
                {"text": "l", "silent": False, "rule": "consonant-l"},
                {"text": "oo", "silent": False, "rule": "oo-uh"},
                {"text": "k", "silent": False, "rule": "consonant-k"}
            ]},
            {"text": "for", "stress": 1, "segments": [
                {"text": "f", "silent": False, "rule": "consonant-f"},
                {"text": "or", "silent": False, "rule": "or"}
            ]},
            {"text": "ward", "stress": 0, "segments": [
                {"text": "w", "silent": False, "rule": "consonant-w"},
                {"text": "ar", "silent": False, "rule": "ar"},
                {"text": "d", "silent": False, "rule": "consonant-d"}
            ]},
            {"text": "to", "stress": 0, "segments": [
                {"text": "t", "silent": False, "rule": "consonant-t"},
                {"text": "o", "silent": False, "rule": "vowel-o"}
            ]},
            {"text": "(doing)", "stress": 0, "segments": [
                {"text": "(", "silent": True, "rule": "punctuation-paren"},
                {"text": "d", "silent": False, "rule": "consonant-d"},
                {"text": "o", "silent": False, "rule": "vowel-o"},
                {"text": "ing", "silent": False, "rule": "ing"},
                {"text": ")", "silent": True, "rule": "punctuation-paren"}
            ]},
            {"text": "sth", "stress": 1, "segments": [
                {"text": "s", "silent": False, "rule": "consonant-s"},
                {"text": "t", "silent": False, "rule": "consonant-t"},
                {"text": "h", "silent": False, "rule": "consonant-h"}
            ]}
        ]
    },
    "scare": {
        "word": "scare",
        "ipa": "/skeər/",
        "arpabet": "S K EH1 R",
        "syllables": [{
            "text": "scare",
            "stress": 1,
            "segments": [
                {"text": "s", "silent": False, "rule": "consonant-s"},
                {"text": "c", "silent": False, "rule": "consonant-c"},
                {"text": "are", "silent": False, "rule": "are"}
            ]
        }]
    },
    "scare sb / sth away": {
        "word": "scare sb / sth away",
        "ipa": "/skeər ˈsʌmbədi ˈsʌmθɪŋ əˈweɪ/",
        "arpabet": "S K EH1 R S AH1 M B AH0 D IY0 S AH1 M TH IH0 NG AH0 W EY1",
        "syllables": [
            {"text": "scare", "stress": 1, "segments": [
                {"text": "s", "silent": False, "rule": "consonant-s"},
                {"text": "c", "silent": False, "rule": "consonant-c"},
                {"text": "are", "silent": False, "rule": "are"}
            ]},
            {"text": "sb", "stress": 1, "segments": [
                {"text": "s", "silent": False, "rule": "consonant-s"},
                {"text": "b", "silent": False, "rule": "consonant-b"}
            ]},
            {"text": "sth", "stress": 1, "segments": [
                {"text": "s", "silent": False, "rule": "consonant-s"},
                {"text": "t", "silent": False, "rule": "consonant-t"},
                {"text": "h", "silent": False, "rule": "consonant-h"}
            ]},
            {"text": "a", "stress": 0, "segments": [
                {"text": "a", "silent": False, "rule": "schwa"}
            ]},
            {"text": "way", "stress": 1, "segments": [
                {"text": "w", "silent": False, "rule": "consonant-w"},
                {"text": "ay", "silent": False, "rule": "ay"}
            ]}
        ]
    },
    "diet": {
        "word": "diet",
        "ipa": "/ˈdaɪət/",
        "arpabet": "D AY1 AH0 T",
        "syllables": [
            {"text": "di", "stress": 1, "segments": [
                {"text": "d", "silent": False, "rule": "consonant-d"},
                {"text": "i", "silent": False, "rule": "vowel-i-long"}
            ]},
            {"text": "et", "stress": 0, "segments": [
                {"text": "e", "silent": False, "rule": "schwa"},
                {"text": "t", "silent": False, "rule": "consonant-t"}
            ]}
        ]
    },
    "catch sb's eye": {
        "word": "catch sb's eye",
        "ipa": "/kætʃ ˈsʌmbədiz aɪ/",
        "arpabet": "K AE1 CH S AH1 M B AH0 D IY0 Z AY1",
        "syllables": [
            {"text": "catch", "stress": 1, "segments": [
                {"text": "c", "silent": False, "rule": "consonant-c"},
                {"text": "a", "silent": False, "rule": "vowel-a"},
                {"text": "tch", "silent": False, "rule": "tch"}
            ]},
            {"text": "sb", "stress": 1, "segments": [
                {"text": "s", "silent": False, "rule": "consonant-s"},
                {"text": "b", "silent": False, "rule": "consonant-b"}
            ]},
            {"text": "s", "stress": 0, "segments": [
                {"text": "s", "silent": False, "rule": "possessive-s"}
            ]},
            {"text": "eye", "stress": 1, "segments": [
                {"text": "eye", "silent": False, "rule": "eye"}
            ]}
        ]
    }
}


def validate(entry, expected_word):
    """Basic validation: check syllables reconstruct to the original word."""
    syllables = entry.get('syllables', [])
    all_text = ''.join(
        ''.join(s.get('text', '') for s in syl.get('segments', []))
        for syl in syllables
    )
    word_compact = expected_word.replace(' ', '').replace('-', '').replace('.', '').replace('/', '').replace("'", '')
    joined_compact = all_text.replace(' ', '').replace('-', '').replace('.', '').replace('/', '').replace("'", '')
    return joined_compact == word_compact


def main():
    db_url = os.getenv('WORDS_DATABASE_URL')
    if not db_url:
        print('ERROR: WORDS_DATABASE_URL not set', file=sys.stderr)
        sys.exit(1)

    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    schema = 'senior_compulsory_1_beijing'
    model = 'manual-fix'
    now = datetime.now(timezone.utc)

    fixed = 0
    for word, entry in MANUAL_PHONICS.items():
        if not validate(entry, word):
            print(f'WARNING: {word} fails validation, skipping!')
            continue

        cur.execute(
            f"UPDATE {schema}.words SET phonics_data = %s, phonics_version = 1, "
            f"generated_by = %s, generated_at = %s, reviewed = TRUE "
            f"WHERE LOWER(english) = %s AND phonics_data IS NULL",
            (json.dumps(entry), f'manual:{model}', now, word.lower())
        )
        if cur.rowcount > 0:
            print(f'  Fixed: {word}')
            fixed += 1
        else:
            print(f'  Not found or already has phonics: {word}')

    conn.commit()
    cur.close()
    conn.close()

    print(f'\nFixed {fixed} words.')


if __name__ == '__main__':
    main()
