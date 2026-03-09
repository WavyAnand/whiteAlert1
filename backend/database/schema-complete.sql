-- ============================================================================
-- WhiteAlert SaaS Platform - Complete PostgreSQL Database Schema
-- Version: 2.0 (Phase 2 - Production Ready)
-- ============================================================================

-- ============================================================================
-- CORE MULTI-TENANCY & ORGANIZATION
-- ============================================================================

-- Companies/Tenants - Root entity for multi-tenancy
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  domain VARCHAR(255) UNIQUE,
  logo_url VARCHAR(500),
  description TEXT,
  subscription_tier VARCHAR(50) DEFAULT 'starter', -- starter, professional, enterprise
  subscription_status VARCHAR(50) DEFAULT 'active', -- active, suspended, cancelled
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Departments within a company
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  manager_id UUID REFERENCES users(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- ============================================================================
-- ROLES & PERMISSIONS (RBAC)
-- ============================================================================

-- Roles - Predefined roles per company
CREATE TABLE IF NOT EXISTS roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL, -- admin, manager, support_agent, customer, etc.
  description TEXT,
  is_system BOOLEAN DEFAULT false, -- system roles cannot be deleted
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- Permissions - Atomic permissions
CREATE TABLE IF NOT EXISTS permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE, -- chat:create, ticket:view, etc.
  description TEXT,
  category VARCHAR(50) -- chat, ticket, qa, admin, etc.
);

-- Role-Permission mapping
CREATE TABLE IF NOT EXISTS role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(role_id, permission_id)
);

-- ============================================================================
-- USERS & AUTHENTICATION
-- ============================================================================

-- Users table with multi-tenant support
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255),
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  avatar_url VARCHAR(500),
  department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  role_id UUID REFERENCES roles(id) ON DELETE SET NULL,
  phone VARCHAR(20),
  bio TEXT,
  timezone VARCHAR(50) DEFAULT 'UTC',
  preferences JSONB DEFAULT '{}', -- notification preferences, theme, etc.
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMP,
  email_verified BOOLEAN DEFAULT false,
  email_verified_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, email)
);

-- User sessions for tracking active sessions
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255),
  ip_address INET,
  user_agent TEXT,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CHAT & REAL-TIME MESSAGING
-- ============================================================================

-- Chat rooms/groups
CREATE TABLE IF NOT EXISTS chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255),
  description TEXT,
  type VARCHAR(50) DEFAULT 'group', -- 'direct', 'group', 'channel'
  is_archived BOOLEAN DEFAULT false,
  is_private BOOLEAN DEFAULT false,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Chat room participants
CREATE TABLE IF NOT EXISTS chat_room_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'member', -- owner, admin, member
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_read_at TIMESTAMP,
  UNIQUE(room_id, user_id)
);

-- Messages in chat rooms
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  message_type VARCHAR(50) DEFAULT 'text', -- text, image, file, system, etc.
  file_url VARCHAR(500),
  file_size BIGINT,
  metadata JSONB, -- rich formatting, reactions, etc.
  is_edited BOOLEAN DEFAULT false,
  edited_at TIMESTAMP,
  is_deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Message reactions/threads
CREATE TABLE IF NOT EXISTS message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  emoji VARCHAR(10),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(message_id, user_id, emoji)
);

-- ============================================================================
-- TICKETING SYSTEM
-- ============================================================================

-- Tickets (created from chat or directly)
CREATE TABLE IF NOT EXISTS tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  reference_number VARCHAR(20) NOT NULL, -- TICKET-001, TICKET-002, etc.
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  priority VARCHAR(50) DEFAULT 'medium', -- low, medium, high, urgent
  status VARCHAR(50) DEFAULT 'open', -- open, in_progress, waiting, qa_review, closed
  category VARCHAR(100), -- bug, feature, support, etc.
  department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  chat_room_id UUID REFERENCES chat_rooms(id) ON DELETE SET NULL, -- originating chat
  gitlab_issue_id VARCHAR(100), -- GitLab issue ID if synced
  gitlab_issue_url VARCHAR(500),
  sla_due_date TIMESTAMP,
  resolved_at TIMESTAMP,
  estimated_hours DECIMAL(10, 2),
  actual_hours DECIMAL(10, 2),
  tags JSONB DEFAULT '[]', -- array of tags for filtering
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, reference_number)
);

