from functools import wraps
from flask import jsonify
from flask_login import current_user

from .models import Teacher


def api_login_required(f):
    """Return JSON 401 instead of a Flask-Login redirect."""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not current_user.is_authenticated:
            return jsonify({'error': '请先登录'}), 401
        return f(*args, **kwargs)
    return decorated


def teacher_required(f):
    """Return JSON 403 if the current user is not a teacher."""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not current_user.is_authenticated:
            return jsonify({'error': '请先登录'}), 401
        if not isinstance(current_user, Teacher):
            return jsonify({'error': '需要教师权限'}), 403
        return f(*args, **kwargs)
    return decorated
