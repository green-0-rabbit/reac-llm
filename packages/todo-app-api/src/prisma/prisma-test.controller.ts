import { Controller, Get } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Controller('prisma-test')
export class PrismaTestController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async testConnection() {
    // Determine the current user and database
    // "SELECT current_user, current_database()"
    const result = await this.prisma.$queryRaw`SELECT current_user, current_database()`;
    return {
      message: 'Prisma connection successful',
      info: result,
    };
  }

  @Get('todos')
  async getTodos() {
      // Basic check on the Todo table
      return this.prisma.todo.findMany({ take: 5 });
  }
}
