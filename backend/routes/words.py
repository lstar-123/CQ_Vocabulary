from flask import Blueprint, request, jsonify
from flask_login import current_user
from sqlalchemy import func

from ..models import get_book_models
from ..decorators import api_login_required
from ..phonics import get_phonics_data, adapt_phonics_for_frontend

words_bp = Blueprint('words', __name__)


@words_bp.route('')
@api_login_required
def get_words():
    book = request.args.get('book_schema', current_user.current_book)
    UnitModel, WordModel = get_book_models(book)

    unit_ids_str = request.args.get('unit_ids', '')
    query = WordModel.query

    if unit_ids_str:
        try:
            ids = [int(x.strip()) for x in unit_ids_str.split(',') if x.strip()]
        except ValueError:
            return jsonify({'error': 'unit_ids 格式错误'}), 400
        if ids:
            query = query.filter(WordModel.unit_id.in_(ids))

    # Default: natural order by unit_id then word id.
    # Pass ?random=1 to get shuffled order (used by quiz mode).
    if request.args.get('random') == '1':
        words = query.order_by(func.random()).all()
    else:
        words = query.order_by(WordModel.unit_id, WordModel.id).all()
    result = []
    for w in words:
        result.append({
            'id': w.id,
            'unit_id': w.unit_id,
            'unit_name': w.unit.name if w.unit else '',
            'english': w.english,
            'chinese': w.chinese
        })
    return jsonify(result)


@words_bp.route('/all')
@api_login_required
def get_all_words_grouped():
    """Return all words grouped by unit, for study mode."""
    book = request.args.get('book_schema', current_user.current_book)
    UnitModel, WordModel = get_book_models(book)

    units = UnitModel.query.order_by(UnitModel.order_num).all()
    result = []
    for u in units:
        words = WordModel.query.filter_by(unit_id=u.id).order_by(WordModel.id).all()
        result.append({
            'unit_id': u.id,
            'unit_name': u.name,
            'order_num': u.order_num,
            'words': [{
                'id': w.id,
                'english': w.english,
                'chinese': w.chinese
            } for w in words]
        })
    return jsonify(result)


@words_bp.route('/phonics')
@api_login_required
def get_phonics():
    """Return pre-generated phonics data for a word (DB lookup only).

    No runtime analysis is performed. If the word has no phonics_data in
    the database, returns 404. Manual overrides in
    data/manual_overrides.json always take priority.
    """
    word_text = (request.args.get('word') or '').strip()
    if not word_text:
        return jsonify({'error': 'word is required'}), 400

    book = request.args.get('book_schema', current_user.current_book)
    _, WordModel = get_book_models(book)

    word = WordModel.query.filter(
        func.lower(WordModel.english) == word_text.lower()
    ).first()

    if not word:
        return jsonify({'error': 'word not found'}), 404

    phonics_data = get_phonics_data(word)
    if phonics_data is None:
        return jsonify({'error': 'phonics data not available'}), 404

    # Adapt Claude format to frontend format
    return jsonify(adapt_phonics_for_frontend(phonics_data))
