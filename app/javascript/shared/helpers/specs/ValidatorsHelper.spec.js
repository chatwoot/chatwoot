import {
  shouldBeUrl,
  isPhoneNumberValidWithDialCode,
  isPhoneE164OrEmpty,
  isPhoneE164,
  startsWithPlus,
  isValidPassword,
  isPhoneNumberValid,
  isNumber,
  isDomain,
  getRegexp,
  isValidSlug,
  isLocalhostUrl,
} from '../Validators';

describe('#shouldBeUrl', () => {
  it('should return correct url', () => {
    expect(shouldBeUrl('http')).toEqual(true);
  });
  it('should return wrong url', () => {
    expect(shouldBeUrl('')).toEqual(true);
    expect(shouldBeUrl('abc')).toEqual(false);
  });
});

describe('#isPhoneE164', () => {
  it('should return correct phone number', () => {
    expect(isPhoneE164('+1234567890')).toEqual(true);
  });
  it('should return wrong phone number', () => {
    expect(isPhoneE164('1234567890')).toEqual(false);
    expect(isPhoneE164('12345678A9')).toEqual(false);
    expect(isPhoneE164('+12345678901234567890')).toEqual(false);
  });
});

describe('#isPhoneE164OrEmpty', () => {
  it('should return correct phone number', () => {
    expect(isPhoneE164OrEmpty('+1234567890')).toEqual(true);
    expect(isPhoneE164OrEmpty('')).toEqual(true);
  });
  it('should return wrong phone number', () => {
    expect(isPhoneE164OrEmpty('1234567890')).toEqual(false);
    expect(isPhoneE164OrEmpty('12345678A9')).toEqual(false);
    expect(isPhoneE164OrEmpty('+12345678901234567890')).toEqual(false);
  });
});

describe('#isPhoneNumberValid', () => {
  it('should return correct phone number', () => {
    expect(isPhoneNumberValid('1234567890', '+91')).toEqual(true);
  });
  it('should return wrong phone number', () => {
    expect(isPhoneNumberValid('12345A67890', '+1')).toEqual(false);
    expect(isPhoneNumberValid('12345A6789120', '+1')).toEqual(false);
  });
});

describe('#isValidPassword', () => {
  it('should return correct password', () => {
    expect(isValidPassword('testPass4!')).toEqual(true);
    expect(isValidPassword('testPass4-')).toEqual(true);
    expect(isValidPassword('testPass4\\')).toEqual(true);
    expect(isValidPassword("testPass4'")).toEqual(true);
  });

  it('should return wrong password', () => {
    expect(isValidPassword('testpass4')).toEqual(false);
    expect(isValidPassword('testPass4')).toEqual(false);
    expect(isValidPassword('testpass4!')).toEqual(false);
    expect(isValidPassword('testPass!')).toEqual(false);
  });
});

describe('#isNumber', () => {
  it('should return correct number', () => {
    expect(isNumber('123')).toEqual(true);
  });

  it('should return wrong number', () => {
    expect(isNumber('123-')).toEqual(false);
    expect(isNumber('123./')).toEqual(false);
    expect(isNumber('string')).toEqual(false);
  });
});

describe('#isDomain', () => {
  it('should return correct domain', () => {
    expect(isDomain('test.com')).toEqual(true);
    expect(isDomain('www.test.com')).toEqual(true);
  });

  it('should return wrong domain', () => {
    expect(isDomain('test')).toEqual(false);
    expect(isDomain('test.')).toEqual(false);
    expect(isDomain('test.123')).toEqual(false);
    expect(isDomain('http://www.test.com')).toEqual(false);
    expect(isDomain('https://test.in')).toEqual(false);
  });
});

describe('#isPhoneNumberValidWithDialCode', () => {
  it('should return correct phone number', () => {
    expect(isPhoneNumberValidWithDialCode('+123456789')).toEqual(true);
    expect(isPhoneNumberValidWithDialCode('+12345')).toEqual(true);
  });
  it('should return wrong phone number', () => {
    expect(isPhoneNumberValidWithDialCode('+123')).toEqual(false);
    expect(isPhoneNumberValidWithDialCode('+1234')).toEqual(false);
  });
});

