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
    afterEach(() => {
      vi.restoreAllMocks();
    });

    it('returns false when accountId is not present and userLocale is not set', () => {
      const state = { records: [accountData] };
      const rootState = { route: { params: {} } };
      const rootGetters = {};

      expect(getters.isRTL(state, null, rootState, rootGetters)).toBe(false);
    });

    it('uses userLocale when present (no accountId)', () => {
      const state = { records: [accountData] };
      const rootState = { route: { params: {} } };
      const rootGetters = { getUISettings: { locale: 'ar' } };
      const spy = vi
        .spyOn(languageHelpers, 'getLanguageDirection')
        .mockReturnValue(true);

      expect(getters.isRTL(state, null, rootState, rootGetters)).toBe(true);
      expect(spy).toHaveBeenCalledWith('ar');
    });

    it('prefers userLocale over account locale when both are present', () => {
      const state = { records: [{ id: 1, locale: 'en' }] };
      const rootState = { route: { params: { accountId: '1' } } };
      const rootGetters = { getUISettings: { locale: 'ar' } };
      const spy = vi
        .spyOn(languageHelpers, 'getLanguageDirection')
        .mockReturnValue(true);

      expect(getters.isRTL(state, null, rootState, rootGetters)).toBe(true);
      expect(spy).toHaveBeenCalledWith('ar');
    });

    it('falls back to account locale when userLocale is not provided', () => {
      const state = { records: [{ id: 1, locale: 'ar' }] };
      const rootState = { route: { params: { accountId: '1' } } };
      const rootGetters = {};
      const spy = vi
        .spyOn(languageHelpers, 'getLanguageDirection')
        .mockReturnValue(true);

      expect(getters.isRTL(state, null, rootState, rootGetters)).toBe(true);
      expect(spy).toHaveBeenCalledWith('ar');
    });

    it('returns false for LTR language when userLocale is provided', () => {
      const state = { records: [{ id: 1, locale: 'en' }] };
      const rootState = { route: { params: { accountId: '1' } } };
      const rootGetters = { getUISettings: { locale: 'en' } };
      const spy = vi
        .spyOn(languageHelpers, 'getLanguageDirection')
        .mockReturnValue(false);

      expect(getters.isRTL(state, null, rootState, rootGetters)).toBe(false);
      expect(spy).toHaveBeenCalledWith('en');
    });

    it('returns false when accountId present but user locale is null', () => {
      const state = { records: [{ id: 1, locale: 'en' }] };
      const rootState = { route: { params: { accountId: '1' } } };
      const rootGetters = { getUISettings: { locale: null } };
      const spy = vi.spyOn(languageHelpers, 'getLanguageDirection');

      expect(getters.isRTL(state, null, rootState, rootGetters)).toBe(false);
      expect(spy).toHaveBeenCalledWith('en');
    });
  });
});
