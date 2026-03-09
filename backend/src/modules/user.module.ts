import { Module } from '@nestjs/common';
import { UserController } from '../controllers/user.controller';
import { UserService } from '../services/user.service';
import { UserRepository } from '../repositories/user.repository';
import { FileUploadService } from '../services/file-upload.service';

@Module({
  controllers: [UserController],
  providers: [UserService, UserRepository, FileUploadService],
  exports: [UserService, FileUploadService],
})
export class UserModule {}
