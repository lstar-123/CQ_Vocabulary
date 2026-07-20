from collections import defaultdict

from flask import Blueprint, request, jsonify

from ..models import db, User, QuizSession, QuizAnswer, BOOK_SCHEMAS, get_book_models
from ..decorators import teacher_required

teacher_bp = Blueprint('teacher', __name__)


# ----------------------------------------------------------------
# Student management
# ----------------------------------------------------------------
@teacher_bp.route('/students')
@teacher_required
def get_students():
    students = User.query.order_by(User.created_at.desc()).all()
    result = []
    for s in students:
        sessions = QuizSession.query.filter_by(user_id=s.id).all()
        total_quizzes = len(sessions)
        if total_quizzes > 0:
            avg_score = round(sum(float(q.score_pct) for q in sessions) / total_quizzes, 1)
            best_score = round(max(float(q.score_pct) for q in sessions), 1)
            total_words = sum(q.total_count for q in sessions)
        else:
            avg_score = 0
            best_score = 0
            total_words = 0

        result.append({
            'id': s.id,
            'username': s.username,
            'created_at': s.created_at.isoformat() if s.created_at else None,
            'total_quizzes': total_quizzes,
            'avg_score': avg_score,
            'best_score': best_score,
            'total_words_tested': total_words
        })
    return jsonify(result)


@teacher_bp.route('/students/<int:student_id>')
@teacher_required
def get_student_detail(student_id):
    student = db.session.get(User, student_id)
    if not student:
        return jsonify({'error': '学生不存在'}), 404

    sessions = QuizSession.query.filter_by(user_id=student.id).all()
    total_quizzes = len(sessions)
    if total_quizzes > 0:
        avg_score = round(sum(float(q.score_pct) for q in sessions) / total_quizzes, 1)
        best_score = round(max(float(q.score_pct) for q in sessions), 1)
        total_words = sum(q.total_count for q in sessions)
    else:
        avg_score = 0
        best_score = 0
        total_words = 0

    return jsonify({
        'id': student.id,
        'username': student.username,
        'created_at': student.created_at.isoformat() if student.created_at else None,
        'total_quizzes': total_quizzes,
        'avg_score': avg_score,
        'best_score': best_score,
        'total_words_tested': total_words
    })


@teacher_bp.route('/students/<int:student_id>/sessions')
@teacher_required
def get_student_sessions(student_id):
    student = db.session.get(User, student_id)
    if not student:
        return jsonify({'error': '学生不存在'}), 404

    sessions = QuizSession.query \
        .filter_by(user_id=student.id) \
        .order_by(QuizSession.completed_at.desc()) \
        .all()

    # Resolve unit names — need to group by book_schema
    # Collect (book_schema, unit_id) pairs
    book_unit_pairs = defaultdict(set)
    for s in sessions:
        for uid in s.unit_ids.split(','):
            if uid.strip():
                book_unit_pairs[s.book_schema].add(int(uid.strip()))

    unit_map = {}  # (book_schema, unit_id) -> name
    for book_schema, unit_ids in book_unit_pairs.items():
        UnitModel, _ = get_book_models(book_schema)
        units = UnitModel.query.filter(UnitModel.id.in_(unit_ids)).all()
        for u in units:
            unit_map[(book_schema, u.id)] = u.name

    result = []
    for s in sessions:
        unit_id_list = [int(x.strip()) for x in s.unit_ids.split(',') if x.strip()]
        result.append({
            'id': s.id,
            'unit_ids': s.unit_ids,
            'unit_names': [unit_map.get((s.book_schema, uid), f'单元#{uid}') for uid in unit_id_list],
            'total_count': s.total_count,
            'correct_count': s.correct_count,
            'score_pct': float(s.score_pct),
            'book_schema': s.book_schema,
            'completed_at': s.completed_at.isoformat() if s.completed_at else None
        })
    return jsonify(result)


@teacher_bp.route('/students/<int:student_id>/sessions/<int:session_id>')
@teacher_required
def get_student_session_detail(student_id, session_id):
    student = db.session.get(User, student_id)
    if not student:
        return jsonify({'error': '学生不存在'}), 404

    session_record = db.session.get(QuizSession, session_id)
    if not session_record or session_record.user_id != student.id:
        return jsonify({'error': '记录不存在'}), 404

    answers = QuizAnswer.query.filter_by(session_id=session_id).all()

    # Resolve words using the session's book_schema
    _, WordModel = get_book_models(session_record.book_schema)

    answer_list = []
    for a in answers:
        word = db.session.get(WordModel, a.word_id)
        answer_list.append({
            'word_id': a.word_id,
            'chinese': word.chinese if word else '',
            'english': word.english if word else '',
            'user_answer': a.user_answer,
            'is_correct': a.is_correct
        })

    return jsonify({
        'id': session_record.id,
        'unit_ids': session_record.unit_ids,
        'total_count': session_record.total_count,
        'correct_count': session_record.correct_count,
        'score_pct': float(session_record.score_pct),
        'book_schema': session_record.book_schema,
        'completed_at': session_record.completed_at.isoformat() if session_record.completed_at else None,
        'answers': answer_list
    })


