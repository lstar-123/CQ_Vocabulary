from flask import Blueprint, jsonify, request
from flask_login import current_user
from collections import defaultdict

from ..models import QuizSession, QuizAnswer, GroupMemoryHistory, get_book_models
from ..decorators import api_login_required

stats_bp = Blueprint('stats', __name__)


def _resolve_unit_map(book_schema):
    """Return {unit_id: unit_name} for a given book schema."""
    UnitModel, _ = get_book_models(book_schema)
    units = UnitModel.query.all()
    return {u.id: u.name for u in units}


@stats_bp.route('/trend')
@api_login_required
def get_stats_trend():
    book = request.args.get('book_schema', current_user.current_book)

    sessions = QuizSession.query \
        .filter_by(user_id=current_user.id, book_schema=book) \
        .order_by(QuizSession.completed_at.asc()) \
        .all()

    _, WordModel = get_book_models(book)

    all_unit_ids = set()
    for s in sessions:
        for uid in s.unit_ids.split(','):
            if uid.strip():
                all_unit_ids.add(int(uid.strip()))
    unit_map = {}
    if all_unit_ids:
        unit_map = _resolve_unit_map(book)

    # Pre-compute per-unit scores for multi-unit sessions
    # Since FK is cross-database, resolve word -> unit manually
    multi_sessions = [s for s in sessions if ',' in s.unit_ids]
    unit_scores_map = {}  # session_id -> {unit_id_str: {total, correct, score_pct}}
    if multi_sessions:
        multi_session_ids = [s.id for s in multi_sessions]
        answers = QuizAnswer.query \
            .filter(QuizAnswer.session_id.in_(multi_session_ids)) \
            .all()

        # Batch-fetch words to resolve unit_id
        word_ids = list(set(a.word_id for a in answers))
        word_unit_map = {}
        if word_ids:
            words = WordModel.query.filter(WordModel.id.in_(word_ids)).all()
            word_unit_map = {w.id: w.unit_id for w in words}

        session_unit_stats = defaultdict(lambda: defaultdict(lambda: {'total': 0, 'correct': 0}))
        for a in answers:
            unit_id = word_unit_map.get(a.word_id)
            if unit_id is None:
                continue
            stats = session_unit_stats[a.session_id][unit_id]
            stats['total'] += 1
            if a.is_correct:
                stats['correct'] += 1

        for session_id, unit_stats in session_unit_stats.items():
            unit_scores_map[session_id] = {}
            for unit_id, stats in unit_stats.items():
                unit_scores_map[session_id][str(unit_id)] = {
                    'total': stats['total'],
                    'correct': stats['correct'],
                    'score_pct': round(stats['correct'] / stats['total'] * 100, 1) if stats['total'] > 0 else 0
                }

    result = []
    for s in sessions:
        unit_id_list = [int(x.strip()) for x in s.unit_ids.split(',') if x.strip()]
        entry = {
            'date': s.completed_at.strftime('%m-%d %H:%M') if s.completed_at else '',
            'score_pct': float(s.score_pct),
            'total_count': s.total_count,
            'correct_count': s.correct_count,
            'unit_ids': s.unit_ids,
            'unit_names': [unit_map.get(uid, f'单元#{uid}') for uid in unit_id_list]
        }
        if s.id in unit_scores_map:
            entry['unit_scores'] = unit_scores_map[s.id]
        result.append(entry)
    return jsonify(result)


@stats_bp.route('/summary')
@api_login_required
def get_stats_summary():
    book = request.args.get('book_schema', current_user.current_book)

    sessions = QuizSession.query.filter_by(
        user_id=current_user.id,
        book_schema=book
    ).all()
    total_quizzes = len(sessions)

    if total_quizzes > 0:
        scores = [float(s.score_pct) for s in sessions]
        avg_score = round(sum(scores) / len(scores), 1)
        best_score = round(max(scores), 1)
        total_words_tested = sum(s.total_count for s in sessions)
        total_correct = sum(s.correct_count for s in sessions)
    else:
        avg_score = 0
        best_score = 0
        total_words_tested = 0
        total_correct = 0

    # Group learning stats — count completed units and total sessions
    group_records = GroupMemoryHistory.query.filter_by(
        user_id=current_user.id,
        book_schema=book
    ).all()
    total_units_studied = len(set(r.unit_id for r in group_records
                                  if r.event_type == 'unit_complete'))
    total_sessions = len(group_records)

    return jsonify({
        'total_quizzes': total_quizzes,
        'avg_score': avg_score,
        'best_score': best_score,
        'total_words_tested': total_words_tested,
        'total_correct': total_correct,
        'total_units_studied': total_units_studied,
        'total_group_sessions': total_sessions
    })


@stats_bp.route('/group-history')
@api_login_required
def get_group_history():
    """Return group-memory history records for the stats page.
    Reads from the immutable GroupMemoryHistory table — one row
    per completed group / round / unit event."""
    book = request.args.get('book_schema', current_user.current_book)

    records = GroupMemoryHistory.query.filter_by(
        user_id=current_user.id,
        book_schema=book
    ).order_by(
        GroupMemoryHistory.finished_at.desc()
    ).all()

    unit_map = _resolve_unit_map(book)

    result = []
    for r in records:
        unit_name = unit_map.get(r.unit_id, f'Unit#{r.unit_id}')
        # Build a human-readable label from the event type
        if r.event_type == 'unit_complete':
            label = f'🏆 Unit 完成'
        elif r.event_type == 'round_complete':
            label = f'第{r.round_index + 1}轮 完成'
        else:
            label = f'第{r.round_index + 1}轮 · 第{r.group_index}组'

        result.append({
            'id': r.id,
            'unit_id': r.unit_id,
            'unit_name': unit_name,
            'event_type': r.event_type,
            'round_index': r.round_index,
            'group_index': r.group_index,
            'group_size': r.group_size,
            'label': label,
            'duration_seconds': r.duration_seconds,
            'error_count': r.error_count or 0,
            'error_words': r.error_words or [],
            'finished_at': r.finished_at.isoformat() if r.finished_at else None
        })
    return jsonify(result)
