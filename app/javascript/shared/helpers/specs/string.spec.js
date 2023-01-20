import { parseBoolean } from '../string';

describe('#parseBoolean', () => {
  test('returns true for input "true"', () => {
    expect(parseBoolean('true')).toBe(true);
  });

  test('returns false for input "false"', () => {
    expect(parseBoolean('false')).toBe(false);
  });

  test('returns true for input "1"', () => {
    expect(parseBoolean(1)).toBe(true);
  });

  test('returns false for input "0"', () => {
    expect(parseBoolean(0)).toBe(false);
  });

  test('returns false for input "non-boolean value"', () => {
    expect(parseBoolean('non-boolean value')).toBe(false);
  });

  test('returns false for input "null"', () => {
    expect(parseBoolean(null)).toBe(false);
  });

  test('returns false for input "undefined"', () => {
    expect(parseBoolean(undefined)).toBe(false);
  });
});
