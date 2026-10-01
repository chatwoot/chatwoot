import Cookies from 'js-cookie';

const REQUIRED_USER_KEYS = ['avatar_url', 'email', 'name'];
const ALLOWED_USER_ATTRIBUTES = [...REQUIRED_USER_KEYS, 'identifier_hash'];
const FNV1A_128_OFFSET_BASIS = 0x6c62272e07bb014262b821756295c58dn;
const FNV1A_128_PRIME = 0x1000000000000000000013bn;
const CONTACT_INFORMATION_ATTRIBUTES = [
  'phone_number',
  'company_name',
  'city',
  'country_code',
  'description',
  'social_profiles',
];

const normalizeUserAttribute = value => {
  if (!value || typeof value !== 'object') return value || '';

  return Object.keys(value)
    .sort()
    .map(key => [key, value[key]]);
};

export const getUserCookieName = () => {
  const SET_USER_COOKIE_PREFIX = 'cw_user_';
  const { websiteToken: websiteIdentifier } = window.$chatwoot;
  return `${SET_USER_COOKIE_PREFIX}${websiteIdentifier}`;
};

export const getUserString = ({ identifier = '', user }) => {
  const userAttributes = [
    ...ALLOWED_USER_ATTRIBUTES.map(key => [key, user[key] || '']),
    ...CONTACT_INFORMATION_ATTRIBUTES.filter(
      key => user[key] !== undefined
    ).map(key => [key, normalizeUserAttribute(user[key])]),
    ['identifier', String(identifier)],
  ];
  return JSON.stringify(userAttributes);
};

export const fnv1a128 = value => {
  const data = new TextEncoder().encode(value);
  let hash = FNV1A_128_OFFSET_BASIS;

  data.forEach(byte => {
    hash ^= BigInt(byte); // eslint-disable-line no-bitwise
    hash = BigInt.asUintN(128, hash * FNV1A_128_PRIME);
  });

  return hash.toString(16).padStart(32, '0');
};

export const computeHashForUserData = (...args) =>
  fnv1a128(getUserString(...args));

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
