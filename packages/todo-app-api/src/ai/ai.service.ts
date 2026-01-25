import { Injectable } from '@nestjs/common';
import { AIClient } from './ai.client';

@Injectable()
export class AIService {
  constructor(private readonly aiClient: AIClient) {}

  async testAI(prompt?: string): Promise<string> {
    return this.aiClient.testConnection(prompt);
  }
}
