import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AIClient } from './ai.client';
import { AIService } from './ai.service';
import { AIController } from './ai.controller';

@Module({
  imports: [ConfigModule],
  controllers: [AIController],
  providers: [AIClient, AIService],
  exports: [AIService],
})
export class AIModule {}
