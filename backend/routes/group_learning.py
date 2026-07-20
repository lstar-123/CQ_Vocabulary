from datetime import datetime, timezone

from flask import Blueprint, request, jsonify
from flask_login import current_user

from ..models import db, GroupMemoryHistory
from ..decorators import api_login_required

group_learning_bp = Blueprint('group_learning', __name__)

# ── Valid event types ──────────────────────────────────────────────────
VALID_EVENT_TYPES = {'group_complete', 'round_complete', 'unit_complete'}


# ═══════════════════════════════════════════════════════════════════════
# POST /api/group-learning/history  —  insert ONE immutable history row
# ═══════════════════════════════════════════════════════════════════════
@group_learning_bp.route('/history', methods=['POST'])
@api_login_required
def insert_history():
    """Record a completed learning event.

    Valid event_type values:
      - group_complete  : finished memorising + spelling one group
      - round_complete  : finished all groups in a round
      - unit_complete   : finished all rounds in a unit

    This is the ONLY write endpoint.  No progress tracking — every row
    is a standalone, immutable record of something the learner actually
    finished."""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required'}), 400

    unit_id = data.get('unit_id')
    book_schema = data.get('book_schema', current_user.current_book)
    event_type = data.get('event_type', '')

    if not unit_id:
        return jsonify({'error': 'unit_id is required'}), 400
    if event_type not in VALID_EVENT_TYPES:
        return jsonify({'error': f'event_type must be one of {sorted(VALID_EVENT_TYPES)}'}), 400

    round_index = data.get('round_index', 0)
    group_index = data.get('group_index')     # None for round/unit complete
    group_size = data.get('group_size')       # None for round/unit complete
    duration_seconds = data.get('duration_seconds')

    error_count = data.get('error_count', 0)
    error_words = data.get('error_words', None)

    finished_at_str = data.get('finished_at')
    finished_at = None
    if finished_at_str:
        try:
            finished_at = datetime.fromisoformat(finished_at_str)
        except ValueError:
            pass
    if not finished_at:
        finished_at = datetime.now(timezone.utc)

    record = GroupMemoryHistory(
        user_id=current_user.id,
        unit_id=unit_id,
        book_schema=book_schema,
        event_type=event_type,
        round_index=round_index,
        group_index=group_index,
        group_size=group_size,
        duration_seconds=duration_seconds,
        error_count=error_count,
        error_words=error_words,
        finished_at=finished_at
    )
    db.session.add(record)
    db.session.commit()

    return jsonify({
        'id': record.id,
        'event_type': record.event_type,
        'unit_id': record.unit_id,
        'round_index': record.round_index
    }), 201


# ═══════════════════════════════════════════════════════════════════════
# GET /api/group-learning/history  —  read history for display
# ═══════════════════════════════════════════════════════════════════════
@group_learning_bp.route('/history', methods=['GET'])
@api_login_required
def get_history():
    """Return all GroupMemoryHistory records for the current book.

    The frontend uses this to:
      - Determine which units / rounds are completed
      - Render the stats page

    No position tracking data is ever returned."""
    book_schema = request.args.get('book_schema', current_user.current_book)
    unit_id_str = request.args.get('unit_id', '')

    query = GroupMemoryHistory.query.filter_by(
        user_id=current_user.id,
        book_schema=book_schema
    )

    if unit_id_str:
        try:
            query = query.filter_by(unit_id=int(unit_id_str))
        except ValueError:
            pass

    records = query.order_by(GroupMemoryHistory.finished_at.desc()).all()

    result = []
    for r in records:
        result.append({
            'id': r.id,
            'unit_id': r.unit_id,
            'event_type': r.event_type,
            'round_index': r.round_index,
            'group_index': r.group_index,
            'group_size': r.group_size,
            'duration_seconds': r.duration_seconds,
            'error_count': r.error_count or 0,
            'error_words': r.error_words or [],
            'finished_at': r.finished_at.isoformat() if r.finished_at else None
        })

    # Also compute a per-unit summary: max_completed_round for each unit.
    # Only round_complete / unit_complete count — group_complete is
    # intermediate progress that should NOT unlock the next round.
    unit_max_round = {}
    unit_complete = set()
    for r in records:
        uid = r.unit_id
        if r.event_type == 'unit_complete':
            unit_complete.add(uid)
        if r.event_type in ('round_complete', 'unit_complete'):
            current = unit_max_round.get(uid, -1)
            if r.round_index > current:
                unit_max_round[uid] = r.round_index

    return jsonify({
        'records': result,
        'unit_max_completed_round': unit_max_round,
        'unit_complete': list(unit_complete)
    })
