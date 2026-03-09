#!/bin/bash

echo "=========================================="
echo "WhiteAlert SaaS Platform - Local Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Starting Docker Services...${NC}"
docker-compose up -d
sleep 5

echo -e "${BLUE}Step 2: Installing Backend Dependencies...${NC}"
cd backend
npm install
cd ..

echo -e "${BLUE}Step 3: Installing Frontend Dependencies...${NC}"
cd frontend
npm install
cd ..

echo -e "${BLUE}Step 4: Initializing Database...${NC}"
sleep 10
PGPASSWORD=password psql -h localhost -p 5432 -U postgres -d whitealert -c "CREATE TABLE IF NOT EXISTS companies (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, domain VARCHAR(255) UNIQUE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}To start the platform:${NC}"
echo ""
echo -e "${BLUE}Terminal 1 - Backend:${NC}"
echo "cd /workspaces/whiteAlert1/backend && npm run dev"
echo ""
echo -e "${BLUE}Terminal 2 - Frontend:${NC}"
echo "cd /workspaces/whiteAlert1/frontend && npm run dev"
echo ""
echo -e "${GREEN}Then open: http://localhost:3000${NC}"
echo ""