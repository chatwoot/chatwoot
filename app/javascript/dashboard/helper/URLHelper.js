import queryString from 'query-string';

export const frontendURL = (path, params) => {
  const stringifiedParams = params ? `?${queryString.stringify(params)}` : '';
  return `/app/${path}${stringifiedParams}`;
};

export const conversationUrl = ({
  accountId,
  activeInbox,
  id,
  label,
  teamId,
}) => {
  if (activeInbox) {
    return `accounts/${accountId}/inbox/${activeInbox}/conversations/${id}`;
  }
  if (label) {
    return `accounts/${accountId}/label/${label}/conversations/${id}`;
  }
  if (teamId) {
    return `accounts/${accountId}/team/${teamId}/conversations/${id}`;
  }
  return `accounts/${accountId}/conversations/${id}`;
};

export const accountIdFromPathname = pathname => {
  const isInsideAccountScopedURLs = pathname.includes('/app/accounts');
  const urlParam = pathname.split('/')[3];
  // eslint-disable-next-line no-restricted-globals
  const isScoped = isInsideAccountScopedURLs && !isNaN(urlParam);
  const accountId = isScoped ? Number(urlParam) : '';
  return accountId;
};
