from flask import Blueprint, render_template

from ..db import run_query

bp = Blueprint("dashboard", __name__)


@bp.route("/")
def index():
    lot_availability = run_query(
        "SELECT * FROM CurrentLotAvailability ORDER BY lot_name"
    )
    active_permits = run_query(
        "SELECT COUNT(*) AS count FROM CurrentActivePermits"
    )[0]["count"]
    overdue = run_query(
        "SELECT COUNT(*) AS count, COALESCE(SUM(fine_amount), 0) AS total FROM OverduePayments"
    )[0]
    upcoming_reservations = run_query(
        """
        SELECT r.reservation_id, r.start_time, r.end_time, r.status,
               u.first_name, u.last_name, s.spot_label, l.lot_name
        FROM reservations r
        JOIN users u ON r.user_id = u.user_id
        JOIN spots s ON r.spot_id = s.spot_id
        JOIN lots l ON s.lot_id = l.lot_id
        WHERE r.status IN ('Pending', 'Active')
        ORDER BY r.start_time
        LIMIT 8
        """
    )
    return render_template(
        "dashboard.html",
        lot_availability=lot_availability,
        active_permits=active_permits,
        overdue=overdue,
        upcoming_reservations=upcoming_reservations,
    )
