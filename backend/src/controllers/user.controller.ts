import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { UserService } from '../services/user.service';
import { JwtAuthGuard } from '../middleware/jwt-auth.guard';
import { RolesGuard } from '../middleware/roles.guard';
import { Roles } from '../middleware/roles.decorator';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get()
  @Roles('admin')
  findAll() {
    return this.userService.findAll();
  }

  @Post()
  @Roles('admin')
  create(@Body() dto: any) {
    return this.userService.create(dto);
  }

  @Get(':id')
  @Roles('admin','user')
  findOne(@Param('id') id: string) {
    return this.userService.findOne(id);
  }
}
