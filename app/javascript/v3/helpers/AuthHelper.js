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

const SHOPIFY_ENTITLED_STATES = ['active', 'trialing', 'cancelled'];

export const isShopifyBillingAccount = account =>
  account?.billing_provider === 'shopify' &&
  account.shopify_integration === true;

export const requiresShopifyBilling = account =>
  isShopifyBillingAccount(account) &&
  !SHOPIFY_ENTITLED_STATES.includes(account.subscription_status);

export const getShopifyBillingRedirect = query => {
  const { plan_handle: planHandle, shop } = query || {};
  if (!planHandle && !shop) return '';

  const params = new URLSearchParams();
  if (planHandle) params.set('plan_handle', planHandle);
  if (shop) params.set('shop', shop);
  return `settings/billing?${params.toString()}`;
};

export const getShopifyShopFromRedirect = redirectUrl => {
  const query = redirectUrl?.split('?')[1];
  return new URLSearchParams(query).get('shop')?.trim().toLowerCase() || '';
};

export const getTargetAccount = ({ ssoAccountId, redirectUrl, user }) => {
  const { accounts = [], account_id: accountId = null } = user || {};
  const shop = getShopifyShopFromRedirect(redirectUrl);
  if (shop) {
    return accounts.find(
      account => account.shopify_shop_domain?.toLowerCase() === shop
    );
  }

  const ssoAccount = accounts.find(
    account => account.id === Number(ssoAccountId)
  );
  return (
    ssoAccount ||
    accounts.find(account => account.id === Number(accountId)) ||
    accounts[0]
  );
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
  const targetAccount = getTargetAccount({ ssoAccountId, redirectUrl, user });
  if (getShopifyShopFromRedirect(redirectUrl) && !targetAccount) {
    return DEFAULT_REDIRECT_URL;
  }
  if (redirectUrl) {
    const { accounts = [], account_id = null } = user || {};
    const redirectAccount = isShopifyInstallRedirect(redirectUrl)
      ? getShopifyInstallAccount({ accounts, accountId: account_id })
      : targetAccount;
    if (redirectAccount) {
      return frontendURL(`accounts/${redirectAccount.id}/${redirectUrl}`);
    }
  }
  if (requiresShopifyBilling(targetAccount)) {
    return frontendURL(`accounts/${targetAccount.id}/settings/billing`);
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
