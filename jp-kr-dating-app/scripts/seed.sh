#!/bin/bash

# This script seeds the database with initial data.

# Load environment variables
source .env

# Define the database seeding command
SEED_COMMAND="npx prisma db seed"

# Execute the seeding command
echo "Seeding the database..."
$SEED_COMMAND

if [ $? -eq 0 ]; then
  echo "Database seeded successfully."
else
  echo "Failed to seed the database."
  exit 1
fi