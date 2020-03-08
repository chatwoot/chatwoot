import queryString from 'query-string';

export const frontendURL = (path, params) => {
  const stringifiedParams = params ? `?${queryString.stringify(params)}` : '';
  return `/app/${path}${stringifiedParams}`;
};

export const conversationUrl = (accountId, activeInbox, id) => {
  const path = activeInbox
    ? `account/${accountId}/inbox/${activeInbox}/conversations/${id}`
    : `account/${accountId}/conversations/${id}`;
  return path;
};
