import { describe, it, expect } from 'vitest';
import request from 'supertest';
import express from 'express';

/**
 * Sanity test to verify Supertest works correctly
 * This test doesn't require the full NestJS app to verify HTTP testing infrastructure
 */
describe('Supertest Sanity Test', () => {
  it('should be able to make HTTP GET requests', async () => {
    // Create a simple Express app for testing
    const app = express();
    app.get('/test', (req, res) => {
      res.json({ message: 'test successful' });
    });

    const response = await request(app).get('/test').expect(200);

    expect(response.body).toEqual({ message: 'test successful' });
  });

  it('should be able to test POST requests', async () => {
    const app = express();
    app.use(express.json());
    app.post('/echo', (req, res) => {
      res.json(req.body);
    });

    const testData = { name: 'test', value: 123 };
    const response = await request(app).post('/echo').send(testData).expect(200);

    expect(response.body).toEqual(testData);
  });

  it('should handle 404 errors', async () => {
    const app = express();

    await request(app).get('/nonexistent').expect(404);
  });

  it('should be able to check response headers', async () => {
    const app = express();
    app.get('/headers', (req, res) => {
      res.header('X-Custom-Header', 'test-value').json({ success: true });
    });

    const response = await request(app)
      .get('/headers')
      .expect(200)
      .expect('X-Custom-Header', 'test-value');

    expect(response.headers['x-custom-header']).toBe('test-value');
  });
});
