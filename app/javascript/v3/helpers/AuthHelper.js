import Cookies from 'js-cookie';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { getUserRole } from 'dashboard/helper/permissionsHelper';

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

const isAdminOrOwner = (user, accountId) => {
  if (!user || !accountId) return false;
  const role = getUserRole(user, accountId);
  return role === 'administrator' || role === 'owner';
};

const isAdminFirstEnabled = () => {
  const globalConfig = window.globalConfig || {};
  const adminFirst = globalConfig.ADMIN_FIRST;
  // Check if adminFirst is truthy (true, 'true', '1', etc.)
  return adminFirst === true || adminFirst === 'true' || adminFirst === '1';
};

export const getLoginRedirectURL = ({
  ssoAccountId,
  ssoConversationId,
  user,
}) => {
  const accountPath = getSSOAccountPath({ ssoAccountId, user });
  if (accountPath) {
    if (ssoConversationId) {
      return frontendURL(`${accountPath}/conversations/${ssoConversationId}`);
    }
    
    const accountId = ssoAccountId || user.account_id || (user.accounts && user.accounts[0]?.id);
    
    // Check if admin-first mode is enabled
    if (isAdminFirstEnabled()) {
      // Admin/owner goes to admin console
      if (isAdminOrOwner(user, accountId)) {
        return frontendURL(`${accountPath}/admin`);
      }
      // Colaborador/agent goes directly to inbox view
      return frontendURL(`${accountPath}/inbox-view`);
    }
    
    // Default behavior: go to dashboard
    return frontendURL(`${accountPath}/dashboard`);
  }
  return DEFAULT_REDIRECT_URL;
};
