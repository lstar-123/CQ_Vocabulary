"""Add error_count and error_words columns to group_memory_history table."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from backend import create_app
from backend.models import db

app = create_app()

with app.app_context():
    with db.engine.connect() as conn:
        # Check if columns already exist
        result = conn.execute(db.text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'group_memory_history'
            AND column_name IN ('error_count', 'error_words')
        """))
        existing = {row[0] for row in result}

        if 'error_count' not in existing:
            conn.execute(db.text(
                "ALTER TABLE group_memory_history ADD COLUMN error_count INTEGER NOT NULL DEFAULT 0"
            ))
            print('Added column: error_count')
        else:
            print('Column already exists: error_count')

        if 'error_words' not in existing:
            conn.execute(db.text(
                "ALTER TABLE group_memory_history ADD COLUMN error_words JSON"
            ))
            print('Added column: error_words')
        else:
            print('Column already exists: error_words')

        conn.commit()
    print('Migration complete.')
