export const buildPortalURL = portalSlug => {
  const { hostURL, helpCenterURL } = window.chatwootConfig;
  const baseURL = helpCenterURL || hostURL || '';
  return `${baseURL}/hc/${portalSlug}`;
};

export const buildPortalArticleURL = (
  portalSlug,
  categorySlug,
  locale,
  articleSlug
) => {
  const portalURL = buildPortalURL(portalSlug);
  return `${portalURL}/articles/${articleSlug}`;
};

export const getArticleStatus = status => {
  switch (status) {
    case 'draft':
      return 0;
    case 'published':
      return 1;
    case 'archived':
      return 2;
    default:
      return undefined;
  }
};

// Constants
export const ARTICLE_STATUSES = {
  DRAFT: 'draft',
  PUBLISHED: 'published',
  ARCHIVED: 'archived',
};

export const ARTICLE_MENU_ITEMS = {
  publish: {
    label: 'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.DROPDOWN_MENU.PUBLISH',
    value: ARTICLE_STATUSES.PUBLISHED,
    action: 'publish',
    icon: 'checkmark',
  },
  draft: {
    label: 'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.DROPDOWN_MENU.DRAFT',
    value: ARTICLE_STATUSES.DRAFT,
    action: 'draft',
    icon: 'draft',
  },
  archive: {
    label: 'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.DROPDOWN_MENU.ARCHIVE',
    value: ARTICLE_STATUSES.ARCHIVED,
    action: 'archive',
    icon: 'archive',
  },
  delete: {
    label: 'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.DROPDOWN_MENU.DELETE',
    value: 'delete',
    action: 'delete',
    icon: 'delete',
  },
};

export const ARTICLE_MENU_OPTIONS = {
  [ARTICLE_STATUSES.ARCHIVED]: ['publish', 'draft'],
  [ARTICLE_STATUSES.DRAFT]: ['publish', 'archive'],
  [ARTICLE_STATUSES.PUBLISHED]: ['draft', 'archive'],
};

export const ARTICLE_TABS = {
  ALL: 'all',
  MINE: 'mine',
  DRAFT: 'draft',
  ARCHIVED: 'archived',
};

export const CATEGORY_ALL = 'all';

export const ARTICLE_TABS_OPTIONS = [
  {
    key: 'ALL',
    value: 'all',
  },
  {
    key: 'MINE',
    value: 'mine',
  },
  {
    key: 'DRAFT',
    value: 'draft',
  },
  {
    key: 'ARCHIVED',
    value: 'archived',
  },
];
