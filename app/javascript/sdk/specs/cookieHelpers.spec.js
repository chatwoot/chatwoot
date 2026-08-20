import Cookies from 'js-cookie';
import {
  computeHashForUserData,
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
