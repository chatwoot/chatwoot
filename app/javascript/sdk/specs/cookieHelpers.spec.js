import Cookies from 'js-cookie';
import {
  computeHashForUserData,
  fnv1a128,
  getUserCookieName,
  getUserString,
  hasUserKeys,
  setCookieWithDomain,
} from '../cookieHelpers';

describe('#getUserCookieName', () => {
  it('returns correct cookie name', () => {
    global.$chatwoot = { websiteToken: '123456' };
    expect(getUserCookieName()).toBe('cw_user_123456');
  });
});

describe('#getUserString', () => {
  it('returns correct user string', () => {
    expect(
      getUserString({
        user: {
          name: 'Pranav',
          email: 'pranav@example.com',
          avatar_url: 'https://images.chatwoot.com/placeholder',
          identifier_hash: '12345',
        },
        identifier: '12345',
      })
    ).toBe(
      JSON.stringify([
        ['avatar_url', 'https://images.chatwoot.com/placeholder'],
        ['email', 'pranav@example.com'],
        ['name', 'Pranav'],
        ['identifier_hash', '12345'],
        ['identifier', '12345'],
      ])
    );

    expect(
      getUserString({
        user: {
          email: 'pranav@example.com',
          avatar_url: 'https://images.chatwoot.com/placeholder',
        },
      })
    ).toBe(
      JSON.stringify([
        ['avatar_url', 'https://images.chatwoot.com/placeholder'],
        ['email', 'pranav@example.com'],
        ['name', ''],
        ['identifier_hash', ''],
        ['identifier', ''],
      ])
    );
  });
});

describe('#fnv1a128', () => {
  // Adapted from https://github.com/sindresorhus/fnv1a/blob/main/test.js
  it.each([
    ['', '6c62272e07bb014262b821756295c58d'],
    ['h', 'd228cb69681a8caf78912b704e4a80c7'],
    ['he', '08809533baab1be95aa0733055ac4756'],
    ['hel', 'a68d42edea8b5822836dbc796afba45e'],
    ['hell', '693c5663cb757277b806e966a3a30986'],
    ['hello', 'e3e1efd54283d94f7081314b599d31b3'],
    ['hello ', 'b25bb89a6b3c64bf6ef7a7b7446bffe1'],
    ['hello w', '2e209201894ff78d8abb5e8130e37d92'],
    ['hello wo', '43448b61f2659b29b48d48f727ec064f'],
    ['hello wor', 'bc7f6d8b8005ec5129d8c81e1f6bad0f'],
    ['hello worl', '0eeb3653ea49c7de7dbe3d10a97e58d1'],
    ['hello world', '6c155799fdc8eec4b91523808e7726b7'],
  ])('hashes %j to %s', (value, expectedHash) => {
    expect(fnv1a128(value)).toBe(expectedHash);
  });

  it('hashes long input', () => {
    const loremIpsumParagraph = [
      'Lorem ipsum dolor sit amet, consectetuer adipiscing elit.',
      'Aenean commodo ligula eget dolor.',
      'Aenean massa.',
      'Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.',
      'Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem.',
      'Nulla consequat massa quis enim.',
      'Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu.',
      'In enim justo, rhoncus ut, imperdiet a, venenatis vitae, justo.',
      'Nullam dictum felis eu pede mollis pretium.',
    ].join(' ');
    const value = Array(3).fill(loremIpsumParagraph).join(' ');

    expect(fnv1a128(value)).toBe('4fedf302b27b5c4dbaf35bd87a91f589');
  });

  it('hashes multi-byte UTF-8 characters', () => {
    expect(fnv1a128('🦄🌈')).toBe('0a25841ae4659905b36cb0d359fad39f');
  });

  it('hashes characters from across the Unicode range', () => {
    const codePoints = [
      0x0000, 0x0080, 0x0100, 0x0180, 0x0250, 0x02b0, 0x0300, 0x0370, 0x0400,
      0x0500, 0x0530, 0x0590, 0x0600, 0x0700, 0x0780, 0x0900, 0x0980, 0x0a00,
      0x0a80, 0x0b00, 0x0b80, 0x0c00, 0x0c80, 0x0d00, 0x0d80, 0x0e00, 0x0e80,
      0x0f00, 0x1000, 0x10a0, 0x1100, 0x1200, 0x13a0, 0x1400, 0x1680, 0x16a0,
      0x1700, 0x1720, 0x1740, 0x1760, 0x1780, 0x1800, 0x1900, 0x1950, 0x19e0,
      0x1d00, 0x1e00, 0x1f00, 0x2000, 0x2070, 0x20a0, 0x20d0, 0x2100, 0x2150,
      0x2190, 0x2200, 0x2300, 0x2400, 0x2440, 0x2460, 0x2500, 0x2580, 0x25a0,
      0x2600, 0x2700, 0x27c0, 0x27f0, 0x2800, 0x2900, 0x2980, 0x2a00, 0x2b00,
      0x2e80, 0x2f00, 0x2ff0, 0x3000, 0x3040, 0x30a0, 0x3100, 0x3130, 0x3190,
      0x31a0, 0x31f0, 0x3200, 0x3300, 0x3400, 0x4dc0, 0x4e00, 0xa000, 0xa490,
      0xac00, 0xd800, 0xdc00, 0xe000, 0xf900, 0xfb00, 0xfb50, 0xfe00, 0xfe20,
      0xfe30, 0xfe50, 0xfe70, 0xff00, 0xfff0, 0x10000, 0x10080, 0x10100,
      0x10300, 0x10330, 0x10380, 0x10400, 0x10450, 0x10480, 0x10800, 0x1d000,
      0x1d100, 0x1d300, 0x1d400, 0x20000, 0x2f800, 0xe0000, 0xe0100,
    ];
    const value = codePoints
      .map(codePoint => String.fromCodePoint(codePoint))
      .join('');

    expect(fnv1a128(value)).toBe('ca8f3b27d9685fa16c01b04ca12aba2d');
  });
});

