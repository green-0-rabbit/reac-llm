import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DefaultAzureCredential } from '@azure/identity';

@Injectable()
export class AIClient {
  private readonly logger = new Logger(AIClient.name);
  private readonly endpoint: string;
  private readonly deployment: string;
  private readonly apiVersion: string;
  private readonly credential = new DefaultAzureCredential();

  constructor(private readonly config: ConfigService) {
    this.endpoint = (
      this.config.get<string>('API_ENDPOINT') ??
      process.env.API_ENDPOINT ??
      ''
    ).replace(/\/+$/, '');
    this.deployment =
      this.config.get<string>('API_MODEL_NAME') ??
      process.env.API_MODEL_NAME ??
      '';
    this.apiVersion =
      this.config.get<string>('API_VERSION') ??
      process.env.API_VERSION ??
      '2024-02-15-preview';

    if (!this.endpoint || !this.deployment) {
      throw new Error(
        'Missing AI configuration. Ensure API_ENDPOINT and API_MODEL_NAME are set.',
      );
    }
  }

  async testConnection(prompt: string = 'Hello, are you working?'): Promise<string> {
    const url = `${this.endpoint}/openai/deployments/${encodeURIComponent(this.deployment)}/chat/completions?api-version=${encodeURIComponent(this.apiVersion)}`;

    this.logger.log(`Testing AI Connection to: ${url}`);

    try {
      // 1. Get Managed Identity Token
      const tokenResponse = await this.credential.getToken(
        'https://cognitiveservices.azure.com/.default',
      );
      const accessToken = tokenResponse.token;
      this.logger.log('Successfully retrieved Managed Identity token');

      // 2. Make Request
      const body = {
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 50,
      };

      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(body),
      });

      const text = await res.text();

      if (!res.ok) {
        this.logger.error(`AI Request failed: ${res.status} ${text}`);
        throw new Error(`AI Request failed: ${res.status}`);
      }

      this.logger.log('AI Request successful');
      return text;
    } catch (error) {
      this.logger.error('Test connection failed', error);
      throw error;
    }
  }
}

