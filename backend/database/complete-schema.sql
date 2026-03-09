-- WhiteAlert SaaS Platform - Complete PostgreSQL Schema
-- Comprehensive database design with multi-tenancy support

-- ============================================
-- ENUMS (Data Types)
-- ============================================

CREATE TYPE user_role AS ENUM ('admin', 'manager', 'agent', 'user', 'viewer');
CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'waiting_customer', 'in_qa', 'qa_approved', 'qa_rejected', 'resolved', 'closed', 'reopened');
CREATE TYPE ticket_priority AS ENUM ('critical', 'high', 'medium', 'low');
CREATE TYPE qa_status AS ENUM ('pending', 'approved', 'rejected', 'changes_requested');
CREATE TYPE notification_type AS ENUM ('ticket_created', 'ticket_updated', 'message', 'qa_review', 'assignment', 'mention', 'system');
CREATE TYPE notification_status AS ENUM ('unread', 'read', 'archived');
CREATE TYPE message_type AS ENUM ('text', 'file', 'system', 'ticket_reference');
CREATE TYPE department_type AS ENUM ('support', 'engineering', 'sales', 'marketing', 'qa', 'other');

-- ============================================
-- CORE TABLES - Multi-Tenant Foundation
-- ============================================

-- Companies (Tenants)
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  domain VARCHAR(255) UNIQUE,
  slug VARCHAR(100) UNIQUE,
  description TEXT,
  logo_url VARCHAR(512),
  plan_tier VARCHAR(50) DEFAULT 'starter', -- starter, professional, enterprise
  max_users INTEGER DEFAULT 10,
  max_storage_gb BIGINT DEFAULT 10,
  is_active BOOLEAN DEFAULT true,
  billing_email VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_companies_slug ON companies(slug);
CREATE INDEX idx_companies_active ON companies(is_active);

-- ============================================
-- ROLES & PERMISSIONS
-- ============================================

-- Roles
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  default_role BOOLEAN DEFAULT false,
  is_system_role BOOLEAN DEFAULT false, -- true for admin, manager, agent roles
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

CREATE INDEX idx_roles_company_id ON roles(company_id);

-- Permissions
CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  resource VARCHAR(100) NOT NULL, -- users, tickets, chat, qa, reports
  action VARCHAR(50) NOT NULL, -- create, read, update, delete, approve, reject
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Role-Permission Mapping
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);

-- ============================================
-- USERS & DEPARTMENTS
-- ============================================

-- Departments
CREATE TABLE departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  type department_type DEFAULT 'other',
  description TEXT,
  manager_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Self-referencing, handled after users table
  parent_department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255),
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  full_name VARCHAR(255) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
  phone VARCHAR(20),
  avatar_url VARCHAR(512),
  role user_role DEFAULT 'user',
  custom_role_id UUID REFERENCES roles(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  last_login_at TIMESTAMP,
  login_count INTEGER DEFAULT 0,
  failed_login_attempts INTEGER DEFAULT 0,
  locked_until TIMESTAMP,
  sso_provider VARCHAR(50), -- google, microsoft, github, okta
  sso_id VARCHAR(255),
  timezone VARCHAR(50) DEFAULT 'UTC',
  language VARCHAR(10) DEFAULT 'en',
  preferences JSONB DEFAULT '{}', -- notification prefs, UI settings, etc
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP,
  UNIQUE(company_id, email),
  UNIQUE(sso_provider, sso_id)
);

CREATE INDEX idx_users_company_id ON users(company_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_department_id ON users(department_id);
CREATE INDEX idx_users_is_active ON users(is_active);

-- Add foreign key for department manager (was deferred)
ALTER TABLE departments ADD CONSTRAINT fk_departments_manager_id 
  FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL;

CREATE INDEX idx_departments_company_id ON departments(company_id);
CREATE INDEX idx_departments_manager_id ON departments(manager_id);

-- ============================================
-- CHAT SYSTEM
-- ============================================

-- Chat Rooms/Channels
CREATE TABLE chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255),
  description TEXT,
  type VARCHAR(50) NOT NULL, -- direct, group, support, ticket
  is_public BOOLEAN DEFAULT false,
  is_archived BOOLEAN DEFAULT false,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  topic_ticket_id UUID, -- Reference to associated ticket, if any
  max_members INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  archived_at TIMESTAMP
);

CREATE INDEX idx_chat_rooms_company_id ON chat_rooms(company_id);
CREATE INDEX idx_chat_rooms_type ON chat_rooms(type);
CREATE INDEX idx_chat_rooms_is_public ON chat_rooms(is_public);
CREATE INDEX idx_chat_rooms_created_by ON chat_rooms(created_by);

