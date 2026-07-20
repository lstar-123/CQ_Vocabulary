from flask import Blueprint, request, jsonify
from flask_login import current_user

from ..models import db, QuizSession, QuizAnswer
from ..decorators import api_login_required

quiz_bp = Blueprint('quiz', __name__)


@quiz_bp.route('/submit', methods=['POST'])
@api_login_required
def submit_quiz():
    data = request.get_json()
    if not data:
        return jsonify({'error': '请求数据无效'}), 400

    unit_ids = data.get('unit_ids', [])
    answers = data.get('answers', [])
    duration_seconds = data.get('duration_seconds')
    book_schema = data.get('book_schema', current_user.current_book)

    if not answers:
        return jsonify({'error': '答案不能为空'}), 400

    total_count = len(answers)
    correct_count = sum(1 for a in answers if a.get('is_correct'))
    score_pct = round((correct_count / total_count) * 100, 2) if total_count > 0 else 0

    session_record = QuizSession(
        user_id=current_user.id,
        unit_ids=','.join(str(x) for x in unit_ids),
        total_count=total_count,
        correct_count=correct_count,
        score_pct=score_pct,
        duration_seconds=duration_seconds,
        book_schema=book_schema
    )
    db.session.add(session_record)
    db.session.flush()

    for a in answers:
        answer = QuizAnswer(
            session_id=session_record.id,
            word_id=a['word_id'],
            user_answer=a.get('user_answer', ''),
            is_correct=a.get('is_correct', False),
            book_schema=book_schema
        )
        db.session.add(answer)

    db.session.commit()

    return jsonify({
        'session_id': session_record.id,
        'total_count': total_count,
        'correct_count': correct_count,
        'score_pct': float(score_pct)
    })
