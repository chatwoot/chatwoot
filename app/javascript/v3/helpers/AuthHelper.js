import Cookies from 'js-cookie';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { frontendURL } from 'dashboard/helper/URLHelper';

export const hasAuthCookie = () => {
  return !!Cookies.get('cw_d_session_info');
};

const SHOPIFY_INSTALL_REDIRECT_PATTERN =
  /^settings\/integrations\/shopify\?shopify_pending_install=([0-9a-f]{32})$/;

export const isShopifyInstallRedirect = redirectUrl =>
  SHOPIFY_INSTALL_REDIRECT_PATTERN.test(redirectUrl || '');

export const getSignupRoute = redirectUrl => {
  const match = (redirectUrl || '').match(SHOPIFY_INSTALL_REDIRECT_PATTERN);
  const signupRoute = { name: 'auth_signup' };

  return match
    ? { ...signupRoute, query: { shopify_pending_install: match[1] } }
    : signupRoute;
};

export const getShopifyInstallAccount = ({ accounts, accountId }) => {
  const canManageShopify = account =>
    account.role === 'administrator' && account.status === 'active';
  const currentAccount = accounts.find(
    account => account.id === Number(accountId)
  );

  return canManageShopify(currentAccount || {})
    ? currentAccount
    : accounts.find(canManageShopify);
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

export const getLoginRedirectURL = ({
  ssoAccountId,
  ssoConversationId,
  redirectUrl,
  user,
}) => {
  if (redirectUrl) {
    const { accounts = [], account_id = null } = user || {};
    const targetAccount = isShopifyInstallRedirect(redirectUrl)
      ? getShopifyInstallAccount({ accounts, accountId: account_id })
      : accounts.find(account => account.id === Number(account_id)) ||
        accounts[0];
    if (targetAccount) {
      return frontendURL(`accounts/${targetAccount.id}/${redirectUrl}`);
    }
  }
  const accountPath = getSSOAccountPath({ ssoAccountId, user });
  if (accountPath) {
    if (ssoConversationId) {
      return frontendURL(`${accountPath}/conversations/${ssoConversationId}`);
    }
    return frontendURL(`${accountPath}/dashboard`);
  }
  return DEFAULT_REDIRECT_URL;
};
