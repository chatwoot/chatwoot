import { getters } from '../../accounts';
import * as languageHelpers from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

const accountData = {
  id: 1,
  name: 'Company one',
  locale: 'en',
  features: {
    auto_resolve_conversations: true,
    agent_management: false,
  },
};

describe('#getters', () => {
  it('getAccount', () => {
    const state = {
      records: [accountData],
    };
    expect(getters.getAccount(state)(1)).toEqual(accountData);
  });
  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    });
  });

  it('isFeatureEnabledonAccount', () => {
    const state = {
      records: [accountData],
    };
    expect(
      getters.isFeatureEnabledonAccount(
        state,
        null,
        null
      )(1, 'auto_resolve_conversations')
    ).toEqual(true);
  });

  describe('isRTL', () => {
    it('returns false when accountId is not present', () => {
      const rootState = { route: { params: {} } };
      const userLocale = null; // No user-selected locale
      expect(getters.isRTL({}, null, rootState)(userLocale)).toBe(false);
    });

    it('returns true for RTL language', () => {
      const state = {
        records: [{ id: 1, locale: 'ar' }],
      };
      const rootState = { route: { params: { accountId: '1' } } };
      const userLocale = 'ar'; // User-selected locale is Arabic
      vi.spyOn(languageHelpers, 'getLanguageDirection').mockReturnValue(true);
      expect(getters.isRTL(state, null, rootState)(userLocale)).toBe(true);
    });

    it('returns false for LTR language', () => {
      const state = {
        records: [{ id: 1, locale: 'en' }],
      };
      const rootState = { route: { params: { accountId: '1' } } };
      const userLocale = 'en'; // User-selected locale is English
      vi.spyOn(languageHelpers, 'getLanguageDirection').mockReturnValue(false);
      expect(getters.isRTL(state, null, rootState)(userLocale)).toBe(false);
    });

    it('returns false when account is not found', () => {
      const state = {
        records: [],
      };
      const rootState = { route: { params: { accountId: '1' } } };
      const userLocale = null; // No user-selected locale
      expect(getters.isRTL(state, null, rootState)(userLocale)).toBe(false);
    });

    it('falls back to account locale when userLocale is not provided', () => {
      const state = {
        records: [{ id: 1, locale: 'ar' }],
      };
      const rootState = { route: { params: { accountId: '1' } } };
      const userLocale = null; // No user-selected locale
      vi.spyOn(languageHelpers, 'getLanguageDirection').mockReturnValue(true);
      expect(getters.isRTL(state, null, rootState)(userLocale)).toBe(true);
    });
  });
});
