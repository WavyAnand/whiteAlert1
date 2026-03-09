import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  UseGuards,
  Query,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  Req,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UserService } from '../services/user.service';
import { FileUploadService } from '../services/file-upload.service';
import { JwtAuthGuard } from '../middleware/jwt-auth.guard';
import { RolesGuard } from '../middleware/roles.guard';
import { Roles } from '../middleware/roles.decorator';
import {
  CreateUserDto,
  UpdateUserProfileDto,
  AssignRoleDto,
} from '../dto/user.dto';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UserController {
  constructor(
    private readonly userService: UserService,
    private readonly fileUploadService: FileUploadService,
  ) {}

  /**
   * Get all users in company
   * @param companyId Company ID from query or request
   * @param page Page number (default 1)
   * @param limit Items per page (default 50)
   */
  @Get()
  @Roles('admin', 'manager')
  async findAll(
    @Req() req: any,
    @Query('page') page = 1,
    @Query('limit') limit = 50,
  ) {
    const companyId = req.user.companyId;
    return this.userService.listUsersByCompany(companyId, +page, +limit);
  }

  /**
   * Get single user by ID
   */
  @Get(':id')
  @Roles('admin', 'user')
  async findOne(@Param('id') id: string) {
    return this.userService.findOne(id);
  }

  /**
   * Create new user
   */
  @Post()
  @Roles('admin')
  async create(@Body() dto: CreateUserDto, @Req() req: any) {
    // Ensure user is created in their own company
    dto.company_id = req.user.companyId;
    return this.userService.createUser(dto);
  }

  /**
   * Update user profile
   */
  @Put(':id/profile')
  @Roles('admin', 'user')
  async updateProfile(
    @Param('id') id: string,
    @Body() dto: UpdateUserProfileDto,
    @Req() req: any,
  ) {
    // Users can only update their own profile unless they're admin
    if (req.user.userId !== id && req.user.role !== 'admin') {
      throw new BadRequestException('Unauthorized to update this profile');
    }
    return this.userService.updateProfile(id, dto);
  }

  /**
   * Upload profile photo
   */
  @Post(':id/profile-photo')
  @Roles('admin', 'user')
  @UseInterceptors(FileInterceptor('file'))
  async uploadProfilePhoto(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
    @Req() req: any,
  ) {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Users can only upload their own photo unless they're admin
    if (req.user.userId !== id && req.user.role !== 'admin') {
      throw new BadRequestException('Unauthorized to upload for this user');
    }

    const photoUrl = await this.fileUploadService.uploadProfilePhoto(file);
    return this.userService.uploadProfilePhoto(id, photoUrl);
  }

  /**
   * Assign role to user
   */
  @Post(':id/assign-role')
  @Roles('admin')
  async assignRole(
    @Param('id') id: string,
    @Body() dto: AssignRoleDto,
  ) {
    return this.userService.assignRole(id, dto);
  }

  /**
   * Deactivate user
   */
  @Put(':id/deactivate')
  @Roles('admin')
  async deactivateUser(@Param('id') id: string) {
    return this.userService.deactivateUser(id);
  }

  /**
   * List users by department
   */
  @Get('department/:departmentId')
  @Roles('admin', 'manager')
  async findByDepartment(@Param('departmentId') departmentId: string) {
    return this.userService.listUsersByDepartment(departmentId);
  }

  /**
   * Search users
   */
  @Get('search/:term')
  @Roles('admin', 'user')
  async searchUsers(
    @Param('term') term: string,
    @Req() req: any,
  ) {
    const companyId = req.user.companyId;
    return this.userService.searchUsers(companyId, term);
  }
}