-- Room Participants
CREATE TABLE room_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_admin BOOLEAN DEFAULT false,
  is_muted BOOLEAN DEFAULT false,
  last_read_at TIMESTAMP,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  left_at TIMESTAMP,
  UNIQUE(room_id, user_id)
);

CREATE INDEX idx_room_participants_room_id ON room_participants(room_id);
CREATE INDEX idx_room_participants_user_id ON room_participants(user_id);

-- Chat Messages
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type message_type DEFAULT 'text',
  file_url VARCHAR(512),
  file_name VARCHAR(255),
  file_size INTEGER,
  mentioned_user_ids UUID[] DEFAULT '{}',
  ticket_reference UUID, -- Reference to a ticket if message is about a ticket
  is_edited BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  parent_message_id UUID REFERENCES messages(id) ON DELETE SET NULL, -- For thread replies
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_messages_room_id ON messages(room_id);
CREATE INDEX idx_messages_user_id ON messages(user_id);
CREATE INDEX idx_messages_company_id ON messages(company_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_messages_parent_message_id ON messages(parent_message_id);

-- ============================================
-- TICKETING SYSTEM
-- ============================================

-- Tickets
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  ticket_number VARCHAR(20) NOT NULL, -- Auto-generated: TICKET-001, TICKET-002, etc
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status ticket_status DEFAULT 'open',
  priority ticket_priority DEFAULT 'medium',
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  assigned_to_department UUID REFERENCES departments(id) ON DELETE SET NULL,
  created_from_message UUID REFERENCES messages(id) ON DELETE SET NULL, -- Reference to chat message
  source_channel VARCHAR(50), -- chat, email, api, web_form
  customer_email VARCHAR(255),
  customer_name VARCHAR(255),
  due_date TIMESTAMP,
  sla_breach_date TIMESTAMP,
  resolved_at TIMESTAMP,
  closed_at TIMESTAMP,
  views_count INTEGER DEFAULT 0,
  is_urgent BOOLEAN DEFAULT false,
  tags VARCHAR(100)[] DEFAULT '{}',
  custom_fields JSONB DEFAULT '{}', -- For extensibility
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP,
  UNIQUE(company_id, ticket_number)
);

CREATE INDEX idx_tickets_company_id ON tickets(company_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_priority ON tickets(priority);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to);
CREATE INDEX idx_tickets_created_at ON tickets(created_at);
CREATE INDEX idx_tickets_created_by ON tickets(created_by);

-- Ticket Activity/Lifecycle Tracking
CREATE TABLE ticket_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  activity_type VARCHAR(50) NOT NULL, -- status_change, assignment, comment, attachment, qa_submission, etc
  old_value VARCHAR(255),
  new_value VARCHAR(255),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ticket_activities_ticket_id ON ticket_activities(ticket_id);
CREATE INDEX idx_ticket_activities_company_id ON ticket_activities(company_id);
CREATE INDEX idx_ticket_activities_user_id ON ticket_activities(user_id);
CREATE INDEX idx_ticket_activities_created_at ON ticket_activities(created_at);

-- ============================================
-- QA VALIDATION SYSTEM
-- ============================================

-- QA Review Workflows
CREATE TABLE qa_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  initiated_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  assigned_to UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  status qa_status DEFAULT 'pending',
  review_comments TEXT,
  approval_date TIMESTAMP,
  rejection_reason TEXT,
  requires_changes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);

CREATE INDEX idx_qa_reviews_ticket_id ON qa_reviews(ticket_id);
CREATE INDEX idx_qa_reviews_company_id ON qa_reviews(company_id);
CREATE INDEX idx_qa_reviews_status ON qa_reviews(status);
CREATE INDEX idx_qa_reviews_assigned_to ON qa_reviews(assigned_to);

-- QA Validation Rules
CREATE TABLE qa_validation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  rule_type VARCHAR(50) NOT NULL, -- automated, manual, hybrid
  conditions JSONB NOT NULL, -- JSON structure for rule conditions
  is_active BOOLEAN DEFAULT true,
  applies_to_all_tickets BOOLEAN DEFAULT true,
  ticket_status_filter VARCHAR(50)[], -- Only apply to tickets with these statuses
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_qa_validation_rules_company_id ON qa_validation_rules(company_id);
CREATE INDEX idx_qa_validation_rules_is_active ON qa_validation_rules(is_active);

-- ============================================
-- GITLAB INTEGRATION
-- ============================================

-- GitLab Issue Integration
CREATE TABLE gitlab_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  gitlab_url VARCHAR(255) NOT NULL,
  gitlab_token VARCHAR(255), -- Encrypted in production
  project_id VARCHAR(100) NOT NULL,
  group_id VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  auto_sync_enabled BOOLEAN DEFAULT true,
  auto_sync_interval_minutes INTEGER DEFAULT 30,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  last_synced_at TIMESTAMP,
  webhook_secret VARCHAR(255), -- For webhook verification
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id)
);

