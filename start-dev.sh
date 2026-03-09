#!/bin/bash

# Convenient script to start backend and frontend development servers

echo "Starting Docker services..."
docker-compose up -d
sleep 5

echo "Installing dependencies if necessary..."
cd backend && npm install || true
cd ../frontend && npm install || true
cd ..

echo "Starting backend server on port 5000..."
cd backend
npm run dev &
BACKEND_PID=$!
cd ..

sleep 3

echo "Starting frontend server on port 3000..."
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

echo "Development servers launched."
echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"
echo "Open http://localhost:3000 to view the app."

echo "Press Ctrl+C to stop."
wait