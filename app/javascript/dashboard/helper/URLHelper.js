export const frontendURL = (path, params) => {
  const stringifiedParams = params ? `?${new URLSearchParams(params)}` : '';
  return `/app/${path}${stringifiedParams}`;
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
  } else if (conversationType === 'participating') {
    url = `accounts/${accountId}/participating/conversations/${id}`;
  } else if (conversationType === 'unattended') {
    url = `accounts/${accountId}/unattended/conversations/${id}`;
  }
  return url;
};

export const conversationListPageURL = ({
  accountId,
  conversationType = '',
  inboxId,
  label,
  teamId,
  customViewId,
}) => {
  let url = `accounts/${accountId}/dashboard`;
  if (label) {
    url = `accounts/${accountId}/label/${label}`;
  } else if (teamId) {
    url = `accounts/${accountId}/team/${teamId}`;
  } else if (inboxId) {
    url = `accounts/${accountId}/inbox/${inboxId}`;
  } else if (customViewId) {
    url = `accounts/${accountId}/custom_view/${customViewId}`;
  } else if (conversationType) {
    const urlMap = {
      mention: 'mentions/conversations',
      unattended: 'unattended/conversations',
    };
    url = `accounts/${accountId}/${urlMap[conversationType]}`;
  }
  return frontendURL(url);
};

export const isValidURL = value => {
  /* eslint-disable no-useless-escape */
  const URL_REGEX =
    /^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$/gm;
  return URL_REGEX.test(value);
};

export const getArticleSearchURL = ({
  host,
  portalSlug,
  pageNumber,
  locale,
  status,
  authorId,
  categorySlug,
  sort,
  query,
}) => {
  const queryParams = new URLSearchParams({});

  const params = {
    page: pageNumber,
    locale,
    status,
    author_id: authorId,
    category_slug: categorySlug,
    sort,
    query,
  };

  Object.entries(params).forEach(([key, value]) => {
    if (value !== null && value !== undefined) {
      queryParams.set(key, value);
    }
  });

  return `${host}/${portalSlug}/articles?${queryParams.toString()}`;
};

export const hasValidAvatarUrl = avatarUrl => {
  try {
    const { host: avatarUrlHost } = new URL(avatarUrl);
    const isFromGravatar = ['www.gravatar.com', 'gravatar'].includes(
      avatarUrlHost
    );
    return avatarUrl && !isFromGravatar;
  } catch (error) {
    return false;
  }
};
