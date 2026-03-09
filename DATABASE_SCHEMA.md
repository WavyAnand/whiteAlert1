# WhiteAlert SaaS Platform - Database Schema Documentation

## Overview

This document describes the comprehensive PostgreSQL database schema for the WhiteAlert multi-tenant SaaS platform. The schema supports:
- Multi-tenancy with complete data isolation
- Role-based access control (RBAC)
- Real-time chat functionality
- Advanced ticketing system with lifecycle tracking
- QA validation workflows
- GitLab integration
- Full audit logging and compliance

## Database Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    CORE MULTI-TENANT LAYER                      │
│                                                                   │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │  Companies   │◄─────┤    Users     │─────►│ Departments  │  │
│  │   (Tenants)  │      │  (Multi-T)   │      │   (Org)      │  │
│  └──────────────┘      └──────────────┘      └──────────────┘  │
│         │                     │                      │           │
│         ▼                     ▼                      ▼           │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │  Roles       │◄─────┤Role_Perms    │─────►│Permissions   │  │
│  │  (RBAC)      │      │  (Mapping)   │      │  (RBAC)      │  │
│  └──────────────┘      └──────────────┘      └──────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
      ┌───────────────────────┼───────────────────────┐
      │                       │                       │
      ▼                       ▼                       ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ CHAT SYSTEM  │      │ TICKETING    │      │ QA SYSTEM    │
│              │      │              │      │              │
│ ChatRooms    │      │ Tickets      │      │ QA_Reviews   │
│ Messages     │      │ Ticket_Activ │      │ QA_Rules     │
│ Participants │      │ Ticket_GitLab│      │              │
└──────────────┘      └──────────────┘      └──────────────┘
      │                       │                       │
      │                       ▼                       │
      │              ┌──────────────┐                │
      │              │GITLAB INTEG  │                │
      │              │              │                │
      └─────────────►│GitLab_Config │◄───────────────┘
                     │GitLab_Mapping│
                     └──────────────┘
                              │
                     ┌────────┴────────┐
                     │                 │
                     ▼                 ▼
            ┌──────────────┐  ┌──────────────┐
            │NOTIFICATIONS │  │ AUDIT LOGS   │
            │ & Preferences│  │ (Compliance) │
            └──────────────┘  └──────────────┘
```

## Core Entities

### 1. **Companies (Tenants)**
Multi-tenant isolation at the database level.

```
companies
├── id (UUID, PK)
├── name (VARCHAR)
├── domain (VARCHAR, UNIQUE)
├── slug (VARCHAR, UNIQUE)
├── plan_tier (VARCHAR: starter/professional/enterprise)
├── max_users (INTEGER)
├── is_active (BOOLEAN)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

Relationships:
  → 1 to Many: users
  → 1 to Many: departments
  → 1 to Many: chat_rooms
  → 1 to Many: tickets
  → 1 to Many: qa_reviews
  → 1 to Many: roles
  → 1 to Many: notifications
```

### 2. **Users (Multi-Tenant)**
All users scoped to a company via `company_id`.

```
users
├── id (UUID, PK)
├── company_id (UUID, FK) ◄─── Multi-tenant key
├── department_id (UUID, FK)
├── email (VARCHAR, UNIQUE per company)
├── password_hash (VARCHAR)
├── full_name (VARCHAR, GENERATED)
├── role (ENUM: admin/manager/agent/user/viewer)
├── custom_role_id (UUID, FK → roles)
├── is_active (BOOLEAN)
├── sso_provider (VARCHAR)
├── sso_id (VARCHAR)
├── timezone (VARCHAR)
├── last_login_at (TIMESTAMP)
└── preferences (JSONB)

Indexes:
  - company_id (performance filtering)
  - email (authentication)
  - is_active (user queries)
  - department_id (organization hierarchy)

Relationships:
  ← Many to 1: companies
  ← Many to 1: departments
  ← Many to 1: roles (custom_role_id)
  → 1 to Many: messages
  → 1 to Many: tickets (created_by, assigned_to)
  → 1 to Many: qa_reviews
  → 1 to Many: notifications
  → 1 to Many: audit_logs