-- Ticket comments/updates
CREATE TABLE IF NOT EXISTS ticket_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT false, -- visible only to staff
  attachment_urls JSONB DEFAULT '[]',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ticket lifecycle/audit log
CREATE TABLE IF NOT EXISTS ticket_lifecycle (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL, -- created, status_changed, assigned, commented, etc.
  old_value VARCHAR(255),
  new_value VARCHAR(255),
  field_name VARCHAR(100), -- status, assigned_to, priority, etc.
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- QA & VALIDATION WORKFLOW
-- ============================================================================

-- QA validation rules
CREATE TABLE IF NOT EXISTS qa_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  rule_type VARCHAR(50), -- automated, manual, hybrid
  conditions JSONB NOT NULL, -- JSON: criteria for validation
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- QA validation records for tickets
CREATE TABLE IF NOT EXISTS qa_validations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  qa_rule_id UUID REFERENCES qa_rules(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'pending', -- pending, passed, failed, needs_review
  reviewer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  comments TEXT,
  validation_data JSONB, -- details of what was checked
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- QA approval/rejection workflow
CREATE TABLE IF NOT EXISTS qa_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  qa_validation_id UUID REFERENCES qa_validations(id) ON DELETE CASCADE,
  approver_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected, needs_revision
  comments TEXT,
  rejection_reason TEXT,
  approved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- GITLAB INTEGRATION
-- ============================================================================

-- GitLab sync records
CREATE TABLE IF NOT EXISTS gitlab_syncs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  gitlab_project_id INTEGER NOT NULL,
  gitlab_project_name VARCHAR(255),
  gitlab_url VARCHAR(500),
  access_token_hash VARCHAR(255), -- encrypted
  is_active BOOLEAN DEFAULT true,
  sync_direction VARCHAR(50) DEFAULT 'bidirectional', -- oneway, bidirectional
  last_sync_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, gitlab_project_id)
);

-- GitLab webhook logs
CREATE TABLE IF NOT EXISTS gitlab_webhook_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  event_type VARCHAR(100), -- push, issue, merge_request, etc.
  gitlab_issue_id VARCHAR(100),
  webhook_payload JSONB,
  processed BOOLEAN DEFAULT false,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- NOTIFICATIONS & ALERTS
-- ============================================================================

-- Notification templates
CREATE TABLE IF NOT EXISTS notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE, -- NULL for system templates
  name VARCHAR(255) NOT NULL,
  subject VARCHAR(255),
  body TEXT NOT NULL,
  template_type VARCHAR(50), -- email, sms, push, in_app
  variables JSONB DEFAULT '[]', -- {user_name}, {ticket_title}, etc.
  is_system BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications sent to users
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  related_ticket_id UUID REFERENCES tickets(id) ON DELETE SET NULL,
  related_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  notification_type VARCHAR(50), -- ticket_assigned, comment_mentioned, etc.
  title VARCHAR(255) NOT NULL,
  content TEXT,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  channels JSONB DEFAULT '[]', -- [email, push, in_app]
  metadata JSONB,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User notification preferences
CREATE TABLE IF NOT EXISTS notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  notification_type VARCHAR(100), -- ticket_assigned, comment_reply, etc.
  email_enabled BOOLEAN DEFAULT true,
  push_enabled BOOLEAN DEFAULT true,
  sms_enabled BOOLEAN DEFAULT false,
  in_app_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, notification_type)
);

-- ============================================================================
-- ACTIVITY & AUDIT LOGS
-- ============================================================================

-- Audit log for compliance and security
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL, -- create, update, delete, login, export
  resource_type VARCHAR(100), -- ticket, user, company, etc.
  resource_id VARCHAR(100),
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  status VARCHAR(50) DEFAULT 'success', -- success, failure
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- FILE STORAGE & ATTACHMENTS
-- ============================================================================

