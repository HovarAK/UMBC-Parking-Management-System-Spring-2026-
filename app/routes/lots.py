from flask import Blueprint, flash, redirect, render_template, request, url_for

from ..db import AppError, run_query, run_write

bp = Blueprint("lots", __name__, url_prefix="/lots")


@bp.route("/")
def list_lots():
    search = request.args.get("search", "").strip()
    gated = request.args.get("gated", "")

    where = []
    params = {}
    if search:
        where.append("lot_name ILIKE :search OR location ILIKE :search")
        params["search"] = f"%{search}%"
    if gated in ("true", "false"):
        where.append("is_gated = :gated")
        params["gated"] = gated == "true"

    where_sql = f"WHERE {' AND '.join(where)}" if where else ""
    lots = run_query(
        f"""
        SELECT l.lot_id, l.lot_name, l.location, l.is_gated, l.capacity,
               COUNT(s.spot_id) AS tracked_spots,
               COUNT(CASE WHEN s.current_status = 'Available' THEN 1 END) AS available_spots
        FROM lots l
        LEFT JOIN spots s ON l.lot_id = s.lot_id
        {where_sql}
        GROUP BY l.lot_id, l.lot_name, l.location, l.is_gated, l.capacity
        ORDER BY l.lot_name
        """,
        params,
    )
    return render_template(
        "lots/list.html", lots=lots, search=search, gated=gated
    )


@bp.route("/<int:lot_id>")
def detail(lot_id):
    lot_rows = run_query("SELECT * FROM lots WHERE lot_id = :lot_id", {"lot_id": lot_id})
    if not lot_rows:
        flash("Lot not found.", "error")
        return redirect(url_for("lots.list_lots"))
    spots = run_query(
        """
        SELECT s.spot_id, s.spot_label, s.current_status, s.is_reservable,
               s.is_ada, s.has_ev_charging, pt.code AS type_code, pt.info AS type_info
        FROM spots s
        JOIN parkingTypes pt ON s.parking_type_id = pt.parking_type_id
        WHERE s.lot_id = :lot_id
        ORDER BY s.spot_label
        """,
        {"lot_id": lot_id},
    )
    return render_template("lots/detail.html", lot=lot_rows[0], spots=spots)


@bp.route("/new", methods=["GET", "POST"])
def new_lot():
    if request.method == "POST":
        try:
            _validate_lot_form(request.form)
            run_write(
                """
                INSERT INTO lots (lot_name, location, is_gated, capacity)
                VALUES (:lot_name, :location, :is_gated, :capacity)
                """,
                _lot_params(request.form),
            )
            flash("Lot created.", "success")
            return redirect(url_for("lots.list_lots"))
        except AppError as exc:
            flash(str(exc), "error")
        except ValueError as exc:
            flash(str(exc), "error")
    return render_template("lots/form.html", lot=None)


@bp.route("/<int:lot_id>/edit", methods=["GET", "POST"])
def edit_lot(lot_id):
    lot_rows = run_query("SELECT * FROM lots WHERE lot_id = :lot_id", {"lot_id": lot_id})
    if not lot_rows:
        flash("Lot not found.", "error")
        return redirect(url_for("lots.list_lots"))

    if request.method == "POST":
        try:
            _validate_lot_form(request.form)
            params = _lot_params(request.form)
            params["lot_id"] = lot_id
            run_write(
                """
                UPDATE lots
                SET lot_name = :lot_name, location = :location,
                    is_gated = :is_gated, capacity = :capacity
                WHERE lot_id = :lot_id
                """,
                params,
            )
            flash("Lot updated.", "success")
            return redirect(url_for("lots.detail", lot_id=lot_id))
        except AppError as exc:
            flash(str(exc), "error")
        except ValueError as exc:
            flash(str(exc), "error")

    return render_template("lots/form.html", lot=lot_rows[0])


@bp.route("/<int:lot_id>/delete", methods=["POST"])
def delete_lot(lot_id):
    try:
        run_write("DELETE FROM lots WHERE lot_id = :lot_id", {"lot_id": lot_id})
        flash("Lot deleted.", "success")
    except AppError as exc:
        # Most likely an ON DELETE RESTRICT bounce from spots still
        # referencing this lot.
        flash(f"Couldn't delete lot: {exc}", "error")
    return redirect(url_for("lots.list_lots"))


def _validate_lot_form(form):
    if not form.get("lot_name", "").strip():
        raise ValueError("Lot name is required.")
    if not form.get("location", "").strip():
        raise ValueError("Location is required.")
    try:
        capacity = int(form.get("capacity", ""))
    except ValueError:
        raise ValueError("Capacity must be a whole number.") from None
    if capacity <= 0:
        raise ValueError("Capacity must be greater than zero.")


def _lot_params(form):
    return {
        "lot_name": form.get("lot_name", "").strip(),
        "location": form.get("location", "").strip(),
        "is_gated": form.get("is_gated") == "on",
        "capacity": int(form.get("capacity")),
    }
