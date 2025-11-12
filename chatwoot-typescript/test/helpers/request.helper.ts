import request, { Test } from 'supertest';
import { INestApplication } from '@nestjs/common';
import { getAuthHeader } from './auth.helper';

/**
 * Fluent API wrapper around supertest for easier HTTP testing
 * Provides chainable methods for authenticated and unauthenticated requests
 *
 * @example
 * ```typescript
 * const req = new TestRequest(app);
 *
 * // Simple GET
 * await req.get('/health').expect(200);
 *
 * // Authenticated POST
 * const token = generateTestUserToken('123');
 * await req.withAuth(token).post('/api/v1/conversations', { message: 'Hello' });
 *
 * // Multiple requests with same auth
 * const authReq = req.withAuth(token);
 * await authReq.get('/api/v1/profile');
 * await authReq.post('/api/v1/messages', { text: 'Hi' });
 * ```
 */
export class TestRequest {
  private authToken?: string;

  constructor(private app: INestApplication) {}

  /**
   * Make a GET request
   *
   * @param url - Request URL
   * @returns Supertest Test instance
   */
  get(url: string): Test {
    const req = request(this.app.getHttpServer()).get(url);
    return this.applyAuth(req);
  }

  /**
   * Make a POST request
   *
   * @param url - Request URL
   * @param data - Request body data
   * @returns Supertest Test instance
   */
  post(url: string, data?: any): Test {
    const req = request(this.app.getHttpServer()).post(url);
    if (data !== undefined) {
      req.send(data);
    }
    return this.applyAuth(req);
  }

  /**
   * Make a PUT request
   *
   * @param url - Request URL
   * @param data - Request body data
   * @returns Supertest Test instance
   */
  put(url: string, data?: any): Test {
    const req = request(this.app.getHttpServer()).put(url);
    if (data !== undefined) {
      req.send(data);
    }
    return this.applyAuth(req);
  }

  /**
   * Make a PATCH request
   *
   * @param url - Request URL
   * @param data - Request body data
   * @returns Supertest Test instance
   */
  patch(url: string, data?: any): Test {
    const req = request(this.app.getHttpServer()).patch(url);
    if (data !== undefined) {
      req.send(data);
    }
    return this.applyAuth(req);
  }

  /**
   * Make a DELETE request
   *
   * @param url - Request URL
   * @returns Supertest Test instance
   */
  delete(url: string): Test {
    const req = request(this.app.getHttpServer()).delete(url);
    return this.applyAuth(req);
  }

  /**
   * Set authentication token for subsequent requests
   * Returns a new instance to allow chaining
   *
   * @param token - JWT token
   * @returns New TestRequest instance with auth
   *
   * @example
   * ```typescript
   * const token = generateTestUserToken('123');
   * const authReq = req.withAuth(token);
   * await authReq.get('/protected');
   * ```
   */
  withAuth(token: string): TestRequest {
    const newInstance = new TestRequest(this.app);
    newInstance.authToken = token;
    return newInstance;
  }

  /**
   * Apply authentication header if token is set
   * Internal helper method
   */
  private applyAuth(req: Test): Test {
    if (this.authToken) {
      const authHeader = getAuthHeader(this.authToken);
      req.set(authHeader);
    }
    return req;
  }

  /**
   * Make a request with custom headers
   *
   * @param method - HTTP method
   * @param url - Request URL
   * @param headers - Custom headers
   * @param data - Request body (optional)
   * @returns Supertest Test instance
   */
  withHeaders(
    method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE',
    url: string,
    headers: Record<string, string>,
    data?: any,
  ): Test {
    let req: Test;

    switch (method) {
      case 'GET':
        req = this.get(url);
        break;
      case 'POST':
        req = this.post(url, data);
        break;
      case 'PUT':
        req = this.put(url, data);
        break;
      case 'PATCH':
        req = this.patch(url, data);
        break;
      case 'DELETE':
        req = this.delete(url);
        break;
    }

    Object.entries(headers).forEach(([key, value]) => {
      req.set(key, value);
    });

    return req;
  }
}

/**
 * Create a TestRequest instance for an app
 * Convenience function for cleaner test code
 *
 * @param app - NestJS application instance
 * @returns TestRequest instance
 *
 * @example
 * ```typescript
 * const req = createTestRequest(app);
 * await req.get('/health').expect(200);
 * ```
 */
export function createTestRequest(app: INestApplication): TestRequest {
  return new TestRequest(app);
}