-- File attachments metadata
CREATE TABLE IF NOT EXISTS file_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  file_name VARCHAR(255) NOT NULL,
  file_size BIGINT NOT NULL,
  file_type VARCHAR(50), -- image, document, video, etc.
  mime_type VARCHAR(100),
  storage_path VARCHAR(500), -- S3 path, local path, etc.
  storage_provider VARCHAR(50) DEFAULT 'local', -- local, s3, azure, etc.
  related_ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
  related_message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  is_public BOOLEAN DEFAULT false,
  virus_scanned BOOLEAN DEFAULT false,
  scan_result VARCHAR(50), -- clean, infected, unknown
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Company & Organization
CREATE INDEX IF NOT EXISTS idx_companies_domain ON companies(domain);
CREATE INDEX IF NOT EXISTS idx_departments_company_id ON departments(company_id);
CREATE INDEX IF NOT EXISTS idx_departments_manager_id ON departments(manager_id);

-- Users & Auth
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(company_id, email);
CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_department_id ON users(department_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions(expires_at);

-- Chat
CREATE INDEX IF NOT EXISTS idx_chat_rooms_company_id ON chat_rooms(company_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_type ON chat_rooms(type);
CREATE INDEX IF NOT EXISTS idx_chat_room_participants_room_id ON chat_room_participants(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_room_participants_user_id ON chat_room_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_room_id ON messages(room_id);
CREATE INDEX IF NOT EXISTS idx_messages_user_id ON messages(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_company_id ON messages(company_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON message_reactions(message_id);

-- Tickets
CREATE INDEX IF NOT EXISTS idx_tickets_company_id ON tickets(company_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_priority ON tickets(priority);
CREATE INDEX IF NOT EXISTS idx_tickets_assigned_to ON tickets(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tickets_created_by ON tickets(created_by);
CREATE INDEX IF NOT EXISTS idx_tickets_created_at ON tickets(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tickets_gitlab_issue_id ON tickets(gitlab_issue_id);
CREATE INDEX IF NOT EXISTS idx_tickets_chat_room_id ON tickets(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_ticket_comments_ticket_id ON ticket_comments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_comments_user_id ON ticket_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_ticket_lifecycle_ticket_id ON ticket_lifecycle(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_lifecycle_created_at ON ticket_lifecycle(created_at);

-- QA
CREATE INDEX IF NOT EXISTS idx_qa_rules_company_id ON qa_rules(company_id);
CREATE INDEX IF NOT EXISTS idx_qa_validations_ticket_id ON qa_validations(ticket_id);
CREATE INDEX IF NOT EXISTS idx_qa_validations_status ON qa_validations(status);
CREATE INDEX IF NOT EXISTS idx_qa_approvals_ticket_id ON qa_approvals(ticket_id);
CREATE INDEX IF NOT EXISTS idx_qa_approvals_approver_id ON qa_approvals(approver_id);

-- GitLab
CREATE INDEX IF NOT EXISTS idx_gitlab_syncs_company_id ON gitlab_syncs(company_id);
CREATE INDEX IF NOT EXISTS idx_gitlab_webhook_logs_company_id ON gitlab_webhook_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_gitlab_webhook_logs_processed ON gitlab_webhook_logs(processed);

-- Notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_company_id ON notifications(company_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Audit & Files
CREATE INDEX IF NOT EXISTS idx_audit_logs_company_id ON audit_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_file_attachments_company_id ON file_attachments(company_id);
CREATE INDEX IF NOT EXISTS idx_file_attachments_ticket_id ON file_attachments(related_ticket_id);

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- Active users per company
CREATE OR REPLACE VIEW vw_active_users AS
SELECT c.id AS company_id, c.name AS company_name, COUNT(u.id) AS active_user_count
FROM companies c
LEFT JOIN users u ON c.id = u.company_id AND u.is_active = true
GROUP BY c.id, c.name;

-- Open tickets by priority
CREATE OR REPLACE VIEW vw_open_tickets_by_priority AS
SELECT company_id, priority, COUNT(*) AS ticket_count
FROM tickets
WHERE status != 'closed'
GROUP BY company_id, priority;

-- Unresolved notifications
CREATE OR REPLACE VIEW vw_unresolved_notifications AS
SELECT u.id AS user_id, u.email, COUNT(n.id) AS unread_count
FROM users u
LEFT JOIN notifications n ON u.id = n.user_id AND n.is_read = false
GROUP BY u.id, u.email;
