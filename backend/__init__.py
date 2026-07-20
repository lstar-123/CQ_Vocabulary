import os
from flask import Flask, send_from_directory
from flask_login import LoginManager

from .config import Config
from .models import db, User, Teacher

login_manager = LoginManager()


def create_app():
    app = Flask(__name__, static_folder=None)
    app.config.from_object(Config)

    # Extensions
    db.init_app(app)
    login_manager.init_app(app)

    @login_manager.user_loader
    def load_user(user_id):
        if user_id.startswith('student:'):
            return db.session.get(User, int(user_id[8:]))
        elif user_id.startswith('teacher:'):
            return db.session.get(Teacher, int(user_id[8:]))
        return None

    # Blueprints
    from .routes.auth import auth_bp
    from .routes.units import units_bp
    from .routes.words import words_bp
    from .routes.quiz import quiz_bp
    from .routes.history import history_bp
    from .routes.stats import stats_bp
    from .routes.teacher import teacher_bp
    from .routes.tts import tts_bp
    from .routes.group_learning import group_learning_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(units_bp, url_prefix='/api/units')
    app.register_blueprint(words_bp, url_prefix='/api/words')
    app.register_blueprint(quiz_bp, url_prefix='/api/quiz')
    app.register_blueprint(history_bp, url_prefix='/api/history')
    app.register_blueprint(stats_bp, url_prefix='/api/stats')
    app.register_blueprint(teacher_bp, url_prefix='/api/teacher')
    app.register_blueprint(tts_bp, url_prefix='/api/tts')
    app.register_blueprint(group_learning_bp, url_prefix='/api/group-learning')

    # Frontend serving
    frontend_dir = os.path.join(os.path.dirname(__file__), '..', 'frontend')

    @app.route('/')
    def index():
        return send_from_directory(frontend_dir, 'quiz.html')

    @app.route('/teacher')
    def teacher_index():
        return send_from_directory(frontend_dir, 'teacher.html')

    @app.route('/<path:path>')
    def serve_frontend(path):
        return send_from_directory(frontend_dir, path)

    # ----------------------------------------------------------------
    # CLI Commands
    # ----------------------------------------------------------------
    @app.cli.command('init-db')
    def init_db_command():
        """Create all tables."""
        db.create_all()
        print('Database tables created.')

    @app.cli.command('create-teacher')
    def create_teacher_command():
        """Create a new teacher account."""
        from getpass import getpass
        username = input('Teacher username: ').strip()
        password = getpass('Teacher password: ')
        if not username or not password:
            print('ERROR: username and password are required.')
            return
        with app.app_context():
            existing = Teacher.query.filter_by(username=username).first()
            if existing:
                print(f'ERROR: Teacher "{username}" already exists.')
                return
            teacher = Teacher(username=username)
            teacher.set_password(password)
            db.session.add(teacher)
            db.session.commit()
            print(f'Teacher "{username}" created.')

    return app
