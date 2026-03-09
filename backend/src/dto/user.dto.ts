export class CreateUserDto {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  company_id: string;
  department_id?: string;
  role?: string;
}

export class UpdateUserProfileDto {
  first_name?: string;
  last_name?: string;
  phone?: string;
  bio?: string;
  timezone?: string;
  preferences?: Record<string, any>;
}

export class AssignRoleDto {
  role_id: string;
  reason?: string;
}

export class UserResponseDto {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  role_id: string;
  department_id?: string;
  is_active: boolean;
  created_at: Date;
}
