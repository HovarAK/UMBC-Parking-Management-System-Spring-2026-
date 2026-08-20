from flask import Blueprint, flash, redirect, render_template, request, url_for

from ..db import AppError, call_procedure, call_scalar_function, run_query

bp = Blueprint("reservations", __name__, url_prefix="/reservations")

STATUSES = ("Pending", "Active", "Cancelled", "Completed")


@bp.route("/")
def list_reservations():
    status = request.args.get("status", "")
    lot_id = request.args.get("lot_id", "")

    where = []
    params = {}
    if status:
        where.append("r.status = :status")
        params["status"] = status
    if lot_id:
        where.append("s.lot_id = :lot_id")
        params["lot_id"] = int(lot_id)

    where_sql = f"WHERE {' AND '.join(where)}" if where else ""
    reservations = run_query(
        f"""
        SELECT r.reservation_id, r.start_time, r.end_time, r.status,
               u.first_name, u.last_name, v.plate_number,
               s.spot_label, l.lot_id, l.lot_name
        FROM reservations r
        JOIN users u ON r.user_id = u.user_id
        JOIN vehicles v ON r.vehicle_id = v.vehicle_id
        JOIN spots s ON r.spot_id = s.spot_id
        JOIN lots l ON s.lot_id = l.lot_id
        {where_sql}
        ORDER BY r.start_time DESC
        """,
        params,
    )
    lots = run_query("SELECT lot_id, lot_name FROM lots ORDER BY lot_name")
    return render_template(
        "reservations/list.html",
        reservations=reservations,
        statuses=STATUSES,
        lots=lots,
        selected_status=status,
        selected_lot_id=lot_id,
    )


@bp.route("/new", methods=["GET", "POST"])
def new_reservation():
    users = run_query("SELECT user_id, first_name, last_name FROM users ORDER BY first_name")
    vehicles = run_query(
        """
        SELECT v.vehicle_id, v.plate_number, u.first_name, u.last_name
        FROM vehicles v JOIN users u ON v.user_id = u.user_id
        ORDER BY v.plate_number
        """
    )
    spots = run_query(
        """
        SELECT s.spot_id, s.spot_label, s.current_status, l.lot_name
        FROM spots s JOIN lots l ON s.lot_id = l.lot_id
        WHERE s.is_reservable = TRUE
        ORDER BY l.lot_name, s.spot_label
        """
    )

    if request.method == "POST":
        try:
            reservation_id = call_scalar_function(
                """
                SELECT make_reservation(
                    :start_time, :end_time, :status, :user_id, :vehicle_id, :spot_id
                ) AS reservation_id
                """,
                {
                    "start_time": request.form["start_time"],
                    "end_time": request.form["end_time"],
                    "status": request.form.get("status", "Pending"),
                    "user_id": int(request.form["user_id"]),
                    "vehicle_id": int(request.form["vehicle_id"]),
                    "spot_id": int(request.form["spot_id"]),
                },
            )
            flash(f"Reservation #{reservation_id} created.", "success")
            return redirect(url_for("reservations.list_reservations"))
        except AppError as exc:
            flash(str(exc), "error")
        except (KeyError, ValueError):
            flash("All fields are required.", "error")

    return render_template(
        "reservations/form.html",
        users=users,
        vehicles=vehicles,
        spots=spots,
        statuses=STATUSES,
    )


@bp.route("/<int:reservation_id>/cancel", methods=["POST"])
def cancel(reservation_id):
    try:
        call_procedure(
            "CALL cancel_reservation(:reservation_id)", {"reservation_id": reservation_id}
        )
        flash("Reservation cancelled and spot freed.", "success")
    except AppError as exc:
        flash(str(exc), "error")
    return redirect(url_for("reservations.list_reservations"))


@bp.route("/<int:reservation_id>/delete", methods=["POST"])
def delete(reservation_id):
    try:
        call_procedure(
            "CALL delete_reservation(:reservation_id)", {"reservation_id": reservation_id}
        )
        flash("Reservation deleted and spot freed.", "success")
    except AppError as exc:
        flash(str(exc), "error")
    return redirect(url_for("reservations.list_reservations"))
