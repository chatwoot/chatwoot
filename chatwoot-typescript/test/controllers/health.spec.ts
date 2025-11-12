import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { INestApplication } from '@nestjs/common';
import { createTestApp, closeTestApp, getHttpServer } from '../helpers/app-test.helper';

describe('HealthController (HTTP)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  }, 30000); // Increase timeout for app initialization

  afterAll(async () => {
    await closeTestApp(app);
  });

  describe('GET /health', () => {
    it('should return health check status', async () => {
      const response = await request(getHttpServer(app))
        .get('/health')
        .expect('Content-Type', /json/)
        .expect(200);

      // Verify response structure
      expect(response.body).toBeDefined();
      expect(response.body).toHaveProperty('status');

      // Verify health check details exist
      expect(response.body).toHaveProperty('info');
      expect(response.body).toHaveProperty('details');
    });

    it('should check database health', async () => {
      const response = await request(getHttpServer(app))
        .get('/health')
        .expect(200);

      // Should have database check in details
      expect(response.body.details).toHaveProperty('database');
    });

    it('should check redis health', async () => {
      const response = await request(getHttpServer(app))
        .get('/health')
        .expect(200);

      // Should have redis check in details (may be down if Redis unavailable)
      expect(response.body.details).toHaveProperty('redis');
    });

    it('should check memory health', async () => {
      const response = await request(getHttpServer(app))
        .get('/health')
        .expect(200);

      // Should have memory checks
      expect(response.body.details).toHaveProperty('memory_heap');
      expect(response.body.details).toHaveProperty('memory_rss');
    });

    it('should check disk health', async () => {
      const response = await request(getHttpServer(app))
        .get('/health')
        .expect(200);

      // Should have disk check
      expect(response.body.details).toHaveProperty('disk');
    });
  });

  describe('GET /health/live', () => {
    it('should return liveness probe status', async () => {
      const response = await request(getHttpServer(app))
        .get('/health/live')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toBeDefined();
      expect(response.body).toHaveProperty('status');
    });

    it('should always return ok for liveness (app is running)', async () => {
      const response = await request(getHttpServer(app))
        .get('/health/live')
        .expect(200);

      // Liveness just checks if app is running, so should always be ok
      expect(response.body.status).toBe('ok');
    });
  });

  describe('GET /health/ready', () => {
    it('should return readiness probe status', async () => {
      const response = await request(getHttpServer(app))
        .get('/health/ready')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toBeDefined();
      expect(response.body).toHaveProperty('status');
    });

    it('should check database for readiness', async () => {
      const response = await request(getHttpServer(app))
        .get('/health/ready')
        .expect(200);

      // Readiness should check database
      expect(response.body.details).toHaveProperty('database');
    });

    it('should check redis for readiness', async () => {
      const response = await request(getHttpServer(app))
        .get('/health/ready')
        .expect(200);

      // Readiness should check redis
      expect(response.body.details).toHaveProperty('redis');
    });
  });

  describe('Error Handling', () => {
    it('should return 404 for non-existent health endpoint', async () => {
      await request(getHttpServer(app))
        .get('/health/nonexistent')
        .expect(404);
    });

    it('should handle OPTIONS requests for CORS', async () => {
      await request(getHttpServer(app))
        .options('/health')
        .expect(200);
    });
  });
});