-- Mapping between tickets and GitLab issues
CREATE TABLE ticket_gitlab_mappings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  gitlab_issue_id VARCHAR(100) NOT NULL,
  gitlab_issue_number INTEGER NOT NULL,
  gitlab_issue_url VARCHAR(255),
  is_bidirectional BOOLEAN DEFAULT true,
  last_synced_at TIMESTAMP,
  sync_status VARCHAR(50) DEFAULT 'synced', -- syncing, synced, error
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(ticket_id, gitlab_issue_id)
);

CREATE INDEX idx_ticket_gitlab_mappings_ticket_id ON ticket_gitlab_mappings(ticket_id);
CREATE INDEX idx_ticket_gitlab_mappings_company_id ON ticket_gitlab_mappings(company_id);

-- ============================================
-- NOTIFICATIONS
-- ============================================

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  status notification_status DEFAULT 'unread',
  title VARCHAR(255) NOT NULL,
  message TEXT,
  related_ticket_id UUID REFERENCES tickets(id) ON DELETE SET NULL,
  related_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  related_qa_review_id UUID REFERENCES qa_reviews(id) ON DELETE SET NULL,
  action_url VARCHAR(512),
  is_email_sent BOOLEAN DEFAULT false,
  is_sms_sent BOOLEAN DEFAULT false,
  is_push_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP,
  archived_at TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_company_id ON notifications(company_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- User Notification Preferences
CREATE TABLE notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  email_on_ticket_assigned BOOLEAN DEFAULT true,
  email_on_ticket_updated BOOLEAN DEFAULT true,
  email_on_qa_review BOOLEAN DEFAULT true,
  email_on_mention BOOLEAN DEFAULT true,
  push_notifications_enabled BOOLEAN DEFAULT true,
  sms_notifications_enabled BOOLEAN DEFAULT false,
  quiet_hours_enabled BOOLEAN DEFAULT false,
  quiet_hours_start VARCHAR(5), -- HH:MM format
  quiet_hours_end VARCHAR(5),
  timezone VARCHAR(50) DEFAULT 'UTC',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notification_preferences_user_id ON notification_preferences(user_id);
CREATE INDEX idx_notification_preferences_company_id ON notification_preferences(company_id);

-- ============================================
-- AUDITING & COMPLIANCE
-- ============================================

-- Audit Log
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  resource_type VARCHAR(100) NOT NULL, -- ticket, message, user, qa_review
  resource_id UUID NOT NULL,
  action VARCHAR(50) NOT NULL, -- create, read, update, delete
  old_data JSONB,
  new_data JSONB,
  ip_address INET,
  user_agent VARCHAR(512),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_company_id ON audit_logs(company_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);

-- ============================================
-- ANALYTICS & REPORTING
-- ============================================

-- Daily Metrics (for dashboard aggregation)
CREATE TABLE daily_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  tickets_created INTEGER DEFAULT 0,
  tickets_resolved INTEGER DEFAULT 0,
  tickets_in_qa INTEGER DEFAULT 0,
  avg_resolution_time_minutes INTEGER,
  distinct_users INTEGER DEFAULT 0,
  messages_sent INTEGER DEFAULT 0,
  qa_approvals INTEGER DEFAULT 0,
  qa_rejections INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, date)
);

CREATE INDEX idx_daily_metrics_company_id ON daily_metrics(company_id);
CREATE INDEX idx_daily_metrics_date ON daily_metrics(date);

-- ============================================
-- FILE STORAGE METADATA
-- ============================================

-- File Storage
CREATE TABLE files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(50),
  file_size BIGINT NOT NULL,
  storage_path VARCHAR(512) NOT NULL,
  s3_key VARCHAR(512), -- For cloud storage
  is_public BOOLEAN DEFAULT false,
  related_ticket_id UUID REFERENCES tickets(id) ON DELETE SET NULL,
  related_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_files_company_id ON files(company_id);
CREATE INDEX idx_files_uploaded_by ON files(uploaded_by);
CREATE INDEX idx_files_related_ticket_id ON files(related_ticket_id);
CREATE INDEX idx_files_created_at ON files(created_at);

-- ============================================
-- SEARCH & INDEXING
-- ============================================

-- Full-text search indexes (PostgreSQL native)
CREATE INDEX idx_tickets_title_search ON tickets USING GIN(to_tsvector('english', title));
CREATE INDEX idx_tickets_description_search ON tickets USING GIN(to_tsvector('english', description));
CREATE INDEX idx_messages_content_search ON messages USING GIN(to_tsvector('english', content));

