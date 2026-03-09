# WhiteAlert SaaS Platform - Database Schema Documentation

## Overview

This document describes the complete PostgreSQL database schema for WhiteAlert, a multi-tenant SaaS platform with chat, ticketing, QA workflows, and GitLab integration.

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MULTI-TENANCY FOUNDATION                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────┐                                                   │
│  │   COMPANIES      │  (Root tenant entity)                            │
│  ├──────────────────┤                                                   │
│  │ id (PK)          │                                                   │
│  │ name             │                                                   │
│  │ domain           │                                                   │
│  │ subscription_tier│                                                   │
│  │ created_at       │                                                   │
│  └────────┬─────────┘                                                   │
│           │                                                             │
│           ├─────────────────────────┬──────────────┬────────────┐      │
│           │                         │              │            │      │
│    ┌──────▼─────┐        ┌──────────▼──┐  ┌─────────▼──┐  ┌────▼──┐  │
│    │ USERS      │        │ DEPARTMENTS │  │ CHAT_ROOMS │  │TICKETS│  │
│    └────────────┘        └─────────────┘  └────────────┘  └───────┘  │
│                                                                        │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                     ACCESS CONTROL & AUTHORIZATION                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────┐         ┌──────────────────┐                    │
│  │ ROLES            │◄───────►│ PERMISSIONS      │                    │
│  ├──────────────────┤  (M:M)  ├──────────────────┤                    │
│  │ id               │         │ id               │                    │
│  │ company_id (FK)  │         │ name             │                    │
│  │ name             │         │ category         │                    │
│  │ is_system        │         └──────────────────┘                    │
│  └────────┬─────────┘                                                  │
│           │                                                            │
│           │ 1:M                                                        │
│           │                                                            │
│           └──────────────┐                                             │
│                          │                                             │
│                   ┌──────▼────────┐                                   │
│                   │ USERS has ROLE│                                   │
│                   └────────────────┘                                   │
│                                                                        │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      CHAT & MESSAGING SYSTEM                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────┐        ┌──────────────────────┐              │
│  │ CHAT_ROOMS          │        │ CHAT_ROOM_PARTICIPANTS              │
│  ├─────────────────────┤        ├──────────────────────┤              │
│  │ id (PK)             │◄───────│ room_id (FK)         │  (M:M)      │
│  │ company_id (FK)     │        │ user_id (FK)         │              │
│  │ name                │  1:M   │ role                 │              │
│  │ type (direct/group) │        │ joined_at            │              │
│  │ created_by (FK)     │        └──────────────────────┘              │
│  └────────┬────────────┘                                               │
│           │                                                            │
│           │ 1:M                                                        │
│           │                                                            │
│    ┌──────▼─────────────┐                                              │
│    │ MESSAGES            │                                              │
│    ├─────────────────────┤                                              │
│    │ id (PK)             │                                              │
│    │ room_id (FK)        │                                              │
│    │ user_id (FK)        │                                              │
│    │ company_id (FK)     │                                              │
│    │ content             │                                              │
│    │ created_at          │                                              │
│    └────────┬────────────┘                                              │
│             │                                                          │
│             │ 1:M                                                      │
│             │                                                          │
│      ┌──────▼──────────────────┐                                       │
│      │ MESSAGE_REACTIONS        │                                       │
│      ├──────────────────────────┤                                       │
│      │ message_id (FK)          │                                       │
│      │ user_id (FK)             │                                       │
│      │ emoji                    │                                       │
│      └──────────────────────────┘                                       │
│                                                                        │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                     TICKETING & LIFECYCLE SYSTEM                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────┐                                                │
│  │ TICKETS            │                                                │
│  ├────────────────────┤                                                │
│  │ id (PK)            │                                                │
│  │ company_id (FK)    │──┐                                             │
│  │ created_by (FK)    │  │                                             │
│  │ assigned_to (FK)   │  │                                             │
│  │ title              │  │                                             │
│  │ priority (H/M/L)   │  │                                             │
│  │ status             │  │  ┌──────────────────────┐                  │
│  │ chat_room_id (FK)  │  │  │ TICKET_COMMENTS      │                  │
│  │ gitlab_issue_id    │  └─►├──────────────────────┤                  │
│  │ created_at         │     │ ticket_id (FK)       │ 1:M             │
│  └────────┬───────────┘     │ user_id (FK)         │                  │
│           │                 │ content              │                  │
│           │                 │ is_internal          │                  │
│           │ 1:M             └──────────────────────┘                  │
│           │                                                            │
│    ┌──────▼──────────────────┐                                         │
│    │ TICKET_LIFECYCLE        │                                         │
│    ├─────────────────────────┤                                         │
│    │ ticket_id (FK)          │                                         │
│    │ user_id (FK)            │                                         │
│    │ action (created, moved) │                                         │
│    │ field_name              │                                         │
│    │ old_value               │                                         │
│    │ new_value               │                                         │
│    │ created_at              │                                         │
│    └─────────────────────────┘                                         │
│                                                                        │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    QA VALIDATION & APPROVAL WORKFLOW                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────┐                                                │
│  │ QA_RULES           │                                                │
│  ├────────────────────┤                                                │
│  │ id (PK)            │                                                │
│  │ company_id (FK)    │                                                │
│  │ name               │                                                │
│  │ rule_type          │                                                │
│  │ conditions (JSON)  │                                                │
│  └────────┬───────────┘                                                │
│           │                                                            │
│           │ M:1 (optional)                                             │
│           │                                                            │
│    ┌──────▼──────────────────┐        ┌──────────────────────┐       │
│    │ QA_VALIDATIONS          │        │ QA_APPROVALS         │       │
│    ├──────────────────────────┤        ├──────────────────────┤       │
│    │ id (PK)                  │◄──────►│ qa_validation_id(FK) │ 1:1  │
│    │ ticket_id (FK)           │        │ approver_id (FK)     │       │
│    │ qa_rule_id (FK)          │        │ status               │       │
│    │ status (pending/passed)  │        │ approved_at          │       │
│    │ reviewer_id (FK)         │        └──────────────────────┘       │
│    │ comments                 │                                        │
│    │ validation_data (JSON)   │                                        │
│    └──────────────────────────┘                                        │
│                                                                        │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      EXTERNAL INTEGRATIONS                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────┐        ┌──────────────────────┐               │
│  │ GITLAB_SYNCS       │        │ GITLAB_WEBHOOK_LOGS  │               │
│  ├────────────────────┤        ├──────────────────────┤               │
│  │ id (PK)            │◄───────│ sync_id (FK)         │ 1:M          │
│  │ company_id (FK)    │  M:1   │ event_type           │               │
│  │ project_id         │        │ webhook_payload(JSON)│               │
│  │ access_token       │        │ processed            │               │
│  │ sync_direction     │        └──────────────────────┘               │
│  │ last_sync_at       │                                                │
│  └────────────────────┘                                                │
│                                                                        │
│  Connections to Tickets:                                               │
│  - tickets.gitlab_issue_id (bidirectional sync)                        │
│  - tickets.gitlab_issue_url                                            │
│                                                                        │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    NOTIFICATIONS & PREFERENCES                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────┐                                              │
│  │ NOTIFICATION_TEMPLATES                                              │
│  ├──────────────────────┤                                              │
│  │ id (PK)              │                                              │
│  │ company_id (FK)      │                                              │
│  │ name                 │                                              │
│  │ template_type        │                                              │
│  │ body                 │                                              │
│  └────────┬─────────────┘                                              │
│           │ (referenced in generation)                                 │
│           │                                                            │
│    ┌──────▼─────────────────────┐        ┌──────────────────────┐    │
│    │ NOTIFICATIONS               │        │ NOTIFICATION_PREFS   │    │
│    ├─────────────────────────────┤        ├──────────────────────┤    │
│    │ id (PK)                     │        │ user_id (FK)         │    │
│    │ company_id (FK)             │        │ notification_type    │    │
│    │ user_id (FK)                │        │ email_enabled        │    │
│    │ related_ticket_id (FK)      │        │ push_enabled         │    │
│    │ related_message_id (FK)     │        │ sms_enabled          │    │
│    │ title                       │        └──────────────────────┘    │
│    │ content                     │                                     │
│    │ channels (JSON array)       │                                     │
│    │ is_read                     │                                     │
│    │ created_at                  │                                     │
│    └─────────────────────────────┘                                     │
│                                                                        │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    AUDIT LOG & FILE STORAGE                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────┐        ┌──────────────────────┐               │
│  │ AUDIT_LOGS         │        │ FILE_ATTACHMENTS     │               │
│  ├────────────────────┤        ├──────────────────────┤               │
│  │ id (PK)            │        │ id (PK)              │               │
│  │ company_id (FK)    │        │ company_id (FK)      │               │
│  │ user_id (FK)       │        │ uploaded_by (FK)     │               │
│  │ action              │        │ file_name            │               │
│  │ resource_type      │        │ storage_path         │               │
│  │ resource_id        │        │ storage_provider     │               │
│  │ old_values (JSON)  │        │ related_ticket_id(FK)│               │
│  │ new_values (JSON)  │        │ related_message_id(FK)               │
│  │ ip_address         │        │ virus_scanned        │               │
│  │ created_at         │        │ scan_result          │               │
│  └────────────────────┘        └──────────────────────┘               │
│                                                                        │
└─────────────────────────────────────────────────────────────────────────┘
```

## Table Relationships Summary

### One-to-Many (1:M)
- Companies → Users
- Companies → Departments
- Companies → Chat Rooms
- Companies → Tickets
- Departments → Users
- Departments → Tickets
- Users → Tickets (created_by)
- Users → Tickets (assigned_to)
- Chat Rooms → Chat Room Participants
- Chat Rooms → Messages
- Tickets → Ticket Comments
- Tickets → Ticket Lifecycle
- Tickets → QA Validations
- Tickets → QA Approvals
- Tickets → Notifications
- QA Rules → QA Validations
- Roles → Role Permissions

### Many-to-Many (M:M)
- Users ↔ Chat Rooms (via Chat Room Participants)
- Roles ↔ Permissions (via Role Permissions)
- Messages ↔ Users (reactions via Message Reactions)

### Foreign Key Constraints
All foreign keys use:
- ON DELETE CASCADE for dependent records (e.g., messages when chat room deleted)
- ON DELETE SET NULL for optional references (e.g., assigned_to when user deleted)

## Multi-Tenancy Architecture

### Isolation Strategy
- **Database Level**: Every table has `company_id` foreign key
- **Query Level**: All queries filter by company_id to ensure data isolation
- **Application Level**: Middleware validates user belongs to company_id being accessed

### Shared Tables
- `permissions` - System-wide permissions
- `roles` - Company-specific roles (users can't see other company's roles)
- `notification_templates` - Can be system or company-specific
- `audit_logs` - Company-isolated for security

## Key Indexes

**High-Priority Indexes** (created first):
- `users(company_id, email)` - Login queries
- `tickets(company_id, status)` - Dashboard filtering
- `messages(room_id, created_at DESC)` - Chat history
- `chat_room_participants(room_id, user_id)` - Room membership

**Performance Indexes**:
- `notifications(user_id, is_read)` - Unread counts
- `tickets(created_at DESC)` - Recent activity
- `ticket_lifecycle(created_at)` - Audit trails

## Views

### vw_active_users
Shows total active users per company.

### vw_open_tickets_by_priority
Aggregates open tickets grouped by priority (useful for dashboards).

### vw_unresolved_notifications
Shows pending notifications per user.

## Constraints & Validations

### Unique Constraints
- `users(company_id, email)` - Users per company must have unique emails
- `roles(company_id, name)` - Role names are unique per company
- `departments(company_id, name)` - Department names are unique per company
- `tickets(company_id, reference_number)` - Auto-incremented reference per company
- `gitlab_syncs(company_id, gitlab_project_id)` - One sync per project per company

### Data Types
- **IDs**: UUID for distributed systems
- **Timestamps**: TIMESTAMP for audit trails
- **JSON**: JSONB for flexible metadata and preferences
- **Money**: DECIMAL(10,2) for hours/costs
- **IP Addresses**: INET type for network addresses

## Scalability Considerations

1. **Partitioning**: Messages and Audit Logs tables can be partitioned by `created_at` for large volumes
2. **Archiving**: Closed tickets and old messages can be archived to separate schema
3. **Read Replicas**: Set up replicas for reporting and analytics
4. **Caching**: Frequently accessed data (users, roles, permissions) should be cached in Redis

## Security Notes

1. **Passwords**: Stored as `password_hash` - must be hashed with bcrypt/argon2
2. **Tokens**: `token_hash` in user_sessions - hashed for security
3. **GitLab Tokens**: `access_token_hash` - must be encrypted
4. **Sensitive Data**: Audit logs store PII - implement row-level security
5. **Audit Trail**: All changes logged in `audit_logs` and `ticket_lifecycle`

## Migration Strategy

When deploying to production:
1. Create tables in this order:
   - Core: companies, permissions
   - Users: users, roles, role_permissions
   - Organization: departments, users (update with dept)
   - Chat: chat_rooms, participants, messages
   - Ticketing: tickets, lifecycle
   - QA: qa_rules, validations
   - Integrations: gitlab_syncs, webhooks
   - Operations: notifications, audit_logs, files

2. Create indexes after all tables exist
3. Add views last
4. Implement row-level security (RLS) policies per company
