-- Database schema for WhiteAlert SaaS Platform
-- Complete schema with all Phase 1-3 features
-- See DATABASE_SCHEMA.md for complete documentation

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
  plan_tier VARCHAR(50) DEFAULT 'starter',
  max_users INTEGER DEFAULT 10,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Roles & Permissions
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  is_system_role BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  resource VARCHAR(100) NOT NULL,
  action VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  UNIQUE(role_id, permission_id)
);

-- Departments
CREATE TABLE departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  type department_type DEFAULT 'other',
  description TEXT,
  parent_department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
  phone VARCHAR(20),
  avatar_url VARCHAR(512),
  role user_role DEFAULT 'user',
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  last_login_at TIMESTAMP,
  sso_provider VARCHAR(50),
  timezone VARCHAR(50) DEFAULT 'UTC',
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, email)
);

ALTER TABLE departments ADD COLUMN manager_id UUID REFERENCES users(id) ON DELETE SET NULL;

-- ============================================
-- CHAT SYSTEM
-- ============================================

CREATE TABLE chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255),
  description TEXT,
  type VARCHAR(50) NOT NULL,
  is_public BOOLEAN DEFAULT false,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE room_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  last_read_at TIMESTAMP,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(room_id, user_id)
);

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type message_type DEFAULT 'text',
  file_url VARCHAR(512),
  mentioned_user_ids UUID[] DEFAULT '{}',
  is_edited BOOLEAN DEFAULT false,
  parent_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TICKETING SYSTEM
-- ============================================

CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  ticket_number VARCHAR(20) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status ticket_status DEFAULT 'open',
  priority ticket_priority DEFAULT 'medium',
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  assigned_to_department UUID REFERENCES departments(id) ON DELETE SET NULL,
  created_from_message UUID REFERENCES messages(id) ON DELETE SET NULL,
  source_channel VARCHAR(50),
  customer_email VARCHAR(255),
  customer_name VARCHAR(255),
  due_date TIMESTAMP,
  resolved_at TIMESTAMP,
  tags VARCHAR(100)[] DEFAULT '{}',
  custom_fields JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, ticket_number)
);

CREATE TABLE ticket_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  activity_type VARCHAR(50) NOT NULL,
  old_value VARCHAR(255),
  new_value VARCHAR(255),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- QA VALIDATION SYSTEM
-- ============================================

CREATE TABLE qa_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  initiated_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  assigned_to UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  status qa_status DEFAULT 'pending',
  review_comments TEXT,
  approval_date TIMESTAMP,
  requires_changes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);

CREATE TABLE qa_validation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  rule_type VARCHAR(50) NOT NULL,
  conditions JSONB NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- GITLAB INTEGRATION
-- ============================================

CREATE TABLE gitlab_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  gitlab_url VARCHAR(255) NOT NULL,
  gitlab_token VARCHAR(255),
  project_id VARCHAR(100) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  last_synced_at TIMESTAMP,
  webhook_secret VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id)
);

CREATE TABLE ticket_gitlab_mappings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  gitlab_issue_id VARCHAR(100) NOT NULL,
  gitlab_issue_number INTEGER NOT NULL,
  last_synced_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(ticket_id, gitlab_issue_id)
);

-- ============================================
-- NOTIFICATIONS
-- ============================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  status notification_status DEFAULT 'unread',
  title VARCHAR(255) NOT NULL,
  message TEXT,
  related_ticket_id UUID REFERENCES tickets(id) ON DELETE SET NULL,
  action_url VARCHAR(512),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP
);

CREATE TABLE notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  email_on_ticket_assigned BOOLEAN DEFAULT true,
  email_on_qa_review BOOLEAN DEFAULT true,
  push_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- AUDIT LOGS
-- ============================================

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  resource_type VARCHAR(100) NOT NULL,
  resource_id UUID NOT NULL,
  action VARCHAR(50) NOT NULL,
  old_data JSONB,
  new_data JSONB,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- FILES
-- ============================================

CREATE TABLE files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(50),
  file_size BIGINT NOT NULL,
  storage_path VARCHAR(512) NOT NULL,
  related_ticket_id UUID REFERENCES tickets(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_companies_slug ON companies(slug);
CREATE INDEX idx_roles_company_id ON roles(company_id);
CREATE INDEX idx_departments_company_id ON departments(company_id);
CREATE INDEX idx_users_company_id ON users(company_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_department_id ON users(department_id);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_chat_rooms_company_id ON chat_rooms(company_id);
CREATE INDEX idx_messages_room_id ON messages(room_id);
CREATE INDEX idx_messages_company_id ON messages(company_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_room_participants_room_id ON room_participants(room_id);
CREATE INDEX idx_tickets_company_id ON tickets(company_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to);
CREATE INDEX idx_tickets_created_at ON tickets(created_at);
CREATE INDEX idx_ticket_activities_ticket_id ON ticket_activities(ticket_id);
CREATE INDEX idx_qa_reviews_ticket_id ON qa_reviews(ticket_id);
CREATE INDEX idx_qa_reviews_status ON qa_reviews(status);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_audit_logs_company_id ON audit_logs(company_id);
CREATE INDEX idx_files_company_id ON files(company_id);

-- Phase 2: Ticketing and QA

CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'open',
  priority VARCHAR(50) DEFAULT 'normal',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ticket_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tickets_company_id ON tickets(company_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_ticket_comments_ticket_id ON ticket_comments(ticket_id);