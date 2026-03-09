import { Injectable } from '@nestjs/common';
import { UserRepository } from '../repositories/user.repository';

@Injectable()
export class UserService {
  constructor(private readonly userRepo: UserRepository) {}

  findAll() {
    return this.userRepo.findAll();
  }

  findOne(id: string) {
    return this.userRepo.findOne(id);
  }

  findByEmail(email: string) {
    return this.userRepo.findByEmail(email);
  }

  create(data: any) {
    return this.userRepo.create(data);
  }
}
