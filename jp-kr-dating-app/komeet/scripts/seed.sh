#!/bin/bash

# This script seeds the database with initial data.

# Load environment variables
source .env

# Database connection parameters
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-komeet}
DB_USER=${DB_USER:-user}
DB_PASSWORD=${DB_PASSWORD:-password}

# Seed data
echo "Seeding database..."

# Example SQL commands to insert initial data
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME <<EOF
INSERT INTO users (name, age, preferences) VALUES
('Alice', 25, 'likes hiking, reading'),
('Bob', 30, 'enjoys cooking, traveling'),
('Charlie', 28, 'loves music, sports');
EOF

echo "Database seeded successfully."