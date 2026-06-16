import {
  DEFAULT_SIDEBAR_SORT_PREFERENCES,
  SIDEBAR_SORT_KEYS,
  SIDEBAR_SORT_SECTIONS,
  getSidebarSortOptions,
  normalizeSidebarSortPreferences,
  resolveSidebarSort,
  sortSidebarItems,
} from '../sidebarSort';

const items = [
  {
    id: 1,
    name: 'Billing',
    created_at: '2024-01-01T00:00:00.000Z',
  },
  {
    id: 3,
    name: 'Accounts',
    created_at: '2024-03-01T00:00:00.000Z',
  },
  {
    id: 2,
    name: 'Support',
    created_at: '2024-02-01T00:00:00.000Z',
  },
];

describe('#sortSidebarItems', () => {
  it('sorts by created date descending', () => {
    const sortedItems = sortSidebarItems(items, {
      sortBy: SIDEBAR_SORT_KEYS.CREATED_DESC,
      labelKey: item => item.name,
    });

    expect(sortedItems.map(item => item.name)).toEqual([
      'Accounts',
      'Support',
      'Billing',
    ]);
  });

  it('sorts by created date ascending', () => {
    const sortedItems = sortSidebarItems(items, {
      sortBy: SIDEBAR_SORT_KEYS.CREATED_ASC,
      labelKey: item => item.name,
    });

    expect(sortedItems.map(item => item.name)).toEqual([
      'Billing',
      'Support',
      'Accounts',
    ]);
  });

  it('falls back to id when created date is not present', () => {
    const sortedItems = sortSidebarItems(
      items.map(({ created_at: _createdAt, ...item }) => item),
      {
        sortBy: SIDEBAR_SORT_KEYS.CREATED_DESC,
        labelKey: item => item.name,
      }
    );

    expect(sortedItems.map(item => item.id)).toEqual([3, 2, 1]);
  });

  it('sorts alphabetically from A to Z', () => {
    const sortedItems = sortSidebarItems(items, {
      sortBy: SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC,
      labelKey: item => item.name,
    });

    expect(sortedItems.map(item => item.name)).toEqual([
      'Accounts',
      'Billing',
      'Support',
    ]);
  });

  it('sorts alphabetically from Z to A', () => {
    const sortedItems = sortSidebarItems(items, {
      sortBy: SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
      labelKey: item => item.name,
    });

    expect(sortedItems.map(item => item.name)).toEqual([
      'Support',
      'Billing',
      'Accounts',
    ]);
  });

  it('sorts by unread count descending and falls back to alphabetical order', () => {
    const unreadCounts = {
      1: 3,
      2: 3,
      3: 7,
    };

    const sortedItems = sortSidebarItems(items, {
      sortBy: SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
      labelKey: item => item.name,
      unreadCountKey: item => unreadCounts[item.id],
    });

    expect(sortedItems.map(item => item.name)).toEqual([
      'Accounts',
      'Billing',
      'Support',
    ]);
  });

  it('sorts by unread count ascending and falls back to alphabetical order', () => {
    const unreadCounts = {
      1: 3,
      2: 3,
      3: 7,
    };

    const sortedItems = sortSidebarItems(items, {
      sortBy: SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC,
      labelKey: item => item.name,
      unreadCountKey: item => unreadCounts[item.id],
    });

    expect(sortedItems.map(item => item.name)).toEqual([
      'Billing',
      'Support',
      'Accounts',
    ]);
  });
});

describe('#normalizeSidebarSortPreferences', () => {
  it('keeps valid preferences', () => {
    const preferences = normalizeSidebarSortPreferences({
      [SIDEBAR_SORT_SECTIONS.FOLDERS]: SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
      [SIDEBAR_SORT_SECTIONS.TEAMS]: SIDEBAR_SORT_KEYS.CREATED_ASC,
    });

    expect(preferences).toEqual({
      ...DEFAULT_SIDEBAR_SORT_PREFERENCES,
      [SIDEBAR_SORT_SECTIONS.FOLDERS]: SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
      [SIDEBAR_SORT_SECTIONS.TEAMS]: SIDEBAR_SORT_KEYS.CREATED_ASC,
    });
  });

  it('falls back to defaults for unsupported preferences', () => {
    const preferences = normalizeSidebarSortPreferences({
      [SIDEBAR_SORT_SECTIONS.FOLDERS]: SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
    });

    expect(preferences).toEqual(DEFAULT_SIDEBAR_SORT_PREFERENCES);
  });

  it('falls back to defaults when stored preferences are null', () => {
    expect(normalizeSidebarSortPreferences(null)).toEqual(
      DEFAULT_SIDEBAR_SORT_PREFERENCES
    );
  });
});

describe('#getSidebarSortOptions', () => {
  it('keeps unread count options when unread counts are enabled', () => {
    const options = getSidebarSortOptions(SIDEBAR_SORT_SECTIONS.TEAMS, {
      hasUnreadCounts: true,
    });

    expect(options).toContain(SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC);
    expect(options).toContain(SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC);
  });

  it('removes unread count options when unread counts are disabled', () => {
    const options = getSidebarSortOptions(SIDEBAR_SORT_SECTIONS.TEAMS, {
      hasUnreadCounts: false,
    });

    expect(options).not.toContain(SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC);
    expect(options).not.toContain(SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC);
    expect(options).toContain(SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC);
  });
});

describe('#resolveSidebarSort', () => {
  it('keeps unread count sort when unread counts are enabled', () => {
    const sortBy = resolveSidebarSort(
      SIDEBAR_SORT_SECTIONS.TEAMS,
      SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
      { hasUnreadCounts: true }
    );

    expect(sortBy).toBe(SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC);
  });

  it('falls back to alphabetical sort when unread counts are disabled', () => {
    const sortBy = resolveSidebarSort(
      SIDEBAR_SORT_SECTIONS.TEAMS,
      SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
      { hasUnreadCounts: false }
    );

    expect(sortBy).toBe(SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC);
  });
});
