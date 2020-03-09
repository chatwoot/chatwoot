import queryString from 'query-string';

export const frontendURL = (path, params) => {
  const stringifiedParams = params ? `?${queryString.stringify(params)}` : '';
  return `/app/${path}${stringifiedParams}`;
};

export const conversationUrl = (accountId, activeInbox, id) => {
  const path = activeInbox
    ? `accounts/${accountId}/inbox/${activeInbox}/conversations/${id}`
    : `accounts/${accountId}/conversations/${id}`;
  return path;
};
