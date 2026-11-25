import {
  DEFAULT_SIDEBAR_SORT_PREFERENCES,
  SIDEBAR_SORT_KEYS,
  SIDEBAR_SORT_SECTIONS,
} from 'dashboard/helper/sidebarSort';
import {
  SET_SIDEBAR_SORT_PREFERENCES,
  mutations,
} from '../../sidebarSortPreferences';

describe('#mutations', () => {
  it('sets normalized preferences', () => {
    const state = {
      preferences: {},
      storageKey: null,
    };

    mutations[SET_SIDEBAR_SORT_PREFERENCES](state, {
      preferences: {
        [SIDEBAR_SORT_SECTIONS.FOLDERS]: SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
        [SIDEBAR_SORT_SECTIONS.LABELS]: 'invalid',
      },
      storageKey: '1:2',
    });

    expect(state).toEqual({
      preferences: {
        ...DEFAULT_SIDEBAR_SORT_PREFERENCES,
        [SIDEBAR_SORT_SECTIONS.FOLDERS]: SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
      },
      storageKey: '1:2',
    });
  });
});
