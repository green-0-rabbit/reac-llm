import { MikroORM } from '@mikro-orm/sqlite';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import MikroOrmCLIConfig from '../src/database/mikro-orm.config';
import { createTestingModule } from './utils/create-testing-module';

async function initApp() {
  process.env.DATABASE_SCHEMA = "dbtest.db";
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
