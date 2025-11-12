import { describe, it, expect } from 'vitest';
import {
  generateTestToken,
  generateTestUserToken,
  generateAdminToken,
  generateAgentToken,
  getAuthHeader,
  decodeTestToken,
  generateExpiredToken,
} from './auth.helper';
import {
  assertValidUUID,
  assertValidEmail,
  assertTimestamp,
  assertPaginatedResponse,
  assertHasTimestamps,
  assertErrorResponse,
  assertRecentDate,
  assertArrayContains,
  assertArraysEqual,
  assertMatchesPartial,
  assertValidUrl,
  assertInRange,
} from './assert.helper';

describe('Test Helpers', () => {
  describe('Auth Helper', () => {
    describe('generateTestToken', () => {
      it('should generate a valid JWT token', () => {
        const token = generateTestToken({ userId: '123' });
        expect(token).toBeDefined();
        expect(typeof token).toBe('string');
        expect(token.split('.')).toHaveLength(3); // JWT has 3 parts
      });

      it('should include payload in token', () => {
        const payload = { userId: '123', role: 'admin' };
        const token = generateTestToken(payload);
        const decoded = decodeTestToken(token);
        expect(decoded.userId).toBe('123');
        expect(decoded.role).toBe('admin');
      });

      it('should support custom expiration', () => {
        const token = generateTestToken({ userId: '123' }, '2h');
        expect(token).toBeDefined();
      });
    });

    describe('generateTestUserToken', () => {
      it('should generate user token with default role', () => {
        const token = generateTestUserToken('user-123');
        const decoded = decodeTestToken(token);
        expect(decoded.userId).toBe('user-123');
        expect(decoded.role).toBe('agent');
        expect(decoded.type).toBe('access');
      });

      it('should generate user token with custom role', () => {
        const token = generateTestUserToken('user-123', 'administrator');
        const decoded = decodeTestToken(token);
        expect(decoded.role).toBe('administrator');
      });
    });

    describe('generateAdminToken', () => {
      it('should generate admin token', () => {
        const token = generateAdminToken();
        const decoded = decodeTestToken(token);
        expect(decoded.role).toBe('administrator');
      });

      it('should use custom user ID', () => {
        const token = generateAdminToken('custom-admin');
        const decoded = decodeTestToken(token);
        expect(decoded.userId).toBe('custom-admin');
      });
    });

    describe('generateAgentToken', () => {
      it('should generate agent token', () => {
        const token = generateAgentToken();
        const decoded = decodeTestToken(token);
        expect(decoded.role).toBe('agent');
      });
    });

    describe('getAuthHeader', () => {
      it('should format Bearer token header', () => {
        const token = 'test-token-123';
        const header = getAuthHeader(token);
        expect(header).toEqual({ Authorization: 'Bearer test-token-123' });
      });
    });

    describe('generateExpiredToken', () => {
      it('should generate an expired token', () => {
        const token = generateExpiredToken();
        const decoded = decodeTestToken(token);
        expect(decoded.iat).toBeLessThan(Math.floor(Date.now() / 1000));
      });
    });
  });

  describe('Assert Helper', () => {
    describe('assertValidUUID', () => {
      it('should pass for valid UUIDs', () => {
        expect(() => assertValidUUID('123e4567-e89b-12d3-a456-426614174000')).not.toThrow();
      });

      it('should fail for invalid UUIDs', () => {
        expect(() => assertValidUUID('invalid-uuid')).toThrow();
        expect(() => assertValidUUID('12345')).toThrow();
      });
    });

    describe('assertValidEmail', () => {
      it('should pass for valid emails', () => {
        expect(() => assertValidEmail('user@example.com')).not.toThrow();
        expect(() => assertValidEmail('test.user@domain.co.uk')).not.toThrow();
      });

      it('should fail for invalid emails', () => {
        expect(() => assertValidEmail('invalid')).toThrow();
        expect(() => assertValidEmail('user@')).toThrow();
        expect(() => assertValidEmail('@domain.com')).toThrow();
      });
    });

    describe('assertTimestamp', () => {
      it('should pass for valid timestamps', () => {
        expect(() => assertTimestamp(new Date())).not.toThrow();
        expect(() => assertTimestamp(Date.now())).not.toThrow();
        expect(() => assertTimestamp('2024-01-01T00:00:00Z')).not.toThrow();
      });

      it('should fail for invalid timestamps', () => {
        expect(() => assertTimestamp('invalid-date')).toThrow();
        expect(() => assertTimestamp(undefined)).toThrow();
      });
    });

    describe('assertPaginatedResponse', () => {
      it('should pass for valid paginated responses', () => {
        const response = {
          data: [{ id: 1 }, { id: 2 }],
          meta: {
            total: 10,
            page: 1,
            perPage: 2,
          },
        };
        expect(() => assertPaginatedResponse(response)).not.toThrow();
      });

      it('should fail for invalid structure', () => {
        expect(() => assertPaginatedResponse({})).toThrow();
        expect(() => assertPaginatedResponse({ data: [], meta: {} })).toThrow();
      });
    });

    describe('assertHasTimestamps', () => {
      it('should pass for objects with timestamps', () => {
        const obj = {
          id: 1,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        expect(() => assertHasTimestamps(obj)).not.toThrow();
      });

      it('should check deletedAt when requested', () => {
        const obj = {
          id: 1,
          createdAt: new Date(),
          updatedAt: new Date(),
          deletedAt: new Date(),
        };
        expect(() => assertHasTimestamps(obj, true)).not.toThrow();
      });
    });

    describe('assertErrorResponse', () => {
      it('should pass for valid error responses', () => {
        const response = {
          statusCode: 404,
          message: 'Not Found',
          error: 'Not Found',
        };
        expect(() => assertErrorResponse(response, 404)).not.toThrow();
      });

      it('should check message content', () => {
        const response = {
          statusCode: 400,
          message: 'Invalid input provided',
        };
        expect(() => assertErrorResponse(response, 400, 'Invalid')).not.toThrow();
      });
    });

    describe('assertRecentDate', () => {
      it('should pass for recent dates', () => {
        const now = new Date();
        expect(() => assertRecentDate(now, 10)).not.toThrow();
      });

      it('should fail for old dates', () => {
        const old = new Date(Date.now() - 10000); // 10 seconds ago
        expect(() => assertRecentDate(old, 5)).toThrow();
      });
    });

    describe('assertArrayContains', () => {
      it('should pass when condition matches', () => {
        const arr = [{ id: 1 }, { id: 2 }, { id: 3 }];
        expect(() => assertArrayContains(arr, item => item.id === 2)).not.toThrow();
      });

      it('should fail when condition does not match', () => {
        const arr = [{ id: 1 }, { id: 2 }];
        expect(() => assertArrayContains(arr, item => item.id === 3)).toThrow();
      });
    });

    describe('assertArraysEqual', () => {
      it('should pass for equal arrays (order independent)', () => {
        expect(() => assertArraysEqual([1, 2, 3], [3, 1, 2])).not.toThrow();
      });

      it('should fail for different arrays', () => {
        expect(() => assertArraysEqual([1, 2], [1, 2, 3])).toThrow();
      });
    });

    describe('assertMatchesPartial', () => {
      it('should pass when object matches partial', () => {
        const obj = { id: 1, name: 'Test', email: 'test@example.com' };
        expect(() =>
          assertMatchesPartial(obj, { name: 'Test', email: 'test@example.com' }),
        ).not.toThrow();
      });

      it('should fail when values do not match', () => {
        const obj = { id: 1, name: 'Test' };
        expect(() => assertMatchesPartial(obj, { name: 'Different' })).toThrow();
      });
    });

    describe('assertValidUrl', () => {
      it('should pass for valid URLs', () => {
        expect(() => assertValidUrl('https://example.com')).not.toThrow();
        expect(() => assertValidUrl('http://localhost:3000/api')).not.toThrow();
      });

      it('should fail for invalid URLs', () => {
        expect(() => assertValidUrl('not a url')).toThrow();
        expect(() => assertValidUrl('ftp://example.com')).toThrow();
      });
    });

    describe('assertInRange', () => {
      it('should pass for values in range', () => {
        expect(() => assertInRange(5, 1, 10)).not.toThrow();
        expect(() => assertInRange(1, 1, 10)).not.toThrow(); // min boundary
        expect(() => assertInRange(10, 1, 10)).not.toThrow(); // max boundary
      });

      it('should fail for values out of range', () => {
        expect(() => assertInRange(0, 1, 10)).toThrow();
        expect(() => assertInRange(11, 1, 10)).toThrow();
      });
    });
  });
});
