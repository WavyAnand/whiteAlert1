#!/bin/bash
# This script initializes the database
# Run this after docker-compose up -d

echo "Waiting 15 seconds for PostgreSQL to start..."
for i in {1..15}; do
  echo -n "."
  sleep 1
done
echo ""

echo "Initializing database with schema..."
PGPASSWORD=password psql -h localhost -p 5432 -U postgres -d whitealert -f backend/database/schema.sql

if [ $? -eq 0 ]; then
  echo "✓ Database initialized successfully!"
else
  echo "✗ Database initialization failed. Make sure PostgreSQL is running."
fi