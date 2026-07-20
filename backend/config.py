import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        'postgresql://postgres:postgres@localhost:5432/vocab_quiz'
    )
    SQLALCHEMY_BINDS = {
        'words': os.getenv(
            'WORDS_DATABASE_URL',
            'postgresql://postgres:postgres@localhost:5432/vocab_quiz_words'
        ),
    }
    SQLALCHEMY_TRACK_MODIFICATIONS = False
