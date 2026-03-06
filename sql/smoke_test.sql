--Create the roles table to store parking permit groups, and role names.
CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    permit_group VARCHAR(1) UNIQUE NOT NULL,
    role_name VARCHAR(30) UNIQUE NOT NULL
);

-- Create the users table to store user account information.
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    role_id INT NOT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(role_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert predined parking role and permit group data into the roles table.
INSERT INTO roles (permit_group, role_name)
VALUES
    ('A','Commuter Student'),
    ('B','Walker Community Resident'),
    ('C','Residential Student'),
    ('D','Faculty/Staff'),
    ('E','Gated Faculty/Staff');

-- Display all permit groups and role names.
SELECT r.permit_group, r.role_name
FROM roles r;
