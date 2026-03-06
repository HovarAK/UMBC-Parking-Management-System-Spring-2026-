# UMBC-Parking-Management-System-Spring-2026-

## Overview

The UMBC Parking Management System is a database-focused project designed to support campus parking operations through centralized data management in PostgreSQL. The long-term goal of the system is to manage users, roles, permits, vehicles, parking lots, parking spaces, reservations, and tickets in a structured and scalable way.

At the current stage, this repository focuses on the PostgreSQL database layer, SQL schema development, seed data, and local containerized setup using Podman Compose or Docker Compose. The project is currently SQL-first, but it is structured so that a Python application layer can be added in the future.

This setup allows contributors to run the database locally in a containerized environment instead of manually installing and configuring PostgreSQL on their machine.

## Project Structure

```text
UMBC-Parking-Management-System-Spring-2026-/
├── compose.yaml
├── .env
├── .env.example
├── .gitignore
├── README.md
└── sql/
    ├── schema.sql
    ├── seed.sql
    └── queries.sql
```

## Setup

### A) Downloading the REPO

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

### B) Setting the ENVIRONMENT variables

Create a `.env` file in the root of the project:

```bash
cp .env.example .env
```

If `cp` is not available in your shell, create `.env` manually and copy the contents from `.env.example`.

With the `.env` file, you can modify private variables such as:

```env
DB_NAME=umbc_parking
DB_USER=postgres
DB_PASSWORD=change_me
DB_PORT=5432

PGADMIN_EMAIL=admin@umbc.edu
PGADMIN_PASSWORD=change_me_too
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

Start the containers with Podman Compose:

```bash
podman compose up -d
```

Start the containers with Docker Compose:

```bash
docker compose up -d
```

This project uses named volumes for PostgreSQL and pgAdmin data persistence. The PostgreSQL data is stored through this named volume:

```yaml
- postgres_data:/var/lib/postgresql/data
```

This means PostgreSQL writes its database files inside the container at `/var/lib/postgresql/data`, while the data itself is stored in a container-managed named volume.

The SQL initialization scripts are mounted with:

```yaml
- ./sql:/docker-entrypoint-initdb.d
```

This allows PostgreSQL initialization scripts to run automatically when the database is created for the first time.

## Connection Instructions

### A) Connect directly with `psql`

You can connect directly to PostgreSQL from your machine with `psql`.

```bash
psql -h localhost -p 5432 -U postgres -d umbc_parking
```

Use the following values:

* Host: `localhost`
* Port: value of `DB_PORT`
* Database: value of `DB_NAME`
* Username: value of `DB_USER`
* Password: value of `DB_PASSWORD`

If your `.env` values are different, replace them accordingly.

### B) Connect using pgAdmin

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
* Username: value of `DB_USER`
* Password: value of `DB_PASSWORD`

Use `db` as the host in pgAdmin because pgAdmin runs in a separate container and connects to PostgreSQL through the internal Compose network.

### C) Disconnecting / Stopping Container

To stop the running containers with Podman Compose:

```bash
podman compose down
```

To stop the running containers with Docker Compose:

```bash
docker compose down
```

To stop a container without removing it, you can also use:

Podman:

```bash
podman stop umbc_parking_db
podman stop umbc_parking_pgadmin
```

Docker:

```bash
docker stop umbc_parking_db
docker stop umbc_parking_pgadmin
```

Stopping or removing the containers does not automatically delete your database data when using named volumes. The data remains stored in the `postgres_data` volume unless you explicitly remove that volume.
