/**
 * Formats a custom domain with https protocol if needed
 * @param {string} customDomain - The custom domain to format
 * @returns {string} Formatted domain with https protocol
 */
const formatCustomDomain = customDomain =>
  customDomain.startsWith('https') ? customDomain : `https://${customDomain}`;

/**
 * Gets the default base URL from configuration
 * @returns {string} The default base URL
 * @throws {Error} If no valid base URL is found
 */
const getDefaultBaseURL = () => {
  const { hostURL, helpCenterURL } = window.chatwootConfig || {};
  const baseURL = helpCenterURL || hostURL || '';

  if (!baseURL) {
    throw new Error('No valid base URL found in configuration');
  }

  return baseURL;
};

/**
 * Gets the base URL from configuration or custom domain
 * @param {string} [customDomain] - Optional custom domain for the portal
 * @returns {string} The base URL for the portal
 */
const getPortalBaseURL = customDomain =>
  customDomain ? formatCustomDomain(customDomain) : getDefaultBaseURL();

/**
 * Builds a portal URL using the provided portal slug and optional custom domain
 * @param {string} portalSlug - The slug identifier for the portal
 * @param {string} [customDomain] - Optional custom domain for the portal
 * @returns {string} The complete portal URL
 * @throws {Error} If portalSlug is not provided or invalid
 */
export const buildPortalURL = (portalSlug, customDomain) => {
  const baseURL = getPortalBaseURL(customDomain);
  return `${baseURL}/hc/${portalSlug}`;
};

export const buildPortalArticleURL = (
  portalSlug,
  categorySlug,
  locale,
  articleSlug,
  customDomain
) => {
  const portalURL = buildPortalURL(portalSlug, customDomain);
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
export const HELP_CENTER_MENU_ITEMS = [
  {
    label: 'Articles',
    icon: 'i-lucide-book',
    action: 'portals_articles_index',
    value: [
      'portals_articles_index',
      'portals_articles_new',
      'portals_articles_edit',
    ],
  },
  {
    label: 'Categories',
    icon: 'i-lucide-folder',
    action: 'portals_categories_index',
    value: [
      'portals_categories_index',
      'portals_categories_articles_index',
      'portals_categories_articles_edit',
    ],
  },
  {
    label: 'Locales',
    icon: 'i-lucide-languages',
    action: 'portals_locales_index',
    value: ['portals_locales_index'],
  },
  {
    label: 'Settings',
    icon: 'i-lucide-settings',
    action: 'portals_settings_index',
    value: ['portals_settings_index'],
  },
];

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
    icon: 'i-lucide-check',
  },
  draft: {
    label: 'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.DROPDOWN_MENU.DRAFT',
    value: ARTICLE_STATUSES.DRAFT,
    action: 'draft',
    icon: 'i-lucide-pencil-line',
  },
  archive: {
    label: 'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.DROPDOWN_MENU.ARCHIVE',
    value: ARTICLE_STATUSES.ARCHIVED,
    action: 'archive',
    icon: 'i-lucide-archive-restore',
  },
  delete: {
    label: 'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.DROPDOWN_MENU.DELETE',
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
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

export const LOCALE_MENU_ITEMS = [
  {
    label: 'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.MAKE_DEFAULT',
    action: 'change-default',
    value: 'default',
    icon: 'i-lucide-star',
  },
  {
    label: 'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.DELETE',
    action: 'delete',
    value: 'delete',
    icon: 'i-lucide-trash',
  },
];

export const ARTICLE_EDITOR_STATUS_OPTIONS = {
  published: ['archive', 'draft'],
  archived: ['draft'],
  draft: ['archive'],
};
