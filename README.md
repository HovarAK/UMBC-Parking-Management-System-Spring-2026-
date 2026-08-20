# UMBC-Parking-Management-System-Spring-2026-

## Overview

The UMBC Parking Management System is a database-focused project designed to support campus parking operations through centralized data management in PostgreSQL. The long-term goal of the system is to manage users, roles, permits, vehicles, parking lots, parking spaces, reservations, parking sessions, sensor events, and tickets in a structured and scalable way.

At the current stage, this repository focuses on the PostgreSQL database layer, SQL schema development, seed data, query testing, indexing, and local containerized setup using Podman Compose or Docker Compose. The project is currently SQL-first, but it is structured so that a Python application layer can be added in the future.

This setup allows contributors to run the database locally in a containerized environment instead of manually installing and configuring PostgreSQL on their machine.

> Note: The sample data in this repository (lot names, permit types, users, etc.) is illustrative and fictional. It is not sourced from or verified against UMBC's actual parking structure.

## Project Structure

```text
UMBC-Parking-Management-System-Spring-2026-/
├── docker-compose.yml
├── LICENSE
├── README.md
├── .env.example
├── runner/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── run_sql.py
└── sql/
    ├── createDDL.sql
    ├── dropDDL.sql
    ├── loadAll.sql
    ├── queryAll.sql
    ├── indexAll.sql
    ├── transaction.sql
    └── smoke_test.sql
```

Main SQL files (in `sql/`):

* `dropDDL.sql` drops the existing database objects so the database can be reset.
* `createDDL.sql` creates the schema, tables, constraints, functions, triggers, procedures, and views.
* `loadAll.sql` inserts sample data into the database.
* `queryAll.sql` runs the project queries used to demonstrate joins, aggregation, subqueries, and reporting.
* `indexAll.sql` creates indexes used for performance testing.
* `transaction.sql` sets up and documents the concurrency test for double booking and prevention.
* `smoke_test.sql` is currently an empty placeholder reserved for future automated smoke tests.

`runner/` contains a small Python bootstrap container that waits for PostgreSQL to become available and then executes a single SQL file (`run_sql.py`) — it is not an application/API layer.

## Setup

### A) Downloading the Repository

Clone the repository locally with Git.

If using HTTPS:

```bash
git clone https://github.com/HovarAK/UMBC-Parking-Management-System-Spring-2026-.git
cd UMBC-Parking-Management-System-Spring-2026-
```

If using SSH:

```bash
git clone git@github.com:HovarAK/UMBC-Parking-Management-System-Spring-2026-.git
cd UMBC-Parking-Management-System-Spring-2026-
```

You can also download the repository as a ZIP file from GitHub and extract it manually.

### B) Setting the Environment Variables

Create a `.env` file in the root of the project:

```bash
cp .env.example .env
```

If `cp` is not available in your shell, create `.env` manually and copy the contents from `.env.example`.

Recommended `.env` values for this project:

```env
DB_NAME=umbc_parking
DB_USER=admin
DB_PASSWORD=password
DB_PORT=5432

PGADMIN_EMAIL=admin@umbc.edu
PGADMIN_PASSWORD=password111
PGADMIN_PORT=5050
```

Environment variable meanings:

* `DB_NAME` is the PostgreSQL database name.
* `DB_USER` is the PostgreSQL username.
* `DB_PASSWORD` is the PostgreSQL password.
* `DB_PORT` is the host machine port used to access PostgreSQL.
* `PGADMIN_EMAIL` is the login email for pgAdmin.
* `PGADMIN_PASSWORD` is the login password for pgAdmin.
* `PGADMIN_PORT` is the host machine port used to access pgAdmin in the browser.

## Starting the Containers

### Podman Compose

Start the containers with Podman Compose:

```bash
podman compose up -d
```

Check that the containers are running:

```bash
podman ps
```

You should see a PostgreSQL container named something like `umbc_parking_db` and a pgAdmin container named something like `umbc_parking_pgadmin`.

### Docker Compose

Start the containers with Docker Compose:

```bash
docker compose up -d
```

Check that the containers are running:

```bash
docker ps
```

## Running the SQL Files from the Terminal

Run the commands below from the same folder that contains the `.sql` files (`sql/`).

The recommended order is:

1. `dropDDL.sql`
2. `createDDL.sql`
3. `loadAll.sql`
4. `queryAll.sql`
5. `indexAll.sql`
6. `transaction.sql`

### Podman Commands

Reset the database:

```bash
podman exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/dropDDL.sql
```

Create the schema:

```bash
podman exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/createDDL.sql
```

Load the sample data:

```bash
podman exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/loadAll.sql
```

Run the project queries:

```bash
podman exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/queryAll.sql
```

Create indexes for performance testing:

```bash
podman exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/indexAll.sql
```

Run the transaction setup file:

```bash
podman exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/transaction.sql
```

> Note: `transaction.sql` contains Session 1 and Session 2 code blocks for the concurrency test. Those blocks should be copied and run manually in two separate pgAdmin Query Tool windows so the blocked transaction behavior can be observed.

### Docker Commands

Reset the database:

```bash
docker exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/dropDDL.sql
```

Create the schema:

```bash
docker exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/createDDL.sql
```

Load the sample data:

```bash
docker exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/loadAll.sql
```

Run the project queries:

```bash
docker exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/queryAll.sql
```

Create indexes for performance testing:

