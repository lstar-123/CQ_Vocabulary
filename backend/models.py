from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, timezone

db = SQLAlchemy()

# ----------------------------------------------------------------
# Book schema registry
# ----------------------------------------------------------------
BOOK_SCHEMAS = {
    'grade6_vol1': '六年级上册',
    'senior_compulsory_1': '高中必修一',
    'senior_compulsory_1_beijing': '北师大必修一',
}

def get_book_models(schema_name):
    """Return (UnitModel, WordModel) for a given book schema."""
    registry = {
        'grade6_vol1': (Grade6Vol1Unit, Grade6Vol1Word),
        'senior_compulsory_1': (SeniorCompulsory1Unit, SeniorCompulsory1Word),
        'senior_compulsory_1_beijing': (SeniorCompulsory1BeijingUnit, SeniorCompulsory1BeijingWord),
    }
    return registry.get(schema_name, (Grade6Vol1Unit, Grade6Vol1Word))


# ----------------------------------------------------------------
# Default-database models (vocab_quiz)
# ----------------------------------------------------------------

class User(UserMixin, db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    current_book = db.Column(db.String(50), nullable=True, default=None)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    quiz_sessions = db.relationship('QuizSession', backref='user', lazy=True,
                                    order_by='QuizSession.completed_at.desc()')

    def get_id(self):
        return f'student:{self.id}'

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)


class Teacher(UserMixin, db.Model):
    __tablename__ = 'teachers'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def get_id(self):
        return f'teacher:{self.id}'

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)


class QuizSession(db.Model):
    __tablename__ = 'quiz_sessions'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    unit_ids = db.Column(db.String(100), nullable=False)
    total_count = db.Column(db.Integer, nullable=False)
    correct_count = db.Column(db.Integer, nullable=False)
    score_pct = db.Column(db.Numeric(5, 2), nullable=False)
    duration_seconds = db.Column(db.Integer, nullable=True)
    book_schema = db.Column(db.String(50), nullable=True, default=None)
    completed_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    answers = db.relationship('QuizAnswer', backref='session', lazy=True)


class QuizAnswer(db.Model):
    __tablename__ = 'quiz_answers'

    id = db.Column(db.Integer, primary_key=True)
    session_id = db.Column(db.Integer, db.ForeignKey('quiz_sessions.id', ondelete='CASCADE'), nullable=False)
    word_id = db.Column(db.Integer, nullable=False)
    user_answer = db.Column(db.String(500), nullable=False)
    is_correct = db.Column(db.Boolean, nullable=False)
    book_schema = db.Column(db.String(50), nullable=True, default=None)


class GroupMemoryHistory(db.Model):
    """Immutable history record — one row per completed learning event.
    Only THREE event types are valid:
      - group_complete  : a single group of words was fully memorised & spelled
      - round_complete  : all groups in a round were completed
      - unit_complete   : all rounds in a unit were completed

    NO position tracking.  NO IN_PROGRESS rows.  NO automatic inserts.
    A row is written ONLY when the learner finishes the corresponding event."""

    __tablename__ = 'group_memory_history'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    unit_id = db.Column(db.Integer, nullable=False)
    book_schema = db.Column(db.String(50), nullable=False)

    event_type = db.Column(db.String(20), nullable=False)
    # 'group_complete' | 'round_complete' | 'unit_complete'

    round_index = db.Column(db.Integer, nullable=False, default=0)
    group_index = db.Column(db.Integer, nullable=True)   # NULL for round/unit complete
    group_size  = db.Column(db.Integer, nullable=True)   # NULL for round/unit complete
    duration_seconds = db.Column(db.Integer, nullable=True)

    error_count = db.Column(db.Integer, nullable=True, default=0)
    error_words = db.Column(db.JSON, nullable=True)      # [{english, chinese}]

    finished_at = db.Column(db.DateTime, nullable=False,
                            default=lambda: datetime.now(timezone.utc))


# ----------------------------------------------------------------
# Words-database models (vocab_quiz_words) — schema-qualified
# ----------------------------------------------------------------

class Grade6Vol1Unit(db.Model):
    __bind_key__ = 'words'
    __tablename__ = 'units'
    __table_args__ = {'schema': 'grade6_vol1'}

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False)
    order_num = db.Column(db.Integer, nullable=False, default=0)

    words = db.relationship('Grade6Vol1Word', backref='unit', lazy=True,
                            order_by='Grade6Vol1Word.id')


class Grade6Vol1Word(db.Model):
    __bind_key__ = 'words'
    __tablename__ = 'words'
    __table_args__ = {'schema': 'grade6_vol1'}

    id = db.Column(db.Integer, primary_key=True)
    unit_id = db.Column(db.Integer, db.ForeignKey('grade6_vol1.units.id', ondelete='CASCADE'), nullable=False)
    english = db.Column(db.String(255), nullable=False)
    chinese = db.Column(db.String(255), nullable=False)
    phonics_data = db.Column(db.JSON)
    phonics_version = db.Column(db.Integer, default=1)
    generated_by = db.Column(db.String(100))
    generated_at = db.Column(db.DateTime)
    reviewed = db.Column(db.Boolean, default=False)


class SeniorCompulsory1Unit(db.Model):
    __bind_key__ = 'words'
    __tablename__ = 'units'
    __table_args__ = {'schema': 'senior_compulsory_1'}

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False)
    order_num = db.Column(db.Integer, nullable=False, default=0)

    words = db.relationship('SeniorCompulsory1Word', backref='unit', lazy=True,
                            order_by='SeniorCompulsory1Word.id')


class SeniorCompulsory1Word(db.Model):
    __bind_key__ = 'words'
    __tablename__ = 'words'
    __table_args__ = {'schema': 'senior_compulsory_1'}

    id = db.Column(db.Integer, primary_key=True)
    unit_id = db.Column(db.Integer, db.ForeignKey('senior_compulsory_1.units.id', ondelete='CASCADE'), nullable=False)
    english = db.Column(db.String(255), nullable=False)
    chinese = db.Column(db.String(255), nullable=False)
    phonics_data = db.Column(db.JSON)
    phonics_version = db.Column(db.Integer, default=1)
    generated_by = db.Column(db.String(100))
    generated_at = db.Column(db.DateTime)
    reviewed = db.Column(db.Boolean, default=False)


class SeniorCompulsory1BeijingUnit(db.Model):
    __bind_key__ = 'words'
    __tablename__ = 'units'
    __table_args__ = {'schema': 'senior_compulsory_1_beijing'}

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False)
    order_num = db.Column(db.Integer, nullable=False, default=0)

    words = db.relationship('SeniorCompulsory1BeijingWord', backref='unit', lazy=True,
                            order_by='SeniorCompulsory1BeijingWord.id')


class SeniorCompulsory1BeijingWord(db.Model):
    __bind_key__ = 'words'
    __tablename__ = 'words'
    __table_args__ = {'schema': 'senior_compulsory_1_beijing'}

    id = db.Column(db.Integer, primary_key=True)
    unit_id = db.Column(db.Integer, db.ForeignKey('senior_compulsory_1_beijing.units.id', ondelete='CASCADE'), nullable=False)
    english = db.Column(db.String(255), nullable=False)
    chinese = db.Column(db.String(255), nullable=False)
    phonics_data = db.Column(db.JSON)
    phonics_version = db.Column(db.Integer, default=1)
    generated_by = db.Column(db.String(100))
    generated_at = db.Column(db.DateTime)
    reviewed = db.Column(db.Boolean, default=False)
