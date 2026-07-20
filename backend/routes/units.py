from flask import Blueprint, request, jsonify
from flask_login import current_user

from ..models import get_book_models
from ..decorators import api_login_required

units_bp = Blueprint('units', __name__)


@units_bp.route('')
@api_login_required
def get_units():
    book = request.args.get('book_schema', current_user.current_book)
    UnitModel, WordModel = get_book_models(book)

    units = UnitModel.query.order_by(UnitModel.order_num).all()
    result = []
    for u in units:
        count = WordModel.query.filter_by(unit_id=u.id).count()
        result.append({
            'id': u.id,
            'name': u.name,
            'word_count': count
        })
    return jsonify(result)
