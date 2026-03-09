# WhiteAlert1 - Multi-Tenant SaaS Platform

Complete architecture and working implementation of a multi-tenant SaaS platform with real-time chat, ticket management, QA workflows, and GitLab integration.

## 📚 Documentation

- **[Database Schema](DATABASE_SCHEMA.md)** ⭐ - Complete PostgreSQL schema with 19 tables, relationships, ER diagram, and multi-tenancy design
- **[System Architecture](architecture_design.md)** - High-level design, technology stack, data flow diagrams
- **[Features Breakdown](features_breakdown.md)** - Module dependencies, prioritization, development roadmap
- **[Setup Guide](SETUP.md)** - Local development environment setup
- **[Testing Guide](TESTING_GUIDE.md)** - MVP feature testing walkthrough

## 🚀 Quick Start (5 minutes)

```bash
# 1. Start Docker services
docker-compose up -d

# 2. Install dependencies
cd backend && npm install && cd ../frontend && npm install

# 3. Initialize database
PGPASSWORD=password psql -h localhost -p 5432 -U postgres -d whitealert -f backend/database/schema.sql

# 4. Start servers in two terminals
# Terminal 1
cd backend && npm run dev

# Terminal 2  
cd frontend && npm run dev

# 5. Open http://localhost:3000
```

## 📊 Database Design - 19 Tables

**Multi-tenancy Foundation**: companies, users, departments, roles, permissions  
**Communication**: chat_rooms, messages, room_participants  
**Ticketing**: tickets, ticket_activities, ticket_gitlab_mappings  
**QA System**: qa_reviews, qa_validation_rules  
**Support**: notifications, gitlab_configurations, audit_logs, files  

**[See complete schema with ER diagram →](DATABASE_SCHEMA.md)**

## ✨ Core Features

### Phase 1 (MVP - Complete ✅)
- ✅ Multi-company registration & authentication
- ✅ Real-time chat with WebSockets
- ✅ Multi-tenant data isolation
- ✅ Role-based dashboards
- ✅ User management

### Phase 2 (In Progress 🔄)
- 🚧 Ticket creation from chat
- 🚧 QA validation workflows
- 🚧 GitLab bidirectional sync
- 🚧 Advanced analytics

## 🔧 Technology Stack

| Layer | Technology |
|-------|----------|
| Frontend | React 18 + TypeScript + Material-UI + Vite |
| Backend | Node.js + Express.js + Socket.io |
| Database | PostgreSQL 15 + Redis 7 |
| Real-time | WebSocket via Socket.io |
| Infrastructure | Docker Compose + Kubernetes ready |