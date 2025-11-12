import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AppModule } from '@/app.module';

/**
 * Create a test instance of the NestJS application
 * This function sets up the entire app module with all dependencies
 * for integration/E2E testing
 *
 * @returns Initialized NestJS application instance
 *
 * @example
 * ```typescript
 * let app: INestApplication;
 *
 * beforeAll(async () => {
 *   app = await createTestApp();
 * });
 *
 * afterAll(async () => {
 *   await closeTestApp(app);
 * });
 * ```
 */
export async function createTestApp(): Promise<INestApplication> {
  const moduleFixture: TestingModule = await Test.createTestingModule({
    imports: [AppModule],
  }).compile();

  const app = moduleFixture.createNestApplication();

  // Apply same global pipes as production
  // This ensures tests match production behavior
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strip properties that don't have decorators
      transform: true, // Auto-transform payloads to DTO instances
      forbidNonWhitelisted: true, // Throw error on unexpected properties
      transformOptions: {
        enableImplicitConversion: true, // Convert string to number, etc
      },
    }),
  );

  // Initialize the application
  await app.init();

  return app;
}

/**
 * Close and cleanup a test application instance
 * Always call this in afterAll to prevent memory leaks
 *
 * @param app - NestJS application instance to close
 *
 * @example
 * ```typescript
 * afterAll(async () => {
 *   await closeTestApp(app);
 * });
 * ```
 */
export async function closeTestApp(app: INestApplication): Promise<void> {
  if (app) {
    await app.close();
  }
}

/**
 * Get HTTP server from app for supertest
 * This is a convenience helper for cleaner test code
 *
 * @param app - NestJS application instance
 * @returns HTTP server instance
 *
 * @example
 * ```typescript
 * const server = getHttpServer(app);
 * await request(server).get('/health').expect(200);
 * ```
 */
export function getHttpServer(app: INestApplication) {
  return app.getHttpServer();
}
