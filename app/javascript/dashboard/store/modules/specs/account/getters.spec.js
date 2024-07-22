import { getters } from '../../accounts';

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
});
