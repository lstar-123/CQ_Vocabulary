"""Youdao TTS proxy — protects API keys server-side."""
import hashlib
import random
import requests
from flask import Blueprint, request, Response

from ..decorators import api_login_required

tts_bp = Blueprint('tts', __name__)

YOUDAO_TTS_URL = 'https://openapi.youdao.com/ttsapi'


def _load_credentials():
    import os
    return os.getenv('YOUDAO_APP_KEY', ''), os.getenv('YOUDAO_APP_SECRET', '')


@tts_bp.route('')
@api_login_required
def speak():
    text = (request.args.get('text') or '').strip()
    if not text:
        return Response('missing text', status=400)

    lang = request.args.get('lang', 'en')
    app_key, app_secret = _load_credentials()

    if not app_key or not app_secret:
        return Response('tts not configured', status=500)

    salt = str(random.randint(1, 65536))
    sign_str = app_key + text + salt + app_secret
    sign = hashlib.md5(sign_str.encode('utf-8')).hexdigest()

    params = {
        'q': text,
        'appKey': app_key,
        'salt': salt,
        'sign': sign,
        'langType': lang,
        'format': 'mp3',
    }

    try:
        resp = requests.get(YOUDAO_TTS_URL, params=params, timeout=5)
        if resp.status_code != 200:
            return Response(f'tts upstream error {resp.status_code}', status=502)
        content_type = resp.headers.get('Content-Type', 'audio/mp3')
        return Response(resp.content, content_type=content_type)
    except requests.RequestException as e:
        return Response(f'tts request failed: {e}', status=502)
