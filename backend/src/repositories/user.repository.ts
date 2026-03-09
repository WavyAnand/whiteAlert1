import { Injectable } from '@nestjs/common';

@Injectable()
export class UserRepository {
  findAll() {
    // placeholder - connect to database
    return [];
  }

  findOne(id: string) {
    return null;
  }

  create(data: any) {
    return data;
  }
}
