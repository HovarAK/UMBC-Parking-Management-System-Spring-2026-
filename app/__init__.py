import os

from flask import Flask, g, render_template, session

from .db import AppError, DatabaseUnavailable, run_query


def create_app():
    app = Flask(__name__)
    app.secret_key = os.getenv("FLASK_SECRET_KEY", "dev-only-secret-change-me")

    from .routes.dashboard import bp as dashboard_bp
    from .routes.lots import bp as lots_bp
    from .routes.permits import bp as permits_bp
    from .routes.reservations import bp as reservations_bp
    from .routes.session_routes import bp as session_bp
    from .routes.tickets import bp as tickets_bp
    from .routes.users import bp as users_bp
    from .routes.vehicles import bp as vehicles_bp

    app.register_blueprint(dashboard_bp)
    app.register_blueprint(lots_bp)
    app.register_blueprint(permits_bp)
    app.register_blueprint(reservations_bp)
    app.register_blueprint(users_bp)
    app.register_blueprint(vehicles_bp)
    app.register_blueprint(tickets_bp)
    app.register_blueprint(session_bp)

    @app.before_request
    def load_acting_user():
        # Lightweight "act as" selector, not real auth: no passwords, no
        # sessions beyond a plain user_id in the Flask session cookie.
        # Lets the UI adapt (e.g. only Enforcement Officer/Admin see the
        # "issue ticket" action) without building a login system for a
        # database-focused portfolio project.
        g.acting_user = None
        user_id = session.get("acting_as_user_id")
        if user_id:
            rows = run_query(
                """
                SELECT u.user_id, u.first_name, u.last_name, sr.role_name
                FROM users u
                JOIN systemRoles sr ON u.role_id = sr.role_id
                WHERE u.user_id = :user_id
                """,
                {"user_id": user_id},
            )
            if rows:
                g.acting_user = rows[0]
            else:
                session.pop("acting_as_user_id", None)

    @app.context_processor
    def inject_acting_user():
        def all_users_for_act_as():
            return run_query(
                """
                SELECT u.user_id, u.first_name, u.last_name, sr.role_name
                FROM users u
                JOIN systemRoles sr ON u.role_id = sr.role_id
                ORDER BY u.first_name, u.last_name
                """
            )

        return {
            "acting_user": getattr(g, "acting_user", None),
            "all_users_for_act_as": all_users_for_act_as,
        }

    @app.errorhandler(DatabaseUnavailable)
    def handle_db_unavailable(_exc):
        return (
            render_template(
                "error.html",
                title="Database unavailable",
                message="The database isn't reachable right now. If you just started the "
                "stack, give it a few seconds and refresh.",
            ),
            503,
        )

    @app.errorhandler(AppError)
    def handle_app_error(exc):
        return (
            render_template("error.html", title="Request failed", message=str(exc)),
            400,
        )

    @app.errorhandler(404)
    def handle_not_found(_exc):
        return (
            render_template("error.html", title="Not found", message="That page doesn't exist."),
            404,
        )

    return app
