import { Module, Global } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaService } from './prisma.service';
import { PrismaTestController } from './prisma-test.controller';

@Global()
@Module({
  imports: [ConfigModule],
  controllers: [PrismaTestController],
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
