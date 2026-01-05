import { Test, TestingModule } from "@nestjs/testing";
import { AppModule } from "../../src/app.module";
import "dotenv/config";
import { INestApplication } from "@nestjs/common";
import { App } from "supertest/types";

export async function createTestingModule() {
    const moduleFixture: TestingModule = await Test.createTestingModule({
        imports: [AppModule]
    }).compile();

    const nestApp:INestApplication<App> = moduleFixture.createNestApplication();
    // if (process.env.LOCAL_TEST) {
    //     const url = "http://localhost:3001";
    //     return { nestApp, url };
    // }

    await nestApp.listen(3001);
    const url = (await nestApp.getUrl()).replace("[::1]", "localhost");
    const bootstrappedApp = await nestApp.init();
    //   return { nestApp, url, bootstrappedApp };
    return { url, bootstrappedApp };

}