#!/bin/bash

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
while ! pg_isready -h localhost -p 5432 -U postgres; do
  sleep 1
done

echo "PostgreSQL is ready. Initializing database..."

# Run the schema
psql -h localhost -p 5432 -U postgres -d whitealert -f backend/database/schema.sql

echo "Database initialized successfully!"