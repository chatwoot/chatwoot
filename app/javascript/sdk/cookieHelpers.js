import Cookies from 'js-cookie';

const REQUIRED_USER_KEYS = ['avatar_url', 'email', 'name'];
const ALLOWED_USER_ATTRIBUTES = [...REQUIRED_USER_KEYS, 'identifier_hash'];

export const getUserCookieName = () => {
  const SET_USER_COOKIE_PREFIX = 'cw_user_';
  const { websiteToken: websiteIdentifier } = window.$chatwoot;
  return `${SET_USER_COOKIE_PREFIX}${websiteIdentifier}`;
};

export const getUserString = ({ identifier = '', user }) => {
  const userStringWithSortedKeys = ALLOWED_USER_ATTRIBUTES.reduce(
    (acc, key) => `${acc}${key}${user[key] || ''}`,
    ''
  );
  return `${userStringWithSortedKeys}identifier${identifier}`;
};

const computeFallbackHash = data => {
  let hash = 0x811c9dc5;

  data.forEach(byte => {
    hash ^= byte; // eslint-disable-line no-bitwise
    hash = Math.imul(hash, 0x01000193);
  });

  return (hash >>> 0).toString(16).padStart(8, '0'); // eslint-disable-line no-bitwise
};

export const computeHashForUserData = async (...args) => {
  const data = new TextEncoder().encode(getUserString(...args));

  if (!window.crypto?.subtle) {
    return computeFallbackHash(data);
  }

  const hashBuffer = await window.crypto.subtle.digest('SHA-256', data);

  return Array.from(new Uint8Array(hashBuffer), byte =>
    byte.toString(16).padStart(2, '0')
  ).join('');
};

export const hasUserKeys = user =>
  REQUIRED_USER_KEYS.reduce((acc, key) => acc || !!user[key], false);

export const setCookieWithDomain = (
  name,
  value,
  { expires = 365, baseDomain = undefined } = {}
) => {
  const cookieOptions = {
    expires,
    sameSite: 'Lax',
    domain: baseDomain,
  };

  // if type of value is object, stringify it
  // this is because js-cookies 3.0 removed builtin json support
  // ref: https://github.com/js-cookie/js-cookie/releases/tag/v3.0.0
  if (typeof value === 'object') {
    value = JSON.stringify(value);
  }

  Cookies.set(name, value, cookieOptions);
};
