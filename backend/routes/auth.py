from flask import Blueprint, request, jsonify
from flask_login import login_user, logout_user, current_user

from ..models import db, User, Teacher, BOOK_SCHEMAS
from ..decorators import api_login_required

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data:
        return jsonify({'error': '请求数据无效'}), 400

    username = (data.get('username') or '').strip()
    password = (data.get('password') or '').strip()
    book_schema = (data.get('book_schema') or '').strip()

    if not username or not password:
        return jsonify({'error': '用户名和密码不能为空'}), 400
    if len(username) < 2 or len(username) > 50:
        return jsonify({'error': '用户名需要2-50个字符'}), 400
    if len(password) < 3:
        return jsonify({'error': '密码至少需要3个字符'}), 400

    if book_schema and book_schema not in BOOK_SCHEMAS:
        return jsonify({'error': f'无效的词书，可选值：{", ".join(BOOK_SCHEMAS.keys())}'}), 400

    existing = User.query.filter_by(username=username).first()
    if existing:
        return jsonify({'error': '用户名已存在'}), 409

    user = User(username=username)
    user.set_password(password)
    if book_schema:
        user.current_book = book_schema
    db.session.add(user)
    db.session.commit()

    login_user(user)
    return jsonify({
        'id': user.id,
        'username': user.username,
        'role': 'student',
        'current_book': user.current_book
    }), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data:
        return jsonify({'error': '请求数据无效'}), 400

    username = (data.get('username') or '').strip()
    password = (data.get('password') or '').strip()

    user = User.query.filter_by(username=username).first()
    if not user or not user.check_password(password):
        return jsonify({'error': '用户名或密码错误'}), 401

    login_user(user)
    return jsonify({
        'id': user.id,
        'username': user.username,
        'role': 'student',
        'current_book': user.current_book
    })


@auth_bp.route('/teacher/login', methods=['POST'])
def teacher_login():
    data = request.get_json()
    if not data:
        return jsonify({'error': '请求数据无效'}), 400

    username = (data.get('username') or '').strip()
    password = (data.get('password') or '').strip()

    teacher = Teacher.query.filter_by(username=username).first()
    if not teacher or not teacher.check_password(password):
        return jsonify({'error': '用户名或密码错误'}), 401

    login_user(teacher)
    return jsonify({'id': teacher.id, 'username': teacher.username, 'role': 'teacher'})


@auth_bp.route('/logout', methods=['POST'])
@api_login_required
def logout():
    logout_user()
    return jsonify({'ok': True})


@auth_bp.route('/book', methods=['PUT'])
@api_login_required
def switch_book():
    """Switch the current user's active word book."""
    data = request.get_json()
    if not data:
        return jsonify({'error': '请求数据无效'}), 400

    book_schema = (data.get('book_schema') or '').strip()
    if book_schema not in BOOK_SCHEMAS:
        return jsonify({'error': f'无效的词书，可选值：{", ".join(BOOK_SCHEMAS.keys())}'}), 400

    current_user.current_book = book_schema
    db.session.commit()
    return jsonify({
        'current_book': book_schema,
        'book_name': BOOK_SCHEMAS[book_schema]
    })


@auth_bp.route('/books')
@api_login_required
def list_books():
    """List all available word books."""
    books = [{'schema': k, 'name': v} for k, v in BOOK_SCHEMAS.items()]
    return jsonify(books)


@auth_bp.route('/username', methods=['PUT'])
@api_login_required
def change_username():
    data = request.get_json()
    if not data:
        return jsonify({'error': '请求数据无效'}), 400

    username = (data.get('username') or '').strip()
    if len(username) < 2 or len(username) > 50:
        return jsonify({'error': '用户名需要2-50个字符'}), 400

    existing = User.query.filter_by(username=username).first()
    if existing and existing.id != current_user.id:
        return jsonify({'error': '用户名已存在'}), 409

    current_user.username = username
    db.session.commit()
    return jsonify({
        'id': current_user.id,
        'username': current_user.username,
        'role': 'student',
        'current_book': current_user.current_book
    })


@auth_bp.route('/me')
def me():
    if current_user.is_authenticated:
        role = 'teacher' if isinstance(current_user, Teacher) else 'student'
        result = {
            'id': current_user.id,
            'username': current_user.username,
            'role': role
        }
        if role == 'student':
            result['current_book'] = current_user.current_book
        return jsonify(result)
    return jsonify({'user': None})
