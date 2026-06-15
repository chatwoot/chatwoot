export const SIDEBAR_SORT_KEYS = Object.freeze({
  CREATED_DESC: 'created_at_desc',
  CREATED_ASC: 'created_at_asc',
  ALPHABETICAL_ASC: 'alphabetical_asc',
  ALPHABETICAL_DESC: 'alphabetical_desc',
  UNREAD_COUNT_DESC: 'unread_count_desc',
  UNREAD_COUNT_ASC: 'unread_count_asc',
});

export const SIDEBAR_SORT_SECTIONS = Object.freeze({
  FOLDERS: 'folders',
  TEAMS: 'teams',
  CHANNELS: 'channels',
  LABELS: 'labels',
});

export const SIDEBAR_SORT_OPTIONS_BY_SECTION = Object.freeze({
  [SIDEBAR_SORT_SECTIONS.FOLDERS]: [
    SIDEBAR_SORT_KEYS.CREATED_DESC,
    SIDEBAR_SORT_KEYS.CREATED_ASC,
    SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC,
    SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
  ],
  [SIDEBAR_SORT_SECTIONS.TEAMS]: [
    SIDEBAR_SORT_KEYS.CREATED_DESC,
    SIDEBAR_SORT_KEYS.CREATED_ASC,
    SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC,
    SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
    SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
    SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC,
  ],
  [SIDEBAR_SORT_SECTIONS.CHANNELS]: [
    SIDEBAR_SORT_KEYS.CREATED_DESC,
    SIDEBAR_SORT_KEYS.CREATED_ASC,
    SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC,
    SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
    SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
    SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC,
  ],
  [SIDEBAR_SORT_SECTIONS.LABELS]: [
    SIDEBAR_SORT_KEYS.CREATED_DESC,
    SIDEBAR_SORT_KEYS.CREATED_ASC,
    SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC,
    SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
    SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
    SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC,
  ],
});

const UNREAD_COUNT_SORT_OPTIONS = [
  SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
  SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC,
];

export const DEFAULT_SIDEBAR_SORT_PREFERENCES = Object.freeze({
  [SIDEBAR_SORT_SECTIONS.FOLDERS]: SIDEBAR_SORT_KEYS.CREATED_DESC,
  [SIDEBAR_SORT_SECTIONS.TEAMS]: SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
  [SIDEBAR_SORT_SECTIONS.CHANNELS]: SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
  [SIDEBAR_SORT_SECTIONS.LABELS]: SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
});

export const isValidSidebarSort = (section, sortBy) => {
  return SIDEBAR_SORT_OPTIONS_BY_SECTION[section]?.includes(sortBy);
};

const isUnreadCountSort = sortBy => UNREAD_COUNT_SORT_OPTIONS.includes(sortBy);

export const getSidebarSortOptions = (
  section,
  { hasUnreadCounts = true } = {}
) => {
  const options = SIDEBAR_SORT_OPTIONS_BY_SECTION[section] || [];

  if (hasUnreadCounts) return options;

  return options.filter(option => !isUnreadCountSort(option));
};

export const resolveSidebarSort = (
  section,
  sortBy,
  { hasUnreadCounts = true } = {}
) => {
  const options = getSidebarSortOptions(section, { hasUnreadCounts });

  if (options.includes(sortBy)) return sortBy;
  if (!hasUnreadCounts && isUnreadCountSort(sortBy)) {
    return SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC;
  }

  return options[0] || SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC;
};

export const normalizeSidebarSortPreferences = (preferences = {}) => {
  const savedPreferences = preferences || {};

  return Object.keys(DEFAULT_SIDEBAR_SORT_PREFERENCES).reduce(
    (result, section) => {
      const sortBy = savedPreferences[section];
      result[section] = isValidSidebarSort(section, sortBy)
        ? sortBy
        : DEFAULT_SIDEBAR_SORT_PREFERENCES[section];
      return result;
    },
    {}
  );
};

const normalizeUnreadCount = count => {
  const unreadCount = Number(count);
  return Number.isFinite(unreadCount) && unreadCount > 0 ? unreadCount : 0;
};

const getCreatedValue = item => {
  const createdAt = item.created_at || item.createdAt;

  if (typeof createdAt === 'number') return createdAt;

  if (createdAt) {
    const timestamp = Date.parse(createdAt);
    if (Number.isFinite(timestamp)) return timestamp;
  }

  const id = Number(item.id);
  return Number.isFinite(id) ? id : 0;
};

const getLabelValue = (item, labelKey) => {
  return String(labelKey(item) || '');
};

const compareAlphabetically = (a, b, labelKey) => {
  return getLabelValue(a, labelKey).localeCompare(
    getLabelValue(b, labelKey),
    undefined,
    {
      sensitivity: 'base',
    }
  );
};

export const sortSidebarItems = (
  items,
  { sortBy, labelKey, unreadCountKey = () => 0 }
) => {
  return (items || []).slice().sort((a, b) => {
    if (sortBy === SIDEBAR_SORT_KEYS.CREATED_DESC) {
      const createdDiff = getCreatedValue(b) - getCreatedValue(a);
      if (createdDiff !== 0) return createdDiff;
      return compareAlphabetically(a, b, labelKey);
    }

    if (sortBy === SIDEBAR_SORT_KEYS.CREATED_ASC) {
      const createdDiff = getCreatedValue(a) - getCreatedValue(b);
      if (createdDiff !== 0) return createdDiff;
      return compareAlphabetically(a, b, labelKey);
    }

    if (sortBy === SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC) {
      return compareAlphabetically(b, a, labelKey);
    }

    if (sortBy === SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC) {
      const unreadCountDiff =
        normalizeUnreadCount(unreadCountKey(b)) -
        normalizeUnreadCount(unreadCountKey(a));

      if (unreadCountDiff !== 0) return unreadCountDiff;
    }

    if (sortBy === SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC) {
      const unreadCountDiff =
        normalizeUnreadCount(unreadCountKey(a)) -
        normalizeUnreadCount(unreadCountKey(b));

      if (unreadCountDiff !== 0) return unreadCountDiff;
    }

    return compareAlphabetically(a, b, labelKey);
  });
};
