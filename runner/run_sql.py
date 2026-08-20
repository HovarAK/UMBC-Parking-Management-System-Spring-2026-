import os
import time
import psycopg2


DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "parkingdb")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

# SQL_FILES is a comma-separated, ORDERED list of files to run as a single
# init pass, e.g. "/app/sql/createDDL.sql,/app/sql/loadAll.sql,/app/sql/indexAll.sql".
# Before running, the sequence is skipped entirely if SENTINEL_TABLE already
# exists, so re-running the container against an already-initialized database
# (e.g. a second `docker compose up -d` against the same named volume) is a
# harmless no-op instead of failing on "relation already exists".
#
# SQL_FILE (singular) is kept for ad hoc single-file runs (e.g. manually
# re-running indexAll.sql) and always executes unconditionally, without the
# skip check.
SQL_FILES = os.getenv("SQL_FILES", "")
SQL_FILE = os.getenv("SQL_FILE", "")

SENTINEL_TABLE = os.getenv("SENTINEL_TABLE", "users")


def connect():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )


def wait_for_db(max_tries=30, delay=2):
    for attempt in range(1, max_tries + 1):
        try:
            conn = connect()
            conn.close()
            print("Database is ready.")
            return
        except psycopg2.OperationalError as e:
            print(f"[{attempt}/{max_tries}] Waiting for database: {e}")
            time.sleep(delay)

    raise RuntimeError("Could not connect to database.")


def schema_already_initialized():
    conn = connect()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT EXISTS (
                    SELECT 1
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                      AND table_name = %s
                )
                """,
                (SENTINEL_TABLE,),
            )
            row = cur.fetchone()
            return bool(row and row[0])
    finally:
        conn.close()


def run_sql_file(path):
    with open(path, "r", encoding="utf-8") as f:
        sql = f.read()

    conn = connect()
    conn.autocommit = True

    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        print(f"Successfully ran {path}")
    finally:
        conn.close()


def run_init_sequence(paths):
    if schema_already_initialized():
        print(
            f"Schema already initialized (table '{SENTINEL_TABLE}' exists). "
            "Skipping init sequence."
        )
        return

    for path in paths:
        run_sql_file(path)


if __name__ == "__main__":
    wait_for_db()

    if SQL_FILES:
        file_list = [p.strip() for p in SQL_FILES.split(",") if p.strip()]
        run_init_sequence(file_list)
    elif SQL_FILE:
        run_sql_file(SQL_FILE)
    else:
        raise RuntimeError(
            "Set SQL_FILES (ordered, comma-separated list) or SQL_FILE "
            "(single file) in the environment before running this script."
        )
