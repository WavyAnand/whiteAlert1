/**
 * User Management Module - API Usage Examples
 *
 * This file demonstrates how to use the user management endpoints
 */

// ============================================================================
// 1. CREATE USER
// ============================================================================
/**
 * POST /users
 * Headers: Authorization: Bearer <jwt_token> (admin role required)
 * Body:
 * {
 *   "email": "john@example.com",
 *   "password": "SecurePassword123",
 *   "first_name": "John",
 *   "last_name": "Doe",
 *   "department_id": "dept-uuid",
 *   "role": "user"
 * }
 */

// ============================================================================
// 2. LIST USERS BY COMPANY
// ============================================================================
/**
 * GET /users?page=1&limit=50
 * Headers: Authorization: Bearer <jwt_token> (admin/manager role required)
 * Query Parameters:
 *   - page (default: 1)
 *   - limit (default: 50)
 *
 * Response:
 * {
 *   "data": [
 *     {
 *       "id": "user-uuid",
 *       "email": "john@example.com",
 *       "first_name": "John",
 *       "last_name": "Doe",
 *       "role_id": "role-uuid",
 *       "department_id": "dept-uuid",
 *       "is_active": true,
 *       "created_at": "2026-03-09T12:00:00Z"
 *     }
 *   ],
 *   "total": 10,
 *   "page": 1,
 *   "limit": 50,
 *   "pages": 1
 * }
 */

// ============================================================================
// 3. GET USER BY ID
// ============================================================================
/**
 * GET /users/:id
 * Headers: Authorization: Bearer <jwt_token> (admin/user role required)
 * Params: id (user UUID)
 *
 * Response: Full user object
 */

// ============================================================================
// 4. UPDATE USER PROFILE
// ============================================================================
/**
 * PUT /users/:id/profile
 * Headers: Authorization: Bearer <jwt_token>
 * Body (any combination):
 * {
 *   "first_name": "Jonathan",
 *   "last_name": "Smith",
 *   "phone": "+1-234-567-8900",
 *   "bio": "Software Engineer",
 *   "timezone": "America/New_York",
 *   "preferences": {
 *     "notifications": true,
 *     "theme": "dark"
 *   }
 * }
 *
 * Note: Users can only update their own profile (unless admin)
 */

// ============================================================================
// 5. UPLOAD PROFILE PHOTO
// ============================================================================
/**
 * POST /users/:id/profile-photo
 * Headers: Authorization: Bearer <jwt_token>
 * Body: multipart/form-data with 'file' field
 *
 * Constraints:
 *   - Max size: 5MB
 *   - Allowed types: JPEG, PNG, GIF, WebP
 *   - Field name: 'file'
 *
 * Response:
 * {
 *   "avatar_url": "/uploads/profile-<uuid>.jpg"
 * }
 *
 * Note: Users can only upload their own photo (unless admin)
 */

// ============================================================================
// 6. ASSIGN ROLE TO USER
// ============================================================================
/**
 * POST /users/:id/assign-role
 * Headers: Authorization: Bearer <jwt_token> (admin role required)
 * Body:
 * {
 *   "role_id": "role-uuid",
 *   "reason": "Promoted to Manager"
 * }
 *
 * Response: Updated user object with new role
 */

// ============================================================================
// 7. DEACTIVATE USER
// ============================================================================
/**
 * PUT /users/:id/deactivate
 * Headers: Authorization: Bearer <jwt_token> (admin role required)
 * No body required
 *
 * Response:
 * {
 *   "is_active": false
 * }
 */

// ============================================================================
// 8. LIST USERS BY DEPARTMENT
// ============================================================================
/**
 * GET /users/department/:departmentId
 * Headers: Authorization: Bearer <jwt_token> (admin/manager role required)
 * Params: departmentId (department UUID)
 *
 * Response: Array of users in department
 */

// ============================================================================
// 9. SEARCH USERS
// ============================================================================
/**
 * GET /users/search/:term
 * Headers: Authorization: Bearer <jwt_token>
 * Params: term (search term - name, email, etc.)
 *
 * Response: Array of matching users in user's company
 *
 * Note: Full-text search filtering by company
 */

// ============================================================================
// ROLE-BASED ACCESS CONTROL (RBAC)
// ============================================================================
/**
 * The following endpoints require specific roles:
 *
 * ADMIN ONLY:
 *   - POST /users (create user)
 *   - POST /users/:id/assign-role (assign role)
 *   - PUT /users/:id/deactivate (deactivate user)
 *   - GET /users (list all users)
 *
 * ADMIN + MANAGER:
 *   - GET /users (list users with pagination)
 *   - GET /users/department/:departmentId
 *
 * ADMIN + USER:
 *   - PUT /users/:id/profile (own profile only)
 *   - POST /users/:id/profile-photo (own photo only)
 *   - GET /users/:id (own user or admin)
 *   - GET /users/search/:term
 *
 * AUTHENTICATED (any role):
 *   - GET /users/:id (own profile)
 */

// ============================================================================
// EXAMPLE: cURL Commands
// ============================================================================

/**
 * 1. Create User
 * curl -X POST http://localhost:5000/users \
 *   -H "Authorization: Bearer YOUR_JWT_TOKEN" \
 *   -H "Content-Type: application/json" \
 *   -d '{
 *     "email":"user@example.com",
 *     "password":"SecurePass123",
 *     "first_name":"John",
 *     "last_name":"Doe"
 *   }'
 */

/**
 * 2. Update Profile
 * curl -X PUT http://localhost:5000/users/user-id/profile \
 *   -H "Authorization: Bearer YOUR_JWT_TOKEN" \
 *   -H "Content-Type: application/json" \
 *   -d '{
 *     "first_name":"Jane",
 *     "phone":"+1-234-567-8900"
 *   }'
 */

/**
 * 3. Upload Profile Photo
 * curl -X POST http://localhost:5000/users/user-id/profile-photo \
 *   -H "Authorization: Bearer YOUR_JWT_TOKEN" \
 *   -F "file=@/path/to/photo.jpg"
 */

/**
 * 4. Assign Role
 * curl -X POST http://localhost:5000/users/user-id/assign-role \
 *   -H "Authorization: Bearer YOUR_JWT_TOKEN" \
 *   -H "Content-Type: application/json" \
 *   -d '{
 *     "role_id":"role-uuid",
 *     "reason":"Promoted to Manager"
 *   }'
 */

/**
 * 5. List Users by Company
 * curl -X GET "http://localhost:5000/users?page=1&limit=50" \
 *   -H "Authorization: Bearer YOUR_JWT_TOKEN"
 */

/**
 * 6. Search Users
 * curl -X GET "http://localhost:5000/users/search/john" \
 *   -H "Authorization: Bearer YOUR_JWT_TOKEN"
 */

/**
 * 7. Deactivate User
 * curl -X PUT http://localhost:5000/users/user-id/deactivate \
 *   -H "Authorization: Bearer YOUR_JWT_TOKEN"
 */

export {};
