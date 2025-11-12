import { expect } from 'vitest';

/**
 * Assert that a value is a valid UUID (v4)
 *
 * @param value - String to validate
 *
 * @example
 * ```typescript
 * const user = await createUser();
 * assertValidUUID(user.id);
 * ```
 */
export function assertValidUUID(value: string): void {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  expect(value).toMatch(uuidRegex);
}

/**
 * Assert that a value is a valid email address
 *
 * @param value - String to validate
 *
 * @example
 * ```typescript
 * assertValidEmail('user@example.com'); // passes
 * assertValidEmail('invalid-email'); // fails
 * ```
 */
export function assertValidEmail(value: string): void {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  expect(value).toMatch(emailRegex);
}

/**
 * Assert that a value is a valid timestamp
 * Checks if value can be parsed into a valid Date
 *
 * @param value - Value to validate (string, number, or Date)
 *
 * @example
 * ```typescript
 * const user = await createUser();
 * assertTimestamp(user.createdAt);
 * ```
 */
export function assertTimestamp(value: any): void {
  expect(value).toBeDefined();
  const date = new Date(value);
  expect(date.toString()).not.toBe('Invalid Date');
  expect(date.getTime()).not.toBeNaN();
}

/**
 * Assert that a response follows the paginated response structure
 * Expected structure: { data: [], meta: { total, page, perPage } }
 *
 * @param response - Response object to validate
 *
 * @example
 * ```typescript
 * const response = await request(app).get('/api/v1/users');
 * assertPaginatedResponse(response.body);
 * ```
 */
export function assertPaginatedResponse(response: any): void {
  expect(response).toHaveProperty('data');
  expect(Array.isArray(response.data)).toBe(true);

  expect(response).toHaveProperty('meta');
  expect(response.meta).toHaveProperty('total');
  expect(response.meta).toHaveProperty('page');
  expect(response.meta).toHaveProperty('perPage');

  expect(typeof response.meta.total).toBe('number');
  expect(typeof response.meta.page).toBe('number');
  expect(typeof response.meta.perPage).toBe('number');

  expect(response.meta.total).toBeGreaterThanOrEqual(0);
  expect(response.meta.page).toBeGreaterThan(0);
  expect(response.meta.perPage).toBeGreaterThan(0);
}

/**
 * Assert that an object has the expected timestamps (createdAt, updatedAt)
 *
 * @param obj - Object to validate
 * @param includeDeletedAt - Whether to check for deletedAt (default: false)
 *
 * @example
 * ```typescript
 * const user = await createUser();
 * assertHasTimestamps(user);
 * ```
 */
export function assertHasTimestamps(obj: any, includeDeletedAt: boolean = false): void {
  expect(obj).toHaveProperty('createdAt');
  expect(obj).toHaveProperty('updatedAt');

  assertTimestamp(obj.createdAt);
  assertTimestamp(obj.updatedAt);

  if (includeDeletedAt) {
    expect(obj).toHaveProperty('deletedAt');
    if (obj.deletedAt !== null) {
      assertTimestamp(obj.deletedAt);
    }
  }
}

/**
 * Assert that an API error response has the expected structure
 * Expected: { statusCode, message, error? }
 *
 * @param response - Response object
 * @param expectedStatus - Expected HTTP status code
 * @param messageContains - Optional substring to check in error message
 *
 * @example
 * ```typescript
 * const response = await request(app).get('/invalid');
 * assertErrorResponse(response.body, 404, 'Not Found');
 * ```
 */
export function assertErrorResponse(
  response: any,
  expectedStatus: number,
  messageContains?: string,
): void {
  expect(response).toHaveProperty('statusCode');
  expect(response.statusCode).toBe(expectedStatus);

  expect(response).toHaveProperty('message');
  expect(typeof response.message).toBe('string');

  if (messageContains) {
    expect(response.message.toLowerCase()).toContain(messageContains.toLowerCase());
  }
}

/**
 * Assert that a date is recent (within last N seconds)
 * Useful for testing timestamps on newly created entities
 *
 * @param date - Date to check
 * @param withinSeconds - Max age in seconds (default: 5)
 *
 * @example
 * ```typescript
 * const user = await createUser();
 * assertRecentDate(user.createdAt, 10); // Created within last 10 seconds
 * ```
 */
export function assertRecentDate(date: any, withinSeconds: number = 5): void {
  assertTimestamp(date);
  const timestamp = new Date(date).getTime();
  const now = Date.now();
  const ageMs = now - timestamp;
  const ageSeconds = ageMs / 1000;

  expect(ageSeconds).toBeLessThanOrEqual(withinSeconds);
  expect(ageSeconds).toBeGreaterThanOrEqual(0);
}

/**
 * Assert that an array contains items matching a condition
 *
 * @param array - Array to check
 * @param condition - Condition function
 * @param message - Optional error message
 *
 * @example
 * ```typescript
 * assertArrayContains(users, u => u.role === 'admin', 'Should have admin user');
 * ```
 */
export function assertArrayContains<T>(
  array: T[],
  condition: (item: T) => boolean,
  message?: string,
): void {
  expect(Array.isArray(array)).toBe(true);
  const found = array.some(condition);
  expect(found, message || 'Array should contain matching item').toBe(true);
}

/**
 * Assert that two arrays have the same elements (order independent)
 *
 * @param actual - Actual array
 * @param expected - Expected array
 *
 * @example
 * ```typescript
 * assertArraysEqual([1, 2, 3], [3, 1, 2]); // passes
 * assertArraysEqual([1, 2], [1, 2, 3]); // fails
 * ```
 */
export function assertArraysEqual<T>(actual: T[], expected: T[]): void {
  expect(actual.length).toBe(expected.length);
  expect(actual.sort()).toEqual(expected.sort());
}

/**
 * Assert that an object matches a partial shape
 * Useful for testing API responses where you only care about certain fields
 *
 * @param obj - Object to test
 * @param partial - Partial object with expected values
 *
 * @example
 * ```typescript
 * const user = await getUser();
 * assertMatchesPartial(user, { email: 'test@example.com', role: 'agent' });
 * ```
 */
export function assertMatchesPartial(obj: any, partial: any): void {
  Object.keys(partial).forEach(key => {
    expect(obj).toHaveProperty(key);
    expect(obj[key]).toEqual(partial[key]);
  });
}

/**
 * Assert that a string is a valid URL
 *
 * @param value - String to validate
 *
 * @example
 * ```typescript
 * assertValidUrl('https://example.com'); // passes
 * assertValidUrl('not a url'); // fails
 * ```
 */
export function assertValidUrl(value: string): void {
  expect(() => new URL(value)).not.toThrow();
  expect(value).toMatch(/^https?:\/\/.+/);
}

/**
 * Assert that a number is within a range
 *
 * @param value - Number to check
 * @param min - Minimum value (inclusive)
 * @param max - Maximum value (inclusive)
 *
 * @example
 * ```typescript
 * assertInRange(response.data.length, 1, 100);
 * ```
 */
export function assertInRange(value: number, min: number, max: number): void {
  expect(value).toBeGreaterThanOrEqual(min);
  expect(value).toBeLessThanOrEqual(max);
}
