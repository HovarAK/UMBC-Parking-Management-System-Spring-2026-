from flask import Blueprint, flash, g, redirect, render_template, request, url_for

from ..db import AppError, run_query, run_write

bp = Blueprint("tickets", __name__, url_prefix="/tickets")

ISSUER_ROLES = ("Admin", "Enforcement Officer")


@bp.route("/")
def list_tickets():
    unpaid_only = request.args.get("unpaid") == "1"
    where_sql = "WHERE t.has_paid = FALSE" if unpaid_only else ""
    tickets = run_query(
        f"""
        SELECT t.ticket_id, t.created_at, t.violation_type, t.fine_amount,
               t.has_paid, v.plate_number,
               u.user_id, u.first_name, u.last_name
        FROM tickets t
        JOIN vehicles v ON t.vehicle_id = v.vehicle_id
        JOIN users u ON t.issued_to_user_id = u.user_id
        {where_sql}
        ORDER BY t.created_at DESC
        """
    )
    return render_template("tickets/list.html", tickets=tickets, unpaid_only=unpaid_only)


@bp.route("/new", methods=["GET", "POST"])
def new_ticket():
    if not _acting_user_can_issue():
        flash("Only an Enforcement Officer or Admin can issue a ticket. Use “Act as” to switch users.", "error")
        return redirect(url_for("tickets.list_tickets"))

    rates = run_query("SELECT violation_type, fine_amount FROM violationRates ORDER BY violation_type")
    users = run_query("SELECT user_id, first_name, last_name FROM users ORDER BY first_name")
    vehicles = run_query(
        """
        SELECT v.vehicle_id, v.plate_number, v.user_id
        FROM vehicles v ORDER BY v.plate_number
        """
    )
    spots = run_query(
        """
        SELECT s.spot_id, s.spot_label, l.lot_name
        FROM spots s JOIN lots l ON s.lot_id = l.lot_id
        ORDER BY l.lot_name, s.spot_label
        """
    )

    if request.method == "POST":
        try:
            violation_type = request.form["violation_type"]
            rate = next((r for r in rates if r["violation_type"] == violation_type), None)
            if rate is None:
                raise ValueError("Unknown violation type.")
            run_write(
                """
                INSERT INTO tickets (
                    violation_type, fine_amount, issued_to_user_id,
                    issued_by_user_id, spot_id, vehicle_id
                )
                VALUES (
                    :violation_type, :fine_amount, :issued_to_user_id,
                    :issued_by_user_id, :spot_id, :vehicle_id
                )
                """,
                {
                    "violation_type": violation_type,
                    "fine_amount": rate["fine_amount"],
                    "issued_to_user_id": int(request.form["issued_to_user_id"]),
                    "issued_by_user_id": g.acting_user["user_id"],
                    "spot_id": int(request.form["spot_id"]),
                    "vehicle_id": int(request.form["vehicle_id"]),
                },
            )
            flash("Ticket issued.", "success")
            return redirect(url_for("tickets.list_tickets"))
        except AppError as exc:
            flash(str(exc), "error")
        except (KeyError, ValueError) as exc:
            flash(str(exc) or "All fields are required.", "error")

    return render_template(
        "tickets/form.html", rates=rates, users=users, vehicles=vehicles, spots=spots
    )


@bp.route("/<int:ticket_id>/pay", methods=["POST"])
def mark_paid(ticket_id):
    try:
        run_write(
            "UPDATE tickets SET has_paid = TRUE WHERE ticket_id = :ticket_id",
            {"ticket_id": ticket_id},
        )
        flash("Ticket marked as paid.", "success")
    except AppError as exc:
        flash(str(exc), "error")
    return redirect(url_for("tickets.list_tickets"))


def _acting_user_can_issue():
    acting_user = getattr(g, "acting_user", None)
    return bool(acting_user and acting_user["role_name"] in ISSUER_ROLES)
