import { describe, it, expect } from 'vitest';

describe('Vitest Setup', () => {
  it('should run tests', () => {
    expect(true).toBe(true);
  });

  it('should support async tests', async () => {
    const result = await Promise.resolve(42);
    expect(result).toBe(42);
  });

  it('should have access to environment variables', () => {
    expect(process.env.NODE_ENV).toBe('test');
  });

  it('should support basic assertions', () => {
    const obj = { name: 'test', value: 123 };
    expect(obj).toHaveProperty('name');
    expect(obj.name).toBe('test');
    expect(obj.value).toBeGreaterThan(100);
  });

  it('should support array assertions', () => {
    const arr = [1, 2, 3, 4, 5];
    expect(arr).toHaveLength(5);
    expect(arr).toContain(3);
    expect(arr).toEqual(expect.arrayContaining([2, 4]));
  });
});