describe('#computeHashForUserData', () => {
  it.each([
    [{ user: {} }, '1aad4cb46d5db425dcc232d086a8b6be'],
    [
      {
        identifier: '12345',
        user: {
          name: 'Pranav',
          email: 'pranav@example.com',
          avatar_url: 'https://images.chatwoot.com/placeholder',
          identifier_hash: '12345',
        },
      },
      '73b97d28ad386b211c8eed2143752b6e',
    ],
    [
      {
        identifier: 42,
        user: {
          name: 'Jöhn 🌈',
          email: '🦄@example.com',
        },
      },
      'ca2a97a04c3bcafc20d9cdeac1e5b3f4',
    ],
  ])('hashes canonical user data synchronously', (userData, expectedHash) => {
    expect(computeHashForUserData(userData)).toBe(expectedHash);
  });

  it('is independent of user property insertion order', () => {
    const firstHash = computeHashForUserData({
      identifier: '12345',
      user: { name: 'Pranav', email: 'pranav@example.com' },
    });
    const secondHash = computeHashForUserData({
      identifier: '12345',
      user: { email: 'pranav@example.com', name: 'Pranav' },
    });

    expect(firstHash).toBe(secondHash);
  });

  it('ignores user properties that are not part of the SDK identity', () => {
    const firstHash = computeHashForUserData({
      identifier: '12345',
      user: { name: 'Pranav' },
    });
    const secondHash = computeHashForUserData({
      identifier: '12345',
      user: { name: 'Pranav', role: 'administrator' },
    });

    expect(firstHash).toBe(secondHash);
  });

  it('changes when an identity property changes', () => {
    const firstHash = computeHashForUserData({
      identifier: '12345',
      user: { name: 'Pranav' },
    });
    const secondHash = computeHashForUserData({
      identifier: '67890',
      user: { name: 'Pranav' },
    });

    expect(firstHash).not.toBe(secondHash);
  });

  it('distinguishes identities that collide under FNV-1a 32-bit', () => {
    const firstHash = computeHashForUserData({
      identifier: 'id-149599',
      user: { name: 'User' },
    });
    const secondHash = computeHashForUserData({
      identifier: 'id-312382',
      user: { name: 'User' },
    });

    expect(firstHash).toHaveLength(32);
    expect(secondHash).toHaveLength(32);
    expect(firstHash).not.toBe(secondHash);
  });
});

