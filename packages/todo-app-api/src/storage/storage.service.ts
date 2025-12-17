import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BlobServiceClient, ContainerClient } from '@azure/storage-blob';
import { DefaultAzureCredential } from '@azure/identity';

@Injectable()
export class StorageService implements OnModuleInit {
  private blobServiceClient: BlobServiceClient;
  private containerClient: ContainerClient;
  private readonly logger = new Logger(StorageService.name);
  private readonly containerName: string;

  constructor(private readonly configService: ConfigService) {
    const serviceUri: string =
      this.configService.get<string>('AZURE_STORAGE_SERVICE_URI') || '';
    this.containerName =
      this.configService.get<string>('AZURE_STORAGE_CONTAINER_NAME') || '';

    this.blobServiceClient = new BlobServiceClient(
      serviceUri,
      new DefaultAzureCredential(),
    );
    this.containerClient = this.blobServiceClient.getContainerClient(
      this.containerName,
    );
  }

  async onModuleInit() {
    this.logger.log(
      `Initializing Azure Storage container: ${this.containerName}`,
    );
    await this.containerClient.createIfNotExists();
  }

  async uploadFile(
    filename: string,
    buffer: Buffer,
    mimetype: string,
  ): Promise<string> {
    const blockBlobClient = this.containerClient.getBlockBlobClient(filename);

    await blockBlobClient.uploadData(buffer, {
      blobHTTPHeaders: { blobContentType: mimetype },
    });

    return blockBlobClient.url;
  }

  async deleteFile(filename: string): Promise<void> {
    const blockBlobClient = this.containerClient.getBlockBlobClient(filename);
    await blockBlobClient.deleteIfExists();
  }
}
