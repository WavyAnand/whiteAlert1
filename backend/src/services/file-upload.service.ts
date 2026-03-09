import { Injectable, BadRequestException } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class FileUploadService {
  private readonly uploadDir = path.join(process.cwd(), 'uploads');

  constructor() {
    this.ensureUploadDir();
  }

  private ensureUploadDir() {
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  async uploadProfilePhoto(file: Express.Multer.File): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Validate file type
    const allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedMimes.includes(file.mimetype)) {
      throw new BadRequestException('Only image files are allowed');
    }

    // Validate file size (max 5MB)
    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      throw new BadRequestException('File size exceeds 5MB limit');
    }

    try {
      // Generate unique filename
      const ext = path.extname(file.originalname);
      const filename = `profile-${uuidv4()}${ext}`;
      const filepath = path.join(this.uploadDir, filename);

      // Save file
      fs.writeFileSync(filepath, file.buffer);

      // Return URL or relative path
      return `/uploads/${filename}`;
    } catch (error) {
      throw new BadRequestException('Failed to upload file');
    }
  }

  async deleteProfilePhoto(photoUrl: string): Promise<void> {
    try {
      if (photoUrl && photoUrl.includes('/uploads/')) {
        const filename = path.basename(photoUrl);
        const filepath = path.join(this.uploadDir, filename);

        if (fs.existsSync(filepath)) {
          fs.unlinkSync(filepath);
        }
      }
    } catch (error) {
      console.error('Failed to delete photo:', error);
    }
  }

  getUploadDir(): string {
    return this.uploadDir;
  }
}
