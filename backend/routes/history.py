from flask import Blueprint, jsonify, request
from flask_login import current_user

from ..models import db, QuizSession, QuizAnswer, get_book_models
from ..decorators import api_login_required

history_bp = Blueprint('history', __name__)


@history_bp.route('')
@api_login_required
def get_history():
    unit_id = request.args.get('unit_id', type=int)
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    book_schema = request.args.get('book_schema', current_user.current_book)

    query = QuizSession.query.filter_by(
        user_id=current_user.id,
        book_schema=book_schema
    )

    if unit_id:
        # Match unit_id in comma-separated unit_ids: "1", "1,2", "2,1,3", etc.
        query = query.filter(
            db.func.concat(',', QuizSession.unit_ids, ',').like(f'%,{unit_id},%')
        )

    total = query.count()
    total_pages = max(1, (total + per_page - 1) // per_page)
    page = max(1, min(page, total_pages))

    sessions = query \
        .order_by(QuizSession.completed_at.desc()) \
        .offset((page - 1) * per_page) \
        .limit(per_page).all()

    result = []
    for s in sessions:
        result.append({
            'id': s.id,
            'unit_ids': s.unit_ids,
            'total_count': s.total_count,
            'correct_count': s.correct_count,
            'score_pct': float(s.score_pct),
            'duration_seconds': s.duration_seconds,
            'book_schema': s.book_schema,
            'completed_at': s.completed_at.isoformat() if s.completed_at else None
        })

    return jsonify({
        'items': result,
        'total': total,
        'page': page,
        'per_page': per_page,
        'total_pages': total_pages
    })


@history_bp.route('/<int:session_id>')
@api_login_required
def get_history_detail(session_id):
    session_record = db.session.get(QuizSession, session_id)
    if not session_record or session_record.user_id != current_user.id:
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
        'duration_seconds': session_record.duration_seconds,
        'book_schema': session_record.book_schema,
        'completed_at': session_record.completed_at.isoformat() if session_record.completed_at else None,
        'answers': answer_list
    })
