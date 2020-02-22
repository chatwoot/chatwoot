import queryString from 'query-string';

export const frontendURL = (path, params) => {
  const stringifiedParams = params ? `?${queryString.stringify(params)}` : '';
  return `/app/${path}${stringifiedParams}`;
};

export const conversationUrl = (activeInbox, id) => {
  const path = activeInbox
    ? `inbox/${activeInbox}/conversations/${id}`
    : `conversations/${id}`;
  return path;
};
