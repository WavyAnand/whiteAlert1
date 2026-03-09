# WhiteAlert SaaS Platform - Local Development Setup

## Quick Start Guide

Follow these steps to run the platform locally on your machine.

### Prerequisites
- Node.js 18+ 
- Docker and Docker Compose
- npm or yarn

### Step 1: Install Backend Dependencies

```bash
cd backend
npm install
cd ..
```

### Step 2: Install Frontend Dependencies

```bash
cd frontend
npm install
cd ..
```

### Step 3: Start Services (Docker)

```bash
docker-compose up -d
```

This starts PostgreSQL on port 5432 and Redis on port 6379.

### Step 4: Initialize Database

Wait 10 seconds for PostgreSQL to start, then:

```bash
PGPASSWORD=password psql -h localhost -p 5432 -U postgres -d whitealert -f backend/database/schema.sql
```

Or if psql is not installed, use Docker:

```bash
docker exec whitealert1-postgres-1 psql -U postgres -d whitealert -f /docker-entrypoint-initdb.d/schema.sql
```

### Step 5: Start Backend Server

```bash
cd backend
npm run dev
```

Server will run on http://localhost:5000

### Step 6: Start Frontend (New Terminal)

```bash
cd frontend
npm run dev
```

Frontend will run on http://localhost:3000

### Step 7: Access the Application

Open your browser and go to:
```
http://localhost:3000
```

## Troubleshooting

### Port Already in Use
If you get "Address already in use", kill the process:
```bash
# For port 5000 (backend)
lsof -ti:5000 | xargs kill -9

# For port 3000 (frontend)
lsof -ti:3000 | xargs kill -9
```

### Database Connection Issues
Check PostgreSQL is running:
```bash
docker logs whitealert1-postgres-1
```

### Clear Everything and Start Fresh
```bash
docker-compose down -v
docker-compose up -d
```

## Architecture Overview
- **Backend**: Node.js + Express + Socket.io on port 5000
- **Frontend**: React + Vite on port 3000
- **Database**: PostgreSQL on port 5432
- **Cache**: Redis on port 6379