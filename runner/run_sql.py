import os
import time
import psycopg2


DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "parkingdb")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
SQL_FILE = os.getenv("SQL_FILE", "/app/sql/createDDL.sql")


def wait_for_db(max_tries=30, delay=2):
    for attempt in range(1, max_tries + 1):
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                port=DB_PORT,
                dbname=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD,
            )
            conn.close()
            print("Database is ready.")
            return
        except psycopg2.OperationalError as e:
            print(f"[{attempt}/{max_tries}] Waiting for database: {e}")
            time.sleep(delay)

    raise RuntimeError("Could not connect to database.")


def run_sql_file():
    with open(SQL_FILE, "r", encoding="utf-8") as f:
        sql = f.read()

    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )
    conn.autocommit = True

    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        print(f"Successfully ran {SQL_FILE}")
    finally:
        conn.close()


if __name__ == "__main__":
    wait_for_db()
    run_sql_file()
