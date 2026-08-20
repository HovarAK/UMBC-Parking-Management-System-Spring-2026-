from flask import Blueprint, flash, redirect, render_template, request, url_for

from ..db import AppError, run_query, run_write

bp = Blueprint("users", __name__, url_prefix="/users")


@bp.route("/")
def list_users():
    search = request.args.get("search", "").strip()
    where_sql = ""
    params = {}
    if search:
        where_sql = "WHERE u.first_name ILIKE :search OR u.last_name ILIKE :search OR u.email ILIKE :search"
        params["search"] = f"%{search}%"

    users = run_query(
        f"""
        SELECT u.user_id, u.first_name, u.last_name, u.email, u.created_at,
               sr.role_name
        FROM users u
        JOIN systemRoles sr ON u.role_id = sr.role_id
        {where_sql}
        ORDER BY u.last_name, u.first_name
        """,
        params,
    )
    return render_template("users/list.html", users=users, search=search)


@bp.route("/<int:user_id>")
def detail(user_id):
    user_rows = run_query(
        """
        SELECT u.*, sr.role_name FROM users u
        JOIN systemRoles sr ON u.role_id = sr.role_id
        WHERE u.user_id = :user_id
        """,
        {"user_id": user_id},
    )
    if not user_rows:
        flash("User not found.", "error")
        return redirect(url_for("users.list_users"))

    vehicles = run_query(
        "SELECT * FROM vehicles WHERE user_id = :user_id ORDER BY plate_number",
        {"user_id": user_id},
    )
    permits = run_query(
        """
        SELECT p.permit_id, p.valid_from, p.valid_to, pt.code, pt.info
        FROM permits p JOIN parkingTypes pt ON p.parking_type_id = pt.parking_type_id
        WHERE p.user_id = :user_id
        ORDER BY p.valid_to DESC
        """,
        {"user_id": user_id},
    )
    reservations = run_query(
        """
        SELECT r.reservation_id, r.start_time, r.end_time, r.status, s.spot_label
        FROM reservations r JOIN spots s ON r.spot_id = s.spot_id
        WHERE r.user_id = :user_id
        ORDER BY r.start_time DESC
        LIMIT 10
        """,
        {"user_id": user_id},
    )
    return render_template(
        "users/detail.html",
        user=user_rows[0],
        vehicles=vehicles,
        permits=permits,
        reservations=reservations,
    )


@bp.route("/new", methods=["GET", "POST"])
def new_user():
    roles = run_query("SELECT role_id, role_name FROM systemRoles ORDER BY role_name")
    if request.method == "POST":
        try:
            _validate(request.form)
            run_write(
                """
                INSERT INTO users (first_name, last_name, email, role_id)
                VALUES (:first_name, :last_name, :email, :role_id)
                """,
                {
                    "first_name": request.form["first_name"].strip(),
                    "last_name": request.form["last_name"].strip(),
                    "email": request.form["email"].strip(),
                    "role_id": int(request.form["role_id"]),
                },
            )
            flash("User created.", "success")
            return redirect(url_for("users.list_users"))
        except AppError as exc:
            flash(str(exc), "error")
        except ValueError as exc:
            flash(str(exc), "error")
    return render_template("users/form.html", roles=roles)


def _validate(form):
    if not form.get("first_name", "").strip() or not form.get("last_name", "").strip():
        raise ValueError("First and last name are required.")
    if not form.get("email", "").strip() or "@" not in form.get("email", ""):
        raise ValueError("A valid email is required.")
    if not form.get("role_id"):
        raise ValueError("Role is required.")