```bash
docker exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/indexAll.sql
```

Run the transaction setup file:

```bash
docker exec -i -e PGPASSWORD=password umbc_parking_db psql -v ON_ERROR_STOP=1 -U admin -d umbc_parking < sql/transaction.sql
```

## If the Container Name Is Different

If `umbc_parking_db` is not the actual PostgreSQL container name, list your container names.

Podman:

```bash
podman ps --format "{{.Names}}"
```

Docker:

```bash
docker ps --format "{{.Names}}"
```

Then replace `umbc_parking_db` in the commands with the correct container name.

## Verifying That the Data Loaded Correctly

After running `dropDDL.sql`, `createDDL.sql`, and `loadAll.sql`, connect to PostgreSQL.

### Podman

```bash
podman exec -it -e PGPASSWORD=password umbc_parking_db psql -U admin -d umbc_parking
```

### Docker

```bash
docker exec -it -e PGPASSWORD=password umbc_parking_db psql -U admin -d umbc_parking
```

Inside `psql`, list the tables:

```sql
\dt public.*
```

You can also run this SQL query in pgAdmin or `psql`:

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

Check row counts:

```sql
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM public.users
UNION ALL
SELECT 'vehicles', COUNT(*) FROM public.vehicles
UNION ALL
SELECT 'parkingtypes', COUNT(*) FROM public.parkingtypes
UNION ALL
SELECT 'lots', COUNT(*) FROM public.lots
UNION ALL
SELECT 'spots', COUNT(*) FROM public.spots
UNION ALL
SELECT 'permits', COUNT(*) FROM public.permits
UNION ALL
SELECT 'reservations', COUNT(*) FROM public.reservations
UNION ALL
SELECT 'parkingsessions', COUNT(*) FROM public.parkingsessions
UNION ALL
SELECT 'tickets', COUNT(*) FROM public.tickets
UNION ALL
SELECT 'sensorevents', COUNT(*) FROM public.sensorevents;
```

To exit `psql`, run:

```sql
\q
```

## Running the Concurrency Test in pgAdmin

The concurrency test in `transaction.sql` demonstrates a double-booking problem and then shows how `SELECT ... FOR UPDATE` prevents it.

To run the test:

1. Run `dropDDL.sql`, `createDDL.sql`, and `loadAll.sql`.
2. Run the setup portion of `transaction.sql`.
3. Open pgAdmin.
4. Open the `umbc_parking` database.
5. Open two separate Query Tool tabs or windows.
6. Use one tab as Session 1 and the other tab as Session 2.
7. Copy the Session 1 code block from `transaction.sql` into the first Query Tool tab.
8. Copy the Session 2 code block from `transaction.sql` into the second Query Tool tab.
9. Run Session 1 first, then quickly run Session 2 while Session 1 is sleeping.

The unsafe test should show two reservations for the same spot and time. The safe test should show Session 2 blocking and then failing after Session 1 commits.

## Connection Instructions

### A) Connect Directly with `psql`

You can connect directly to PostgreSQL from your machine with `psql`:

```bash
psql -h localhost -p 5432 -U admin -d umbc_parking
```

Use the following values:

* Host: `localhost`
* Port: value of `DB_PORT`
* Database: value of `DB_NAME`
* Username: value of `DB_USER`
* Password: value of `DB_PASSWORD`

If your `.env` values are different, replace them accordingly.

### B) Connect Using pgAdmin

If the `pgadmin` service is running, open your browser and go to:

```text
http://localhost:5050
```

If you changed `PGADMIN_PORT`, use that port instead.

Log in using:

* Email: value of `PGADMIN_EMAIL`
* Password: value of `PGADMIN_PASSWORD`

After logging in, add a new PostgreSQL server in pgAdmin using the following settings:

* Name: `UMBC Parking DB`
* Host: `db`
* Port: `5432`
* Maintenance database: `umbc_parking`
* Username: value of `DB_USER`
* Password: value of `DB_PASSWORD`

Use `db` as the host in pgAdmin because pgAdmin runs in a separate container and connects to PostgreSQL through the internal Compose network.

### C) How to View the Database in pgAdmin

Once the server has been added successfully:

1. Expand **Servers** in the left panel.
2. Expand **UMBC Parking DB**.
3. Expand **Databases**.
4. Select the `umbc_parking` database.
5. Expand **Schemas**.
6. Expand **public**.
7. Expand **Tables**.

This displays the tables created by `createDDL.sql`, such as `users`, `vehicles`, `parkingtypes`, `lots`, `spots`, `permits`, `reservations`, `parkingsessions`, `tickets`, and `sensorevents`.

### D) How to Open the Query Tool in pgAdmin

To run SQL commands inside pgAdmin:

1. In the left panel, right-click the `umbc_parking` database.
2. Select **Query Tool**.
3. Paste SQL commands into the editor.
4. Click the **Execute** button to run the query.

## Stopping or Resetting Containers

To stop the running containers with Podman Compose:

```bash
podman compose down
```

To stop the running containers with Docker Compose:

```bash
docker compose down
```

To remove the containers and the database volume for a completely fresh database, run:

### Podman

```bash
podman compose down -v
```

### Docker

```bash
docker compose down -v
```

Use `down -v` carefully because it deletes the PostgreSQL volume and removes the stored database data. Plain `down` (without `-v`) does not delete the named volume — your data persists across `up`/`down` cycles unless you explicitly remove the volume.