describe('#computeHashForUserData', () => {
  const identifier = 'user-123';
  const user = {
    name: 'Pranav',
    email: 'pranav@example.com',
  };

  it('normalizes numeric identifiers', () => {
    const numericIdentifierHash = computeHashForUserData({
      identifier: 123,
      user,
    });
    const stringIdentifierHash = computeHashForUserData({
      identifier: '123',
      user,
    });

    expect(numericIdentifierHash).toBe(stringIdentifierHash);
  });

  it.each([
    ['phone_number', '+15555550100', '+15555550101'],
    ['company_name', 'Chatwoot', 'Acme'],
    ['city', 'Bengaluru', 'Kochi'],
    ['country_code', 'IN', 'US'],
    ['description', 'Chatwoot user', 'Acme user'],
  ])('changes when %s changes', (attribute, currentValue, updatedValue) => {
    const currentHash = computeHashForUserData({
      identifier,
      user: { ...user, [attribute]: currentValue },
    });
    const updatedHash = computeHashForUserData({
      identifier,
      user: { ...user, [attribute]: updatedValue },
    });

    expect(updatedHash).not.toBe(currentHash);
  });

  it('changes when a social profile changes', () => {
    const currentHash = computeHashForUserData({
      identifier,
      user: { ...user, social_profiles: { github: 'chatwoot' } },
    });
    const updatedHash = computeHashForUserData({
      identifier,
      user: { ...user, social_profiles: { github: 'chatwoot-app' } },
    });

    expect(updatedHash).not.toBe(currentHash);
  });

  it('preserves contact information field boundaries', () => {
    const companyNameHash = computeHashForUserData({
      identifier,
      user: { ...user, company_name: 'cityParis' },
    });
    const companyNameAndCityHash = computeHashForUserData({
      identifier,
      user: { ...user, company_name: '', city: 'Paris' },
    });

    expect(companyNameAndCityHash).not.toBe(companyNameHash);
  });

  it('is independent of social profile property order', () => {
    const firstHash = computeHashForUserData({
      identifier,
      user: {
        ...user,
        social_profiles: { github: 'chatwoot', twitter: 'chatwootapp' },
      },
    });
    const secondHash = computeHashForUserData({
      identifier,
      user: {
        ...user,
        social_profiles: { twitter: 'chatwootapp', github: 'chatwoot' },
      },
    });

    expect(secondHash).toBe(firstHash);
  });

  it('ignores custom attributes managed by setCustomAttributes', () => {
    const currentHash = computeHashForUserData({
      identifier,
      user: { ...user, custom_attributes: { plan: 'starter' } },
    });
    const updatedHash = computeHashForUserData({
      identifier,
      user: { ...user, custom_attributes: { plan: 'business' } },
    });

    expect(updatedHash).toBe(currentHash);
  });
});

describe('#hasUserKeys', () => {
  it('checks whether the allowed list of keys are present', () => {
    expect(hasUserKeys({})).toBe(false);
    expect(hasUserKeys({ randomKey: 'randomValue' })).toBe(false);
    expect(hasUserKeys({ avatar_url: 'randomValue' })).toBe(true);
  });
});

// Mock the 'set' method of the 'Cookies' object

describe('setCookieWithDomain', () => {
  beforeEach(() => {
    vi.spyOn(Cookies, 'set');
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('should set a cookie with default parameters', () => {
    setCookieWithDomain('myCookie', 'cookieValue');

    expect(Cookies.set).toHaveBeenCalledWith('myCookie', 'cookieValue', {
      expires: 365,
      sameSite: 'Lax',
      domain: undefined,
    });
  });

  it('should set a cookie with custom expiration and sameSite attribute', () => {
    setCookieWithDomain('myCookie', 'cookieValue', {
      expires: 30,
    });

    expect(Cookies.set).toHaveBeenCalledWith('myCookie', 'cookieValue', {
      expires: 30,
      sameSite: 'Lax',
      domain: undefined,
    });
  });

  it('should set a cookie with a specific base domain', () => {
    setCookieWithDomain('myCookie', 'cookieValue', {
      baseDomain: 'example.com',
    });

    expect(Cookies.set).toHaveBeenCalledWith('myCookie', 'cookieValue', {
      expires: 365,
      sameSite: 'Lax',
      domain: 'example.com',
    });
  });

  it('should stringify the cookie value when setting the value', () => {
    setCookieWithDomain(
      'myCookie',
      { value: 'cookieValue' },
      {
        baseDomain: 'example.com',
      }
    );

    expect(Cookies.set).toHaveBeenCalledWith(
      'myCookie',
      JSON.stringify({ value: 'cookieValue' }),
      {
        expires: 365,
        sameSite: 'Lax',
        domain: 'example.com',
      }
    );
  });

  it('should set a cookie with custom expiration, sameSite attribute, and specific base domain', () => {
    setCookieWithDomain('myCookie', 'cookieValue', {
      expires: 7,
      baseDomain: 'example.com',
    });

    expect(Cookies.set).toHaveBeenCalledWith('myCookie', 'cookieValue', {
      expires: 7,
      sameSite: 'Lax',
      domain: 'example.com',
    });
  });
});
