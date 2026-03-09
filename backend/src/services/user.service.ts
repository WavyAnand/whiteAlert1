import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { UserRepository } from '../repositories/user.repository';
import * as bcrypt from 'bcrypt';
import { CreateUserDto, UpdateUserProfileDto, AssignRoleDto } from '../dto/user.dto';

@Injectable()
export class UserService {
  constructor(private readonly userRepo: UserRepository) {}

  async findAll(companyId: string, page = 1, limit = 50) {
    const offset = (page - 1) * limit;
    return this.userRepo.findAll(companyId, limit, offset);
  }

  async findOne(id: string) {
    const user = await this.userRepo.findOne(id);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  async findByEmail(email: string, companyId?: string) {
    return this.userRepo.findByEmail(email, companyId);
  }

  async createUser(dto: CreateUserDto) {
    // Check if user already exists
    const existingUser = await this.findByEmail(dto.email, dto.company_id);
    if (existingUser) {
      throw new BadRequestException('User with this email already exists');
    }

    // Hash password
    const password_hash = await bcrypt.hash(dto.password, 10);

    const userData = {
      ...dto,
      password_hash,
    };
    delete userData.password;

    return this.userRepo.create(userData);
  }

  async updateProfile(userId: string, dto: UpdateUserProfileDto) {
    const user = await this.findOne(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const updateData = { ...dto };
    return this.userRepo.update(userId, updateData);
  }

  async uploadProfilePhoto(userId: string, photoUrl: string) {
    const user = await this.findOne(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.userRepo.updateProfilePhoto(userId, photoUrl);
  }

  async assignRole(userId: string, dto: AssignRoleDto) {
    const user = await this.findOne(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // TODO: Validate role_id exists and belongs to same company
    return this.userRepo.assignRole(userId, dto.role_id);
  }

  async listUsersByCompany(companyId: string, page = 1, limit = 50) {
    const offset = (page - 1) * limit;
    const users = await this.userRepo.findByCompany(companyId, limit, offset);
    const total = await this.userRepo.countByCompany(companyId);

    return {
      data: users,
      total,
      page,
      limit,
      pages: Math.ceil(total / limit),
    };
  }

  async listUsersByDepartment(departmentId: string) {
    return this.userRepo.findByDepartment(departmentId);
  }

  async deactivateUser(userId: string) {
    const user = await this.findOne(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.userRepo.deactivateUser(userId);
  }

  async searchUsers(companyId: string, searchTerm: string) {
    // TODO: Implement search in database
    return [];
  }
}
