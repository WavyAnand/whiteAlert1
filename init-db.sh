#!/bin/bash

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 10

echo "Initializing database..."

# Run the schema
PGPASSWORD=password psql -h localhost -p 5432 -U postgres -d whitealert -f backend/database/schema.sql

echo "Database initialized successfully!"