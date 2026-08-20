from flask import Blueprint, flash, redirect, request, session, url_for

bp = Blueprint("session_routes", __name__)


@bp.route("/act-as", methods=["POST"])
def act_as():
    """Set (or clear) which existing user the UI acts as. Not real
    authentication -- see the comment in app/__init__.py."""
    user_id = request.form.get("user_id", "").strip()
    if user_id:
        session["acting_as_user_id"] = int(user_id)
        flash("Now acting as the selected user.", "info")
    else:
        session.pop("acting_as_user_id", None)
        flash("Cleared the acting user.", "info")
    return redirect(request.referrer or url_for("dashboard.index"))
