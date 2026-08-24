import Cookies from 'js-cookie';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { frontendURL } from 'dashboard/helper/URLHelper';

export const hasAuthCookie = () => {
  return !!Cookies.get('cw_d_session_info');
};

const getSSOAccountPath = ({ ssoAccountId, user }) => {
  const { accounts = [], account_id = null } = user || {};
  const ssoAccount = accounts.find(
    account => account.id === Number(ssoAccountId)
  );
  let accountPath = '';
  if (ssoAccount) {
    accountPath = `accounts/${ssoAccountId}`;
  } else if (accounts.length) {
    // If the account id is not found, redirect to the first account
    const accountId = account_id || accounts[0].id;
    accountPath = `accounts/${accountId}`;
  }
  return accountPath;
};

const capitalize = str =>
  str
    .split(/[._-]+/)
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');

export const getCredentialsFromEmail = email => {
  const [localPart, domain] = email.split('@');
  const namePart = localPart.split('+')[0];
  return {
    fullName: capitalize(namePart),
    accountName: capitalize(domain.split('.')[0]),
  };
};

// An SSO link may name the dashboard route to land on after login, so a
// partner product can send the user straight to the page it is talking about.
// The value is only ever appended to the account path, never used as a URL, so
// it has to be a plain relative segment list — anything with a scheme, a host,
// a traversal, a query or a fragment is dropped.
const SAFE_SSO_ROUTE_PATH_REGEX = /^[A-Za-z0-9_-]+(\/[A-Za-z0-9_-]+)*$/;

const isSafeSSORoutePath = ssoRoutePath =>
  SAFE_SSO_ROUTE_PATH_REGEX.test(ssoRoutePath ?? '');

export const getLoginRedirectURL = ({
  ssoAccountId,
  ssoConversationId,
  ssoRoutePath,
  user,
}) => {
  const accountPath = getSSOAccountPath({ ssoAccountId, user });
  if (accountPath) {
    if (ssoConversationId) {
      return frontendURL(`${accountPath}/conversations/${ssoConversationId}`);
    }
    if (isSafeSSORoutePath(ssoRoutePath)) {
      return frontendURL(`${accountPath}/${ssoRoutePath}`);
    }
    return frontendURL(`${accountPath}/dashboard`);
  }
  return DEFAULT_REDIRECT_URL;
};
