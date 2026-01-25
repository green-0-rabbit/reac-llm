import { Controller, Get, Query } from '@nestjs/common';
import { AIService } from './ai.service';
import { Public } from '../common/decorators/public.decorator'; // Assuming public access for testing easier

@Controller('ai')
export class AIController {
  constructor(private readonly aiService: AIService) {}

  @Public() // Make it public for easier testing without auth token initially
  @Get('test')
  async testConnection(@Query('prompt') prompt?: string) {
    const result = await this.aiService.testAI(prompt);
    // Returning the raw result string/JSON from the client
    try {
        return JSON.parse(result);
    } catch {
        return { raw: result };
    }
  }
}
