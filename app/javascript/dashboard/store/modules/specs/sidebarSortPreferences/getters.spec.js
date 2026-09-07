import {
  DEFAULT_SIDEBAR_SORT_PREFERENCES,
  SIDEBAR_SORT_KEYS,
  SIDEBAR_SORT_SECTIONS,
} from 'dashboard/helper/sidebarSort';
import { getters } from '../../sidebarSortPreferences';

describe('#getters', () => {
  it('returns section sort preference', () => {
    const state = {
      preferences: {
        ...DEFAULT_SIDEBAR_SORT_PREFERENCES,
        [SIDEBAR_SORT_SECTIONS.TEAMS]: SIDEBAR_SORT_KEYS.CREATED_ASC,
      },
    };

    expect(getters.getSectionSort(state)(SIDEBAR_SORT_SECTIONS.TEAMS)).toBe(
      SIDEBAR_SORT_KEYS.CREATED_ASC
    );
  });

  it('falls back to default section sort preference', () => {
    const state = {
      preferences: {},
    };

    expect(getters.getSectionSort(state)(SIDEBAR_SORT_SECTIONS.LABELS)).toBe(
      SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC
    );
  });
});
