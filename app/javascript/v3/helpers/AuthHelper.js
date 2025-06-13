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

export const getLoginRedirectURL = ({
  ssoAccountId,
  ssoConversationId,
  user,
}) => {
  const accountPath = getSSOAccountPath({ ssoAccountId, user });
  // let sessionInfo = {};
  let isNewUser = false;
  try {
    const sessionCookie = Cookies.get('cw_d_session_info');
    // sessionInfo = sessionCookie ? JSON.parse(sessionCookie) : {};
    isNewUser =
      user && user.available_name === user.email && user.display_name === null;
  } catch (error) {}
  if (accountPath) {
    if (ssoConversationId) {
      return frontendURL(`${accountPath}/conversations/${ssoConversationId}`);
    }
    if (isNewUser) {
      return frontendURL(`${accountPath}/start/setup-profile`);
    }
    return frontendURL(`${accountPath}/dashboard`);
  }
  return DEFAULT_REDIRECT_URL;
};