```

### 3. **Departments (Org Hierarchy)**
Organizational structure with hierarchical support.

```
departments
├── id (UUID, PK)
├── company_id (UUID, FK)
├── name (VARCHAR)
├── type (ENUM: support/engineering/sales/marketing/qa/other)
├── manager_id (UUID, FK → users)
├── parent_department_id (UUID, FK → departments) ◄─── Hierarchy
├── is_active (BOOLEAN)
└── created_at (TIMESTAMP)

Relationships:
  ← Many to 1: companies
  ← Many to 1: departments (parent)
  → 1 to Many: departments (children)
  → 1 to Many: users (department members)
  ← Many to 1: users (manager)
  → 1 to Many: tickets (assigned_to_department)
```

## RBAC (Role-Based Access Control)

### 4. **Roles**
Tenant-specific roles with custom permissions.

```
roles
├── id (UUID, PK)
├── company_id (UUID, FK)
├── name (VARCHAR)
├── description (TEXT)
├── default_role (BOOLEAN)
├── is_system_role (BOOLEAN) ◄─── admin, manager, agent are built-in
└── created_at (TIMESTAMP)

Relationships:
  ← Many to 1: companies
  → 1 to Many: role_permissions
  ← Many to 1: users (custom_role_id)
```

### 5. **Permissions**
Global permission definitions.

```
permissions
├── id (UUID, PK)
├── name (VARCHAR, UNIQUE)
├── resource (VARCHAR: users/tickets/chat/qa/reports)
├── action (VARCHAR: create/read/update/delete/approve)
└── created_at (TIMESTAMP)

Example permissions:
  - tickets.create     → Create new tickets
  - tickets.update     → Update ticket details
  - qa.approve         → Approve QA submissions
  - gitlab.sync        → Sync with GitLab
  - reports.view       → Access analytics
```

### 6. **Role_Permissions (Mapping)**
Links roles to permissions (many-to-many).

```
role_permissions
├── id (UUID, PK)
├── role_id (UUID, FK → roles)
├── permission_id (UUID, FK → permissions)
└── created_at (TIMESTAMP)

Example:
  admin_role → [tickets.create, tickets.update, tickets.delete, 
                 qa.approve, qa.reject, users.manage]
  agent_role → [tickets.create, tickets.update, chat.message]
```

## Chat System

### 7. **Chat_Rooms**
Support for direct messages, groups, and ticket-linked channels.

```
chat_rooms
├── id (UUID, PK)
├── company_id (UUID, FK)
├── name (VARCHAR)
├── type (VARCHAR: direct/group/support/ticket) ◄─── Type of room
├── is_public (BOOLEAN)
├── created_by (UUID, FK → users)
├── topic_ticket_id (UUID) ◄─── Link to ticket discussion
├── created_at (TIMESTAMP)
└── archived_at (TIMESTAMP)

Relationships:
  ← Many to 1: companies
  ← Many to 1: users (created_by)
  → 1 to Many: room_participants
  → 1 to Many: messages
```

### 8. **Room_Participants**
Membership tracking for chat rooms.

```
room_participants
├── id (UUID, PK)
├── room_id (UUID, FK → chat_rooms)
├── user_id (UUID, FK → users)
├── is_admin (BOOLEAN)
├── is_muted (BOOLEAN)
├── last_read_at (TIMESTAMP) ◄─── Unread message tracking
├── joined_at (TIMESTAMP)
└── left_at (TIMESTAMP)

Relationships:
  ← Many to 1: chat_rooms
  ← Many to 1: users
```

### 9. **Messages**
Real-time chat with file support and threading.

```
messages
├── id (UUID, PK)
├── room_id (UUID, FK → chat_rooms)
├── user_id (UUID, FK → users)
├── company_id (UUID, FK) ◄─── Multi-tenant filtering
├── content (TEXT)
├── message_type (ENUM: text/file/system/ticket_reference)
├── file_url (VARCHAR)
├── file_name (VARCHAR)
├── mentioned_user_ids (UUID[]) ◄─── @mentions
├── ticket_reference (UUID) ◄─── Link to ticket from chat
├── parent_message_id (UUID, FK) ◄─── Thread replies
├── is_edited (BOOLEAN)
├── is_deleted (BOOLEAN)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