describe('#startsWithPlus', () => {
  it('should return correct phone number', () => {
    expect(startsWithPlus('+123456789')).toEqual(true);
  });
  it('should return wrong phone number', () => {
    expect(startsWithPlus('123456789')).toEqual(false);
  });
});

describe('#getRegexp', () => {
  it('should create a correct RegExp object', () => {
    const regexPattern = '/^[a-z]+$/i';
    const regex = getRegexp(regexPattern);

    expect(regex).toBeInstanceOf(RegExp);
    expect(regex.toString()).toBe(regexPattern);

    expect(regex.test('abc')).toBe(true);
    expect(regex.test('ABC')).toBe(true);
    expect(regex.test('123')).toBe(false);
  });

  it('should handle regex with flags', () => {
    const regexPattern = '/hello/gi';
    const regex = getRegexp(regexPattern);

    expect(regex).toBeInstanceOf(RegExp);
    expect(regex.toString()).toBe(regexPattern);

    expect(regex.test('hello')).toBe(true);
    expect(regex.test('HELLO')).toBe(false);
    expect(regex.test('Hello World')).toBe(true);
  });

  it('should handle regex with special characters', () => {
    const regexPattern = '/\\d{3}-\\d{2}-\\d{4}/';
    const regex = getRegexp(regexPattern);

    expect(regex).toBeInstanceOf(RegExp);
    expect(regex.toString()).toBe(regexPattern);

    expect(regex.test('123-45-6789')).toBe(true);
    expect(regex.test('12-34-5678')).toBe(false);
  });
});

describe('#isValidSlug', () => {
  it('should return true for valid slugs', () => {
    expect(isValidSlug('abc')).toEqual(true);
    expect(isValidSlug('abc-123')).toEqual(true);
    expect(isValidSlug('a-b-c')).toEqual(true);
    expect(isValidSlug('123')).toEqual(true);
    expect(isValidSlug('abc123-def')).toEqual(true);
  });
  it('should return false for invalid slugs', () => {
    expect(isValidSlug('abc_def')).toEqual(false);
    expect(isValidSlug('abc def')).toEqual(false);
    expect(isValidSlug('abc@def')).toEqual(false);
    expect(isValidSlug('abc.def')).toEqual(false);
    expect(isValidSlug('abc/def')).toEqual(false);
    expect(isValidSlug('abc!def')).toEqual(false);
    expect(isValidSlug('abc--def!')).toEqual(false);
    expect(isValidSlug('abc-def ')).toEqual(false);
    expect(isValidSlug(' abc-def')).toEqual(false);
  });
});

describe('#isLocalhostUrl', () => {
  const originalLocation = window.location;

  beforeAll(() => {
    delete window.location;
  });

  afterAll(() => {
    window.location = originalLocation;
  });

  it('should return true for empty value', () => {
    expect(isLocalhostUrl('')).toEqual(true);
    expect(isLocalhostUrl(null)).toEqual(true);
    expect(isLocalhostUrl(undefined)).toEqual(true);
  });

  it('should return true for localhost URL when running on localhost', () => {
    window.location = { hostname: 'localhost' };
    expect(isLocalhostUrl('http://localhost:3000/path')).toEqual(true);
    expect(isLocalhostUrl('https://localhost:3000/path')).toEqual(true);
    expect(isLocalhostUrl('http://127.0.0.1:3000/path')).toEqual(true);
    expect(isLocalhostUrl('https://127.0.0.1:3000/path')).toEqual(true);
  });

  it('should return false for localhost URLs when not running on localhost', () => {
    window.location = { hostname: 'example.com' };
    expect(isLocalhostUrl('http://localhost:3000/path')).toEqual(false);
    expect(isLocalhostUrl('https://localhost:3000/path')).toEqual(false);
    expect(isLocalhostUrl('http://127.0.0.1:3000/path')).toEqual(false);
    expect(isLocalhostUrl('https://127.0.0.1:3000/path')).toEqual(false);
  });

  it('should return false for non-localhost URLs', () => {
    expect(isLocalhostUrl('http://example.com')).toEqual(false);
    expect(isLocalhostUrl('https://example.com')).toEqual(false);
  });
});
