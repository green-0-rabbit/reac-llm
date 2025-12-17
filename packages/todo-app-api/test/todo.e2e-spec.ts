import { MikroORM } from '@mikro-orm/sqlite';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import MikroOrmCLIConfig from '../src/database/mikro-orm.config';
import { createTestingModule } from './utils/create-testing-module';

async function initApp() {
  process.env.DATABASE_SCHEMA = "dbtest.db";
  process.env.DATABASE_HOST = process.env.DATABASE_HOST || "localhost";
  process.env.DATABASE_PORT = process.env.DATABASE_PORT || "5432";
  process.env.DATABASE_USERNAME = process.env.DATABASE_USERNAME || "admin";
  process.env.DATABASE_PASSWORD = process.env.DATABASE_PASSWORD || "secretadmin";
  
  // Setup Azure Storage env vars for testing
  process.env.AZURE_STORAGE_SERVICE_URI = "https://127.0.0.1:10000/devstoreaccount1";
  process.env.AZURE_STORAGE_CONTAINER_NAME = "todo-attachments-test";
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

  let orm: MikroORM;
  // eslint-disable-next-line prefer-const
  orm = await MikroORM.init({
    ...MikroOrmCLIConfig,
    dbName: "dbtest.db",
    // ...
  });

  const { bootstrappedApp, url } = await createTestingModule();

  return { orm, bootstrappedApp, url };
}


describe('TodoController (e2e)', () => {
  let app: INestApplication<App>;
  let orm: MikroORM;
  beforeAll(async () => {
    const { bootstrappedApp, url, orm: _orm } = await initApp();
    orm = _orm;
    const seeder = orm.seeder;

    await orm.schema.refreshDatabase();
    await seeder.seed();

    app = bootstrappedApp;
  });

  afterAll(async () => {
    await app.close();
    await orm.close();
  });

  let createdTodoId: string;

  it('/todos (POST)', async () => {
    const response = await request(app.getHttpServer())
      .post('/todos')
      .send({ title: 'E2E Test Todo', isCompleted: false })
      .expect(200);

    expect(response.body).toHaveProperty('id');
    expect(response.body.title).toBe('E2E Test Todo');
    createdTodoId = response.body.id;
  });

  it('/todos (GET)', async () => {
    const response = await request(app.getHttpServer())
      .get('/todos')
      .expect(200);
    
    expect(Array.isArray(response.body)).toBe(true);
    const found = response.body.find((t: any) => t.id === createdTodoId);
    expect(found).toBeDefined();
  });

  it('/todos/:id (GET)', async () => {
    const response = await request(app.getHttpServer())
      .get(`/todos/${createdTodoId}`)
      .expect(200);

    expect(response.body.id).toBe(createdTodoId);
    expect(response.body.title).toBe('E2E Test Todo');
  });

  it('/todos/:id (PUT)', async () => {
    const response = await request(app.getHttpServer())
      .put(`/todos/${createdTodoId}`)
      .send({ title: 'Updated E2E Todo', isCompleted: true })
      .expect(200);

    expect(response.body.title).toBe('Updated E2E Todo');
    expect(response.body.isCompleted).toBe(true);
  });

  it('/todos/:id/attachment (POST)', async () => {
    const buffer = Buffer.from('test file content');
    const response = await request(app.getHttpServer())
      .post(`/todos/${createdTodoId}/attachment`)
      .attach('file', buffer, 'test.txt')
      .expect(201);

    expect(response.body).toHaveProperty('attachmentUrl');
    expect(response.body.attachmentUrl).toContain('test.txt');
  });

  it('/todos/:id (DELETE)', async () => {
    await request(app.getHttpServer())
      .delete(`/todos/${createdTodoId}`)
      .expect(200);
  });

  it('/todos/:id (GET) - Fail after delete', async () => {
    await request(app.getHttpServer())
      .get(`/todos/${createdTodoId}`)
      .expect(404);
  });
});
