import { DEFAULT_REDIRECT_URL } from '../constants';

export const frontendURL = (path, params) => {
  const stringifiedParams = params ? `?${new URLSearchParams(params)}` : '';
  return `/app/${path}${stringifiedParams}`;
};

const getSSOAccountPath = ({ ssoAccountId, user }) => {
  const { accounts = [] } = user || {};
  const ssoAccount = accounts.find(
    account => account.id === Number(ssoAccountId)
  );
  let accountPath = '';
  if (ssoAccount) {
    accountPath = `accounts/${ssoAccountId}`;
  } else if (accounts.length) {
    accountPath = `accounts/${accounts[0].id}`;
  }
  return accountPath;
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
    return frontendURL(`${accountPath}/dashboard`);
  }
  return DEFAULT_REDIRECT_URL;
};

export const conversationUrl = ({
  accountId,
  activeInbox,
  id,
  label,
  teamId,
  conversationType = '',
  foldersId,
}) => {
  let url = `accounts/${accountId}/conversations/${id}`;
  if (activeInbox) {
    url = `accounts/${accountId}/inbox/${activeInbox}/conversations/${id}`;
  } else if (label) {
    url = `accounts/${accountId}/label/${label}/conversations/${id}`;
  } else if (teamId) {
    url = `accounts/${accountId}/team/${teamId}/conversations/${id}`;
  } else if (foldersId && foldersId !== 0) {
    url = `accounts/${accountId}/custom_view/${foldersId}/conversations/${id}`;
  } else if (conversationType === 'mention') {
    url = `accounts/${accountId}/mentions/conversations/${id}`;
  }
  return url;
};

export const conversationListPageURL = ({
  accountId,
  conversationType = '',
  inboxId,
  label,
  teamId,
}) => {
  let url = `accounts/${accountId}/dashboard`;
  if (label) {
    url = `accounts/${accountId}/label/${label}`;
  } else if (teamId) {
    url = `accounts/${accountId}/team/${teamId}`;
  } else if (conversationType === 'mention') {
    url = `accounts/${accountId}/mentions/conversations`;
  } else if (inboxId) {
    url = `accounts/${accountId}/inbox/${inboxId}`;
  }
  return frontendURL(url);
};

export const isValidURL = value => {
  /* eslint-disable no-useless-escape */
  const URL_REGEX = /^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$/gm;
  return URL_REGEX.test(value);
};
