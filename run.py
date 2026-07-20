"""Development server entry point."""
from backend import create_app

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        from backend.models import db
        db.create_all()
    app.run(debug=True, host='127.0.0.1', port=5000)