# ----------------------------------------------------------------
# Book listing for teacher word management
# ----------------------------------------------------------------
@teacher_bp.route('/books')
@teacher_required
def list_books():
    """List all available word books."""
    books = [{'schema': k, 'name': v} for k, v in BOOK_SCHEMAS.items()]
    return jsonify(books)


# ----------------------------------------------------------------
# Word management
# ----------------------------------------------------------------
@teacher_bp.route('/words')
@teacher_required
def get_words():
    unit_id = request.args.get('unit_id', type=int)
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 50, type=int)
    book_schema = request.args.get('book_schema', 'grade6_vol1')

    UnitModel, WordModel = get_book_models(book_schema)

    query = WordModel.query
    if unit_id:
        query = query.filter_by(unit_id=unit_id)

    query = query.order_by(WordModel.unit_id, WordModel.id)

    total = query.count()
    words = query.offset((page - 1) * per_page).limit(per_page).all()

    result = []
    for w in words:
        result.append({
            'id': w.id,
            'unit_id': w.unit_id,
            'unit_name': w.unit.name if w.unit else '',
            'english': w.english,
            'chinese': w.chinese
        })

    return jsonify({
        'words': result,
        'total': total,
        'page': page,
        'per_page': per_page
    })


@teacher_bp.route('/words', methods=['POST'])
@teacher_required
def create_word():
    data = request.get_json()
    if not data:
        return jsonify({'error': '请求数据无效'}), 400

    unit_id = data.get('unit_id')
    english = (data.get('english') or '').strip()
    chinese = (data.get('chinese') or '').strip()
    book_schema = data.get('book_schema', 'grade6_vol1')

    if not unit_id or not english or not chinese:
        return jsonify({'error': '单元、英文和中文不能为空'}), 400

    UnitModel, WordModel = get_book_models(book_schema)

    unit = db.session.get(UnitModel, unit_id)
    if not unit:
        return jsonify({'error': '单元不存在'}), 404

    word = WordModel(unit_id=unit_id, english=english, chinese=chinese)
    db.session.add(word)
    db.session.commit()

    return jsonify({
        'id': word.id,
        'unit_id': word.unit_id,
        'unit_name': word.unit.name if word.unit else '',
        'english': word.english,
        'chinese': word.chinese
    }), 201


@teacher_bp.route('/words/<int:word_id>', methods=['PUT'])
@teacher_required
def update_word(word_id):
    data = request.get_json()
    if not data:
        return jsonify({'error': '请求数据无效'}), 400

    book_schema = data.get('book_schema', 'grade6_vol1')
    _, WordModel = get_book_models(book_schema)

    word = db.session.get(WordModel, word_id)
    if not word:
        return jsonify({'error': '词汇不存在'}), 404

    if 'unit_id' in data:
        book_for_unit = data.get('book_schema', book_schema)
        UnitModel, _ = get_book_models(book_for_unit)
        unit = db.session.get(UnitModel, data['unit_id'])
        if not unit:
            return jsonify({'error': '单元不存在'}), 404
        word.unit_id = data['unit_id']

    if 'english' in data:
        english = (data['english'] or '').strip()
        if not english:
            return jsonify({'error': '英文不能为空'}), 400
        word.english = english

    if 'chinese' in data:
        chinese = (data['chinese'] or '').strip()
        if not chinese:
            return jsonify({'error': '中文不能为空'}), 400
        word.chinese = chinese

    db.session.commit()

    return jsonify({
        'id': word.id,
        'unit_id': word.unit_id,
        'unit_name': word.unit.name if word.unit else '',
        'english': word.english,
        'chinese': word.chinese
    })


@teacher_bp.route('/words/<int:word_id>', methods=['DELETE'])
@teacher_required
def delete_word(word_id):
    book_schema = request.args.get('book_schema', 'grade6_vol1')
    _, WordModel = get_book_models(book_schema)

    word = db.session.get(WordModel, word_id)
    if not word:
        return jsonify({'error': '词汇不存在'}), 404

    db.session.delete(word)
    db.session.commit()

    return jsonify({'ok': True})