Flow: Chat Message → Ticket Creation
  message (chat) → can reference → tickets (create ticket from chat)

Relationships:
  ← Many to 1: chat_rooms
  ← Many to 1: users
  ← Many to 1: companies
  → 1 to Many: messages (parent replies)
  ← Many to 1: messages (parent)
```

## Ticketing System

### 10. **Tickets**
Complete issue tracking with smart references.

```
tickets
├── id (UUID, PK)
├── company_id (UUID, FK)
├── ticket_number (VARCHAR: "TICKET-001") ◄─── Auto-generated
├── title (VARCHAR)
├── description (TEXT)
├── status (ENUM: open/in_progress/waiting_customer/in_qa/
│           qa_approved/qa_rejected/resolved/closed/reopened)
├── priority (ENUM: critical/high/medium/low)
├── created_by (UUID, FK → users)
├── assigned_to (UUID, FK → users)
├── assigned_to_department (UUID, FK → departments)
├── created_from_message (UUID, FK) ◄─── Chat → Ticket
├── source_channel (VARCHAR: chat/email/api)
├── customer_email (VARCHAR)
├── customer_name (VARCHAR)
├── due_date (TIMESTAMP)
├── sla_breach_date (TIMESTAMP)
├── resolved_at (TIMESTAMP)
├── tags (VARCHAR[])
├── custom_fields (JSONB)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

Relationships:
  ← Many to 1: companies
  ← Many to 1: users (created_by, assigned_to)
  ← Many to 1: departments (assigned_to_department)
  → 1 to Many: ticket_activities (lifecycle tracking)
  → 1 to Many: qa_reviews
  ← Many to 1: messages (created_from_message)
  → 1 to Many: ticket_gitlab_mappings
  → 1 to Many: notifications
  → 1 to Many: files (attachments)
```

### 11. **Ticket_Activities (Lifecycle Tracking)**
Immutable log of all ticket changes.

```
ticket_activities
├── id (UUID, PK)
├── ticket_id (UUID, FK → tickets)
├── company_id (UUID, FK)
├── user_id (UUID, FK → users)
├── activity_type (VARCHAR: status_change/assignment/comment/
│                  attachment/qa_submission/resolution)
├── old_value (VARCHAR)
├── new_value (VARCHAR)
├── notes (TEXT)
└── created_at (TIMESTAMP) ◄─── Immutable timestamp

Example activities:
  - status_change: open → in_progress
  - assignment: unassigned → user@company.com
  - qa_submission: Submitted for QA review
  - resolution: Resolved by user@company.com

Relationships:
  ← Many to 1: tickets
  ← Many to 1: companies
  ← Many to 1: users
```

## QA Validation System

### 12. **QA_Reviews**
Quality assurance approval workflow.

```
qa_reviews
├── id (UUID, PK)
├── ticket_id (UUID, FK → tickets) ◄─── 1:1 relationship per ticket
├── company_id (UUID, FK)
├── initiated_by (UUID, FK → users)
├── assigned_to (UUID, FK → users) ◄─── QA reviewer
├── status (ENUM: pending/approved/rejected/changes_requested)
├── review_comments (TEXT)
├── approval_date (TIMESTAMP)
├── rejection_reason (TEXT)
├── requires_changes_count (INTEGER) ◄─── Track revision rounds
├── created_at (TIMESTAMP)
└── completed_at (TIMESTAMP)

Relationship to ticket status:
  ticket.status = 'in_qa'  →  qa_reviews.status = 'pending'
  qa_reviews.status = 'approved'  →  ticket.status = 'qa_approved'
  qa_reviews.status = 'rejected'  →  ticket.status = 'qa_rejected'

Relationships:
  ← Many to 1: tickets
  ← Many to 1: companies
  ← Many to 1: users (initiated_by, assigned_to)
  → 1 to Many: notifications (assigned user notified)
