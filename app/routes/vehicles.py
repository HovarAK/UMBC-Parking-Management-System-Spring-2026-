from flask import Blueprint, flash, redirect, render_template, request, url_for

from ..db import AppError, run_query, run_write

bp = Blueprint("vehicles", __name__, url_prefix="/vehicles")


@bp.route("/")
def list_vehicles():
    search = request.args.get("search", "").strip()
    where_sql = ""
    params = {}
    if search:
        where_sql = "WHERE v.plate_number ILIKE :search OR v.make ILIKE :search OR v.model ILIKE :search"
        params["search"] = f"%{search}%"

    vehicles = run_query(
        f"""
        SELECT v.vehicle_id, v.plate_number, v.make, v.model, v.color,
               u.user_id, u.first_name, u.last_name
        FROM vehicles v
        JOIN users u ON v.user_id = u.user_id
        {where_sql}
        ORDER BY v.plate_number
        """,
        params,
    )
    return render_template("vehicles/list.html", vehicles=vehicles, search=search)


@bp.route("/new", methods=["GET", "POST"])
def new_vehicle():
    users = run_query("SELECT user_id, first_name, last_name FROM users ORDER BY first_name")
    if request.method == "POST":
        try:
            _validate(request.form)
            run_write(
                """
                INSERT INTO vehicles (plate_number, make, model, color, user_id)
                VALUES (:plate_number, :make, :model, :color, :user_id)
                """,
                {
                    "plate_number": request.form["plate_number"].strip().upper(),
                    "make": request.form["make"].strip(),
                    "model": request.form["model"].strip(),
                    "color": request.form["color"].strip(),
                    "user_id": int(request.form["user_id"]),
                },
            )
            flash("Vehicle added.", "success")
            return redirect(url_for("vehicles.list_vehicles"))
        except AppError as exc:
            flash(str(exc), "error")
        except ValueError as exc:
            flash(str(exc), "error")
    return render_template("vehicles/form.html", users=users)


@bp.route("/<int:vehicle_id>/delete", methods=["POST"])
def delete_vehicle(vehicle_id):
    try:
        run_write("DELETE FROM vehicles WHERE vehicle_id = :vehicle_id", {"vehicle_id": vehicle_id})
        flash("Vehicle deleted.", "success")
    except AppError as exc:
        flash(f"Couldn't delete vehicle: {exc}", "error")
    return redirect(url_for("vehicles.list_vehicles"))


def _validate(form):
    for field in ("plate_number", "make", "model", "color"):
        if not form.get(field, "").strip():
            raise ValueError(f"{field.replace('_', ' ').title()} is required.")
    if not form.get("user_id"):
        raise ValueError("Owner is required.")
