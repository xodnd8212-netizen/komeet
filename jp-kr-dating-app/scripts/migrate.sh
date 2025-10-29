#!/bin/bash

# This script is used to run database migrations for the JP-KR Dating App.

set -e

# Navigate to the server directory
cd server

# Run Prisma migrations
npx prisma migrate deploy

echo "Database migrations completed successfully."