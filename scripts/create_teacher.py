"""Create a new teacher user account.

Usage:
    python scripts/create_teacher.py
    (prompts for username and password interactively)

    Or set env vars:
    TEACHER_USERNAME=admin TEACHER_PASSWORD=secret python scripts/create_teacher.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend import create_app
from backend.models import db, Teacher

app = create_app()

with app.app_context():
    username = os.getenv('TEACHER_USERNAME') or input('Teacher username: ').strip()
    password = os.getenv('TEACHER_PASSWORD')
    if not password:
        from getpass import getpass
        password = getpass('Teacher password: ')

    if not username or not password:
        print('ERROR: username and password are required.')
        sys.exit(1)

    existing = Teacher.query.filter_by(username=username).first()
    if existing:
        print(f'ERROR: Teacher "{username}" already exists.')
        sys.exit(1)

    teacher = Teacher(username=username)
    teacher.set_password(password)
    db.session.add(teacher)
    db.session.commit()
    print(f'Teacher "{username}" created.')
