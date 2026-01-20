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

// CommMate: Check if post-signup Evolution onboarding is enabled
const shouldRedirectToEvolutionOnboarding = () => {
  const config = window.chatwootConfig || {};
  return (
    config.commmatePostSignupEvolutionOnboarding === 'true' &&
    config.evolutionApiEnabled === 'true'
  );
};

// CommMate: Build Evolution onboarding URL for new signups
const getEvolutionOnboardingURL = user => {
  const { accounts = [], account_id = null } = user || {};
  if (!accounts.length) return null;

  // Use the first/active account
  const accountId = account_id || accounts[0].id;
  const accountName = accounts[0]?.name || '';

  if (!accountName) return null;

  const inboxName = encodeURIComponent(accountName.trim());
  return frontendURL(
    `accounts/${accountId}/settings/inboxes/new/evolution?inbox_name=${inboxName}&auto_load_qr=1`
  );
};

export const getLoginRedirectURL = ({
  ssoAccountId,
  ssoConversationId,
  user,
  isNewSignup = false,
}) => {
  // CommMate: For new signups via OAuth, redirect to Evolution onboarding if enabled
  // Detect new signup: user has only 1 account (just created)
  const { accounts = [] } = user || {};
  const looksLikeNewSignup = isNewSignup || accounts.length === 1;

  if (
    looksLikeNewSignup &&
    shouldRedirectToEvolutionOnboarding() &&
    !ssoConversationId
  ) {
    const evolutionURL = getEvolutionOnboardingURL(user);
    if (evolutionURL) {
      return evolutionURL;
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
