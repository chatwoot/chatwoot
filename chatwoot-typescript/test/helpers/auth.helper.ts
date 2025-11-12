import * as jwt from 'jsonwebtoken';

/**
 * Generate a test JWT token with custom payload
 * Uses JWT_SECRET from environment or defaults to 'test-secret'
 *
 * @param payload - JWT payload data
 * @param expiresIn - Token expiration time (default: '1h')
 * @returns Signed JWT token
 *
 * @example
 * ```typescript
 * const token = generateTestToken({ userId: '123', role: 'admin' });
 * ```
 */
export function generateTestToken(payload: any, expiresIn = '1h'): string {
  return jwt.sign(payload, process.env.JWT_SECRET || 'test-secret', {
    expiresIn,
  } as jwt.SignOptions);
}

/**
 * Generate a test user access token with user ID and role
 * Convenience method for creating user authentication tokens
 *
 * @param userId - User ID to include in token
 * @param role - User role (default: 'agent')
 * @returns Signed JWT token
 *
 * @example
 * ```typescript
 * const token = generateTestUserToken('user-123', 'administrator');
 * const authHeader = getAuthHeader(token);
 * await request(app).get('/api/v1/users').set(authHeader);
 * ```
 */
export function generateTestUserToken(userId: string, role: string = 'agent'): string {
  return generateTestToken({
    userId,
    role,
    type: 'access',
    iat: Math.floor(Date.now() / 1000),
  });
}

/**
 * Generate an admin user token for testing admin-only endpoints
 *
 * @param userId - User ID (default: 'admin-test-user')
 * @returns Signed JWT token with administrator role
 *
 * @example
 * ```typescript
 * const adminToken = generateAdminToken();
 * await request(app).delete('/api/v1/users/123').set(getAuthHeader(adminToken));
 * ```
 */
export function generateAdminToken(userId: string = 'admin-test-user'): string {
  return generateTestUserToken(userId, 'administrator');
}

/**
 * Generate an agent user token for testing agent endpoints
 *
 * @param userId - User ID (default: 'agent-test-user')
 * @returns Signed JWT token with agent role
 */
export function generateAgentToken(userId: string = 'agent-test-user'): string {
  return generateTestUserToken(userId, 'agent');
}

/**
 * Get Authorization header object for HTTP requests
 * Formats token in Bearer authentication scheme
 *
 * @param token - JWT token
 * @returns Object with Authorization header
 *
 * @example
 * ```typescript
 * const token = generateTestUserToken('123');
 * const headers = getAuthHeader(token);
 * // Returns: { Authorization: 'Bearer eyJ...' }
 * await request(app).get('/protected').set(headers);
 * ```
 */
export function getAuthHeader(token: string): { Authorization: string } {
  return { Authorization: `Bearer ${token}` };
}

/**
 * Decode a JWT token without verification
 * Useful for testing token contents
 *
 * @param token - JWT token to decode
 * @returns Decoded token payload
 *
 * @example
 * ```typescript
 * const token = generateTestUserToken('123');
 * const payload = decodeTestToken(token);
 * expect(payload.userId).toBe('123');
 * ```
 */
export function decodeTestToken(token: string): any {
  return jwt.decode(token);
}

/**
 * Generate an expired token for testing token expiration
 *
 * @param userId - User ID
 * @param role - User role
 * @returns Expired JWT token
 */
export function generateExpiredToken(userId: string = 'test-user', role: string = 'agent'): string {
  return generateTestToken(
    {
      userId,
      role,
      type: 'access',
      iat: Math.floor(Date.now() / 1000) - 7200, // 2 hours ago
    },
    '1h', // Expired 1 hour ago
  );
}