```

### 13. **QA_Validation_Rules**
Configurable QA policies and checks.

```
qa_validation_rules
├── id (UUID, PK)
├── company_id (UUID, FK)
├── name (VARCHAR)
├── description (TEXT)
├── rule_type (VARCHAR: automated/manual/hybrid)
├── conditions (JSONB) ◄─── Flexible rule definition
├── is_active (BOOLEAN)
├── applies_to_all_tickets (BOOLEAN)
├── ticket_status_filter (VARCHAR[])
├── created_by (UUID, FK → users)
└── created_at (TIMESTAMP)

Example rules (as JSONB):
  {
    "type": "required_field_check",
    "fields": ["title", "customer_email"],
    "message": "Title and customer email are required before QA"
  }
  
  {
    "type": "tag_requirement",
    "tags": ["urgent", "bug", "feature"],
    "message": "Ticket must be tagged with category"
  }
```

## GitLab Integration

### 14. **GitLab_Configurations**
API credentials and webhook setup.

```
gitlab_configurations
├── id (UUID, PK)
├── company_id (UUID, FK) ◄─── 1:1 per company
├── gitlab_url (VARCHAR)
├── gitlab_token (VARCHAR) ◄─── Encrypted in production
├── project_id (VARCHAR)
├── is_active (BOOLEAN)
├── auto_sync_enabled (BOOLEAN)
├── auto_sync_interval_minutes (INTEGER)
├── webhook_secret (VARCHAR) ◄─── For webhook verification
├── last_synced_at (TIMESTAMP)
└── created_at (TIMESTAMP)

Relationships:
  ← Many to 1: companies (1:1 via UNIQUE constraint)
```

### 15. **Ticket_GitLab_Mappings**
Bidirectional sync between tickets and GitLab issues.

```
ticket_gitlab_mappings
├── id (UUID, PK)
├── ticket_id (UUID, FK → tickets)
├── company_id (UUID, FK)
├── gitlab_issue_id (VARCHAR)
├── gitlab_issue_number (INTEGER)
├── gitlab_issue_url (VARCHAR)
├── is_bidirectional (BOOLEAN) ◄─── Sync direction
├── last_synced_at (TIMESTAMP)
├── sync_status (VARCHAR: syncing/synced/error)
└── created_at (TIMESTAMP)

Sync Flow:
  1. Create ticket in WhiteAlert
  2. Create GitLab issue automatically
  3. Store mapping
  4. Bidirectional sync on updates

Relationships:
  ← Many to 1: tickets
  ← Many to 1: companies
```

## Notifications

### 16. **Notifications**
Multi-channel notification system (email, SMS, push, in-app).

```
notifications
├── id (UUID, PK)
├── user_id (UUID, FK → users)
├── company_id (UUID, FK)
├── type (ENUM: ticket_created/ticket_updated/message/
│          qa_review/assignment/mention/system)
├── status (ENUM: unread/read/archived)
├── title (VARCHAR)
├── message (TEXT)
├── related_ticket_id (UUID, FK)
├── related_message_id (UUID, FK)
├── related_qa_review_id (UUID, FK)
├── action_url (VARCHAR) ◄─── Deep link to resource
├── is_email_sent (BOOLEAN)
├── is_sms_sent (BOOLEAN)
├── is_push_sent (BOOLEAN)
├── created_at (TIMESTAMP)
├── read_at (TIMESTAMP)
└── archived_at (TIMESTAMP)

Triggers:
  - User assigned to ticket  →  notification (type: assignment)
  - QA review needed  →  notification (type: qa_review)
  - Message mention (@user)  →  notification (type: mention)
  - Ticket status change  →  notification (type: ticket_updated)

Relationships:
  ← Many to 1: users
  ← Many to 1: companies
  → References: tickets
  → References: messages
  → References: qa_reviews
