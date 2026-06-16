import { LocalStorage } from 'shared/helpers/localStorage';
import {
  DEFAULT_SIDEBAR_SORT_PREFERENCES,
  SIDEBAR_SORT_KEYS,
  SIDEBAR_SORT_SECTIONS,
} from 'dashboard/helper/sidebarSort';
import {
  SET_SIDEBAR_SORT_PREFERENCES,
  actions,
} from '../../sidebarSortPreferences';

vi.mock('shared/helpers/localStorage', () => ({
  LocalStorage: {
    getFromJsonStore: vi.fn(),
    updateJsonStore: vi.fn(),
  },
}));

const rootGetters = {
  getCurrentUserID: 1,
  getCurrentAccountId: 2,
};

describe('#actions', () => {
  const commit = vi.fn();

  beforeEach(() => {
    commit.mockClear();
    LocalStorage.getFromJsonStore.mockReset();
    LocalStorage.updateJsonStore.mockReset();
  });

  describe('#initialize', () => {
    it('loads scoped preferences from local storage', () => {
      LocalStorage.getFromJsonStore.mockReturnValue({
        [SIDEBAR_SORT_SECTIONS.FOLDERS]: SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC,
      });

      actions.initialize({ commit, rootGetters });

      expect(LocalStorage.getFromJsonStore).toHaveBeenCalledWith(
        'chatwoot_sidebar_sort_preferences',
        '1:2'
      );
      expect(commit).toHaveBeenCalledWith(SET_SIDEBAR_SORT_PREFERENCES, {
        preferences: {
          ...DEFAULT_SIDEBAR_SORT_PREFERENCES,
          [SIDEBAR_SORT_SECTIONS.FOLDERS]: SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC,
        },
        storageKey: '1:2',
      });
    });
  });

  describe('#setSectionSort', () => {
    it('persists valid preferences to local storage', () => {
      const state = {
        preferences: DEFAULT_SIDEBAR_SORT_PREFERENCES,
        storageKey: '1:2',
      };

      actions.setSectionSort(
        { commit, rootGetters, state },
        {
          section: SIDEBAR_SORT_SECTIONS.LABELS,
          sortBy: SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
        }
      );

      const preferences = {
        ...DEFAULT_SIDEBAR_SORT_PREFERENCES,
        [SIDEBAR_SORT_SECTIONS.LABELS]: SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
      };

      expect(commit).toHaveBeenCalledWith(SET_SIDEBAR_SORT_PREFERENCES, {
        preferences,
        storageKey: '1:2',
      });
      expect(LocalStorage.updateJsonStore).toHaveBeenCalledWith(
        'chatwoot_sidebar_sort_preferences',
        '1:2',
        preferences
      );
    });

    it('ignores invalid preferences', () => {
      actions.setSectionSort(
        {
          commit,
          rootGetters,
          state: {
            preferences: DEFAULT_SIDEBAR_SORT_PREFERENCES,
            storageKey: '1:2',
          },
        },
        {
          section: SIDEBAR_SORT_SECTIONS.FOLDERS,
          sortBy: SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
        }
      );

      expect(commit).not.toHaveBeenCalled();
      expect(LocalStorage.updateJsonStore).not.toHaveBeenCalled();
    });
  });
});
