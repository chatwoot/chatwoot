import md5 from 'md5';
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

export const computeHashForUserData = (...args) => md5(getUserString(...args));

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
