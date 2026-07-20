"""Phonics data access layer — pure database pass-through, no runtime analysis.

All phonics annotation is pre-generated offline. This module only reads
stored data and returns it directly. Manual overrides take priority.

v2 schema (segments nested inside syllables):
{
    "word": "knowledge",
    "ipa": "/ˈnɒlɪdʒ/",
    "arpabet": "N AA1 L AH0 JH",
    "syllables": [{
        "text": "know",
        "stress": 1,
        "segments": [
            {"text": "k", "silent": true,  "rule": "silent-k"},
            {"text": "n", "silent": false, "rule": "consonant-n"},
            {"text": "o", "silent": false, "rule": "vowel-o"},
            {"text": "w", "silent": true,  "rule": "silent-w"}
        ]
    }, {
        "text": "ledge",
        "stress": 0,
        "segments": [
            {"text": "l",  "silent": false, "rule": "consonant-l"},
            {"text": "e",  "silent": false, "rule": "schwa"},
            {"text": "d",  "silent": true,  "rule": "silent-d-in-dge"},
            {"text": "ge", "silent": false, "rule": "dge"}
        ]
    }]
}
"""
import json
import os


# ---------------------------------------------------------------------------
# Manual overrides — teacher-reviewed data that always takes priority
# ---------------------------------------------------------------------------
_manual_overrides = None
_manual_overrides_path = os.path.join(
    os.path.dirname(__file__), '..', 'data', 'manual_overrides.json'
)


def _load_manual_overrides():
    """Load manual_overrides.json once per process."""
    global _manual_overrides
    if _manual_overrides is not None:
        return _manual_overrides
    try:
        with open(_manual_overrides_path, 'r', encoding='utf-8') as f:
            _manual_overrides = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        _manual_overrides = {}
    return _manual_overrides


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def get_phonics_data(word_model_instance):
    """Return phonics_data from a Word model instance, or None.

    Manual overrides in data/manual_overrides.json always take priority
    over database-stored data.
    """
    word_lower = word_model_instance.english.lower().strip()

    # 1. Check manual overrides first (always wins)
    overrides = _load_manual_overrides()
    if word_lower in overrides:
        entry = overrides[word_lower]
        if entry.get('reviewed') and 'phonics_data' in entry:
            return entry['phonics_data']

    # 2. Check database
    if word_model_instance.phonics_data is None:
        return None

    return word_model_instance.phonics_data


def adapt_phonics_for_frontend(phonics_data):
    """Pass phonics_data directly to frontend — no transformation needed.

    v2 format: segments are nested inside syllables. Frontend walks
    syllables[].segments[] directly.
    """
    return phonics_data
