"""Database access layer.

Deliberately built on SQLAlchemy Core, not the ORM. The schema's actual
business rules -- double-booking prevention, permit overlap checks, spot
status bookkeeping, fine-schedule lookups -- already live in the database
as functions, procedures, constraints, and triggers (see
sql/createDDL.sql). This module's job is to call that logic, not
re-derive it in Python.
"""
import os
from contextlib import contextmanager

from sqlalchemy import create_engine, text
from sqlalchemy.exc import DBAPIError, OperationalError, ProgrammingError

DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "umbc_parking")
DB_USER = os.getenv("DB_USER", "admin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")

DATABASE_URL = (
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# pool_pre_ping so a stale/dropped connection (e.g. the db container
# restarted) is detected and replaced instead of surfacing as a confusing
# error on whatever request happens to reuse it next.
engine = create_engine(DATABASE_URL, pool_pre_ping=True, future=True)


class DatabaseUnavailable(Exception):
    """Raised when the database can't be reached at all."""


class AppError(Exception):
    """A business-rule error raised by a SQL function/procedure (RAISE
    EXCEPTION ...) or a constraint violation, surfaced with a clean
    message so the UI can show something meaningful instead of a raw
    driver traceback."""


@contextmanager
def get_connection():
    try:
        conn = engine.connect()
    except OperationalError as exc:
        raise DatabaseUnavailable(str(exc)) from exc
    try:
        yield conn
    finally:
        conn.close()


def run_query(sql, params=None):
    """Run a SELECT and return a list of dict rows."""
    with get_connection() as conn:
        try:
            result = conn.execute(text(sql), params or {})
        except OperationalError as exc:
            raise DatabaseUnavailable(str(exc)) from exc
        except ProgrammingError as exc:
            # Most likely: the schema hasn't finished loading yet (e.g. the
            # web container came up before db-runner finished seeding).
            # Treated the same as "database unavailable" rather than a raw
            # 500, since from the user's point of view it's the same
            # "try again in a moment" situation.
            raise DatabaseUnavailable(str(exc)) from exc
        return [dict(row._mapping) for row in result]


def run_write(sql, params=None):
    """Run an INSERT/UPDATE/DELETE in its own transaction. Raises
    AppError with a clean message on constraint violations (FK
    violations from ON DELETE RESTRICT, CHECK failures, the
    reservations EXCLUDE constraint, etc.)."""
    with get_connection() as conn:
        try:
            with conn.begin():
                conn.execute(text(sql), params or {})
        except OperationalError as exc:
            raise DatabaseUnavailable(str(exc)) from exc
        except DBAPIError as exc:
            raise AppError(_clean_db_error(exc)) from exc


def call_scalar_function(sql, params=None):
    """Call a SQL function that RETURNS a scalar (make_reservation,
    issue_permit) inside its own transaction, and return that scalar.
    Raises AppError with the function's RAISE EXCEPTION message on
    failure, instead of a raw traceback."""
    with get_connection() as conn:
        try:
            with conn.begin():
                result = conn.execute(text(sql), params or {})
                return result.scalar_one()
        except OperationalError as exc:
            raise DatabaseUnavailable(str(exc)) from exc
        except DBAPIError as exc:
            raise AppError(_clean_db_error(exc)) from exc


def call_procedure(sql, params=None):
    """Call a SQL procedure (CALL ...) inside its own transaction."""
    with get_connection() as conn:
        try:
            with conn.begin():
                conn.execute(text(sql), params or {})
        except OperationalError as exc:
            raise DatabaseUnavailable(str(exc)) from exc
        except DBAPIError as exc:
            raise AppError(_clean_db_error(exc)) from exc


def _clean_db_error(exc):
    """Pull the human-readable message out of a psycopg2 error (a RAISE
    EXCEPTION's text, or a constraint-violation's primary message)
    instead of the full driver/traceback text."""
    orig = getattr(exc, "orig", None)
    if orig is not None:
        diag = getattr(orig, "diag", None)
        if diag is not None and diag.message_primary:
            return diag.message_primary
        return str(orig).strip()
    return str(exc)
