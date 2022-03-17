import queryString from 'query-string';
import { DEFAULT_REDIRECT_URL } from '../constants';

export const frontendURL = (path, params) => {
  const stringifiedParams = params ? `?${queryString.stringify(params)}` : '';
  return `/app/${path}${stringifiedParams}`;
};

export const getLoginRedirectURL = (ssoAccountId, user) => {
  const { accounts = [] } = user || {};
  const ssoAccount = accounts.find(
    account => account.id === Number(ssoAccountId)
  );
  if (ssoAccount) {
    return frontendURL(`accounts/${ssoAccountId}/dashboard`);
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

export const accountIdFromPathname = pathname => {
  const isInsideAccountScopedURLs = pathname.includes('/app/accounts');
  const urlParam = pathname.split('/')[3];
  // eslint-disable-next-line no-restricted-globals
  const isScoped = isInsideAccountScopedURLs && !isNaN(urlParam);
  const accountId = isScoped ? Number(urlParam) : '';
  return accountId;
};

export const isValidURL = value => {
  /* eslint-disable no-useless-escape */
  const URL_REGEX = /^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$/gm;
  return URL_REGEX.test(value);
};
