#!/bin/bash

# Navigate to the backend directory
cd ../backend

# Run Prisma migrations
npx prisma migrate deploy

# Seed the database
npx prisma db seed

echo "Migration and seeding completed."