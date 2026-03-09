#!/bin/bash

# WhiteAlert Platform - Development Server Launcher
# This script starts all required services

cd /workspaces/whiteAlert1

echo "======================================"
echo "WhiteAlert SaaS Platform"
echo "Development Environment"
echo "======================================"
echo ""

# Step 1: Check if Docker services are running
echo "Checking Docker services..."
docker-compose ps > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Starting Docker services..."
  docker-compose up -d
  sleep 10
fi

echo "✓ Docker services running"
echo ""

# Step 2: Install dependencies if needed
if [ ! -d "backend/node_modules" ]; then
  echo "Installing backend dependencies..."
  cd backend
  npm install
  cd ..
fi

if [ ! -d "frontend/node_modules" ]; then
  echo "Installing frontend dependencies..."
  cd frontend
  npm install
  cd ..
fi

echo "✓ Dependencies installed"
echo ""

# Step 3: Initialize database if needed
echo "Initializing database..."
sleep 3
PGPASSWORD=password psql -h localhost -p 5432 -U postgres -d whitealert -c "SELECT 1" > /dev/null 2>&1
if [ $? -eq 0 ]; then
  PGPASSWORD=password psql -h localhost -p 5432 -U postgres -d whitealert -c "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name='companies')" | grep -q "t$"
  if [ $? -ne 0 ]; then
    echo "Creating database schema..."
    PGPASSWORD=password psql -h localhost -p 5432 -U postgres -d whitealert -f backend/database/schema.sql
  fi
  echo "✓ Database ready"
else
  echo "✗ Could not connect to PostgreSQL"
  exit 1
fi

echo ""
echo "======================================"
echo "Starting Services..."
echo "======================================"
echo ""

# Start backend
echo "Starting Backend Server (Port 5000)..."
cd backend
npm run dev &
BACKEND_PID=$!
cd ..
sleep 3

# Start frontend
echo "Starting Frontend Server (Port 3000)..."
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..
sleep 3

echo ""
echo "======================================"
echo "✓ Platform is Ready!"
echo "======================================"
echo ""
echo "Frontend: http://localhost:3000"
echo "Backend:  http://localhost:5000"
echo ""
echo "Default Credentials:"
echo "  Email: demo@company.com"
echo "  Password: password123"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for interrupt
wait