"""Add total_rounds and duration_seconds columns to group_learning_progress table."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from backend import create_app
from backend.models import db

app = create_app()

with app.app_context():
    with db.engine.connect() as conn:
        result = conn.execute(db.text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'group_learning_progress'
            AND column_name IN ('total_rounds', 'duration_seconds')
        """))
        existing = {row[0] for row in result}

        if 'total_rounds' not in existing:
            conn.execute(db.text(
                "ALTER TABLE group_learning_progress ADD COLUMN total_rounds INTEGER NOT NULL DEFAULT 0"
            ))
            print('Added column: total_rounds')
        else:
            print('Column already exists: total_rounds')

        if 'duration_seconds' not in existing:
            conn.execute(db.text(
                "ALTER TABLE group_learning_progress ADD COLUMN duration_seconds INTEGER"
            ))
            print('Added column: duration_seconds')
        else:
            print('Column already exists: duration_seconds')

        conn.commit()
    print('Migration complete.')