-- ============================================
-- SYSTEM CONFIGURATION
-- ============================================

-- System Settings
CREATE TABLE system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  setting_key VARCHAR(100) NOT NULL,
  setting_value VARCHAR(500),
  data_type VARCHAR(50),
  is_global BOOLEAN DEFAULT false, -- Global setting if company_id is NULL
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, setting_key)
);

CREATE INDEX idx_system_settings_company_id ON system_settings(company_id);
CREATE INDEX idx_system_settings_key ON system_settings(setting_key);

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- Active Users View
CREATE VIEW active_users AS
SELECT 
  id,
  company_id,
  email,
  full_name,
  role,
  last_login_at,
  is_active
FROM users
WHERE is_active = true AND deleted_at IS NULL;

-- Open Tickets View
CREATE VIEW open_tickets AS
SELECT 
  id,
  company_id,
  ticket_number,
  title,
  status,
  priority,
  assigned_to,
  created_at,
  updated_at
FROM tickets
WHERE status IN ('open', 'in_progress', 'waiting_customer', 'in_qa', 'reopened')
  AND deleted_at IS NULL;

-- Tickets Pending QA View
CREATE VIEW tickets_pending_qa AS
SELECT 
  t.id,
  t.company_id,
  t.ticket_number,
  t.title,
  t.priority,
  qr.id as qa_review_id,
  qr.status as qa_status,
  qr.assigned_to
FROM tickets t
LEFT JOIN qa_reviews qr ON t.id = qr.ticket_id
WHERE t.status = 'in_qa' AND qr.status IN ('pending', 'changes_requested')
  AND t.deleted_at IS NULL;

-- ============================================
-- STORED PROCEDURES & FUNCTIONS
-- ============================================

-- Function to auto-increment ticket numbers
CREATE OR REPLACE FUNCTION generate_ticket_number(p_company_id UUID)
RETURNS VARCHAR(20) AS $$
DECLARE
  v_count INTEGER;
  v_number VARCHAR(20);
BEGIN
  SELECT COUNT(*) + 1 INTO v_count FROM tickets WHERE company_id = p_company_id;
  v_number := 'TICKET-' || LPAD(v_count::TEXT, 6, '0');
  RETURN v_number;
END;
$$ LANGUAGE plpgsql;

-- Function to update ticket updated_at timestamp
CREATE OR REPLACE FUNCTION update_ticket_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for ticket updated_at
CREATE TRIGGER trigger_update_ticket_timestamp
BEFORE UPDATE ON tickets
FOR EACH ROW
EXECUTE FUNCTION update_ticket_timestamp();

-- Similar triggers for other tables
CREATE TRIGGER trigger_update_users_timestamp
BEFORE UPDATE ON users FOR EACH ROW
EXECUTE FUNCTION update_ticket_timestamp();

CREATE TRIGGER trigger_update_messages_timestamp
BEFORE UPDATE ON messages FOR EACH ROW
EXECUTE FUNCTION update_ticket_timestamp();

-- ============================================
-- CONSTRAINTS & INTEGRITY
-- ============================================

-- Check constraints
ALTER TABLE companies ADD CONSTRAINT check_plan_tier 
  CHECK (plan_tier IN ('starter', 'professional', 'enterprise'));

ALTER TABLE tickets ADD CONSTRAINT check_ticket_status_logic
  CHECK (
    (status = 'resolved' AND resolved_at IS NOT NULL) OR 
    (status != 'resolved')
  );

-- ============================================
-- SAMPLE DATA FOR PERMISSIONS
-- ============================================

INSERT INTO permissions (name, description, resource, action) VALUES
  ('tickets.create', 'Create new tickets', 'tickets', 'create'),
  ('tickets.read', 'View tickets', 'tickets', 'read'),
  ('tickets.update', 'Update tickets', 'tickets', 'update'),
  ('tickets.delete', 'Delete tickets', 'tickets', 'delete'),
  ('tickets.assign', 'Assign tickets', 'tickets', 'update'),
  ('qa.review', 'Review tickets in QA', 'qa', 'approve'),
  ('qa.approve', 'Approve QA tickets', 'qa', 'approve'),
  ('qa.reject', 'Reject QA tickets', 'qa', 'reject'),
  ('chat.create', 'Create chat rooms', 'chat', 'create'),
  ('chat.message', 'Send messages', 'chat', 'create'),
  ('reports.view', 'View analytics', 'reports', 'read'),
  ('users.manage', 'Manage users', 'users', 'update'),
  ('gitlab.sync', 'Sync with GitLab', 'gitlab', 'create')
ON CONFLICT DO NOTHING;