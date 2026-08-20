from datetime import date

from flask import Blueprint, flash, redirect, render_template, request, url_for

from ..db import AppError, call_scalar_function, run_query, run_write

bp = Blueprint("permits", __name__, url_prefix="/permits")


@bp.route("/")
def list_permits():
    user_id = request.args.get("user_id", "")
    parking_type_id = request.args.get("parking_type_id", "")
    status = request.args.get("status", "")

    where = []
    params = {}
    if user_id:
        where.append("p.user_id = :user_id")
        params["user_id"] = int(user_id)
    if parking_type_id:
        where.append("p.parking_type_id = :parking_type_id")
        params["parking_type_id"] = int(parking_type_id)
    if status == "active":
        where.append("CURRENT_DATE BETWEEN p.valid_from AND p.valid_to")
    elif status == "expired":
        where.append("p.valid_to < CURRENT_DATE")
    elif status == "upcoming":
        where.append("p.valid_from > CURRENT_DATE")

    where_sql = f"WHERE {' AND '.join(where)}" if where else ""
    permits = run_query(
        f"""
        SELECT p.permit_id, p.valid_from, p.valid_to, p.created_at,
               pt.code AS type_code, pt.info AS type_info,
               u.user_id, u.first_name, u.last_name,
               CASE
                   WHEN CURRENT_DATE BETWEEN p.valid_from AND p.valid_to THEN 'Active'
                   WHEN p.valid_from > CURRENT_DATE THEN 'Upcoming'
                   ELSE 'Expired'
               END AS status
        FROM permits p
        JOIN parkingTypes pt ON p.parking_type_id = pt.parking_type_id
        JOIN users u ON p.user_id = u.user_id
        {where_sql}
        ORDER BY p.valid_to DESC
        """,
        params,
    )
    users = run_query("SELECT user_id, first_name, last_name FROM users ORDER BY first_name")
    parking_types = run_query("SELECT parking_type_id, code, info FROM parkingTypes ORDER BY code")
    return render_template(
        "permits/list.html",
        permits=permits,
        users=users,
        parking_types=parking_types,
        selected_user_id=user_id,
        selected_parking_type_id=parking_type_id,
        selected_status=status,
    )


@bp.route("/new", methods=["GET", "POST"])
def new_permit():
    users = run_query("SELECT user_id, first_name, last_name FROM users ORDER BY first_name")
    parking_types = run_query("SELECT parking_type_id, code, info FROM parkingTypes ORDER BY code")

    if request.method == "POST":
        try:
            user_id = int(request.form["user_id"])
            parking_type_id = int(request.form["parking_type_id"])
            valid_from = request.form["valid_from"]
            valid_to = request.form["valid_to"]
            _check_permit_capacity(parking_type_id, request.form.get("type_info", ""))
            permit_id = call_scalar_function(
                """
                SELECT issue_permit(:user_id, :parking_type_id, :valid_from, :valid_to)
                AS permit_id
                """,
                {
                    "user_id": user_id,
                    "parking_type_id": parking_type_id,
                    "valid_from": valid_from,
                    "valid_to": valid_to,
                },
            )
            flash(f"Permit #{permit_id} issued.", "success")
            return redirect(url_for("permits.list_permits"))
        except AppError as exc:
            flash(str(exc), "error")
        except (KeyError, ValueError):
            flash("All fields are required and dates must be valid.", "error")

    return render_template(
        "permits/form.html", users=users, parking_types=parking_types, today=date.today().isoformat()
    )


@bp.route("/<int:permit_id>/revoke", methods=["POST"])
def revoke_permit(permit_id):
    try:
        run_write("DELETE FROM permits WHERE permit_id = :permit_id", {"permit_id": permit_id})
        flash("Permit revoked.", "success")
    except AppError as exc:
        flash(f"Couldn't revoke permit: {exc}", "error")
    return redirect(url_for("permits.list_permits"))


def _check_permit_capacity(parking_type_id, type_label):
    """Enforce a permit capacity limit per parking type: the number of
    currently-active permits of a type may not exceed the combined
    advertised capacity (lots.capacity) of every lot that has at least
    one spot of that type. If no lot has any spot of that type, there's
    no capacity data to check against, so the check is skipped rather
    than blocking every permit of that type outright."""
    capacity_rows = run_query(
        """
        SELECT COALESCE(SUM(l.capacity), 0) AS type_capacity
        FROM lots l
        WHERE l.lot_id IN (
            SELECT DISTINCT lot_id FROM spots WHERE parking_type_id = :parking_type_id
        )
        """,
        {"parking_type_id": parking_type_id},
    )
    type_capacity = capacity_rows[0]["type_capacity"]
    if type_capacity == 0:
        return

    active_rows = run_query(
        """
        SELECT COUNT(*) AS active_count
        FROM permits
        WHERE parking_type_id = :parking_type_id
          AND CURRENT_DATE BETWEEN valid_from AND valid_to
        """,
        {"parking_type_id": parking_type_id},
    )
    active_count = active_rows[0]["active_count"]

    if active_count >= type_capacity:
        label = type_label or "this parking type"
        raise AppError(
            f"Permit capacity reached for {label}: {active_count}/{type_capacity} "
            "active permits already issued."
        )