```

### 17. **Notification_Preferences**
User-level notification settings.

```
notification_preferences
├── id (UUID, PK)
├── user_id (UUID, FK, UNIQUE) ◄─── 1:1 with users
├── company_id (UUID, FK)
├── email_on_ticket_assigned (BOOLEAN)
├── email_on_ticket_updated (BOOLEAN)
├── email_on_qa_review (BOOLEAN)
├── push_notifications_enabled (BOOLEAN)
├── quiet_hours_enabled (BOOLEAN)
├── quiet_hours_start (VARCHAR: HH:MM)
├── quiet_hours_end (VARCHAR: HH:MM)
└── timezone (VARCHAR)
```

## Audit & Compliance

### 18. **Audit_Logs**
Immutable record of all changes for compliance.

```
audit_logs
├── id (UUID, PK)
├── company_id (UUID, FK)
├── user_id (UUID, FK → users)
├── resource_type (VARCHAR: ticket/message/user/qa_review)
├── resource_id (UUID)
├── action (VARCHAR: create/read/update/delete)
├── old_data (JSONB) ◄─── Full before state
├── new_data (JSONB) ◄─── Full after state
├── ip_address (INET) ◄─── For security
├── user_agent (VARCHAR)
└── timestamp (TIMESTAMP)

Use cases:
  - Compliance auditing (SOC2, GDPR)
  - Security incident investigation
  - Change tracking

Relationships:
  ← Many to 1: companies
  ← Many to 1: users (who made change)
```

## Files & Storage

### 19. **Files**
Metadata for attachments and document management.

```
files
├── id (UUID, PK)
├── company_id (UUID, FK)
├── uploaded_by (UUID, FK → users)
├── file_name (VARCHAR)
├── file_type (VARCHAR)
├── file_size (BIGINT) ◄─── For quota management
├── storage_path (VARCHAR)
├── s3_key (VARCHAR) ◄─── For cloud providers
├── is_public (BOOLEAN)
├── related_ticket_id (UUID, FK)
├── related_message_id (UUID, FK)
├── created_at (TIMESTAMP)
└── deleted_at (TIMESTAMP)

Relationships:
  ← Many to 1: companies
  ← Many to 1: users (uploaded_by)
  → References: tickets
  → References: messages
```

## Cross-Tenant Isolation

**Critical for multi-tenancy:**

Every query must include `company_id` filtering:

```sql
-- ✅ CORRECT - Multi-tenant safe
SELECT * FROM messages 
WHERE company_id = $1 AND room_id = $2;

-- ❌ WRONG - Data leak risk
SELECT * FROM messages WHERE room_id = $2;
```

Row-level security (RLS) recommended:
```sql
CREATE POLICY messages_isolation ON messages
  USING (company_id = current_setting('app.current_company_id')::uuid);
```

## Key Relationships Summary

```
companies (1) ──→ (∞) users
          (1) ──→ (∞) departments
          (1) ──→ (∞) roles
          (1) ──→ (∞) chat_rooms
          (1) ──→ (∞) tickets
          (1) ──→ (∞) qa_reviews
          (1) ──→ (∞) messages
          (1) ──→ (∞) notifications

users     (1) ──→ (∞) messages
          (1) ──→ (∞) tickets (created_by)
          (1) ──→ (∞) tickets (assigned_to)
          (1) ──→ (∞) qa_reviews
          (1) ──→ (∞) notifications

tickets   (1) ──→ (∞) messages
          (1) ──→ (1)  qa_reviews
          (1) ──→ (∞) ticket_activities
          (1) ──→ (∞) ticket_gitlab_mappings
          (1) ──→ (∞) notifications
          (1) ──→ (∞) files (attachments)

messages  (1) ──→ (∞) messages (threads via parent_message_id)
          (1) ──→ (1)  tickets (created_from_message)
```

## Indexes for Performance

Critical indexes created:
- `users(company_id)` - Filter by tenant
- `users(email)` - Authentication
- `tickets(status)` - Query by status
- `tickets(assigned_to)` - User's tickets
- `messages(room_id, created_at)` - Load chat history
- `notifications(user_id, status)` - Unread count
- Full-text search on tickets/messages

## Views for Common Queries

```sql
active_users             -- Users with is_active=true
open_tickets             -- All non-resolved tickets
tickets_pending_qa       -- Tickets awaiting QA approval
```

---

**Total Tables**: 19  
**Total Relationships**: 40+  
**Full Multi-Tenant Support**: Yes  
**Audit Logging**: Yes  
**Compliance Ready**: Yes