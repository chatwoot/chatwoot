import { getters } from '../../integrations';

describe('#getters', () => {
  it('getAppIntegrations', () => {
    const state = {
      records: [
        {
          id: 'dyte',
          name: 'dyte',
          logo: 'test',
          enabled: true,
        },
        {
          id: 'dialogflow',
          name: 'test2',
          logo: 'test',
          enabled: true,
        },
      ],
    };
    expect(getters.getAppIntegrations(state)).toEqual([
      {
        id: 'dyte',
        name: 'dyte',
        logo: 'test',
        enabled: true,
      },
      {
        id: 'dialogflow',
        name: 'test2',
        logo: 'test',
        enabled: true,
      },
    ]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isFetchingItem: false,
        isUpdating: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isFetchingItem: false,
      isUpdating: false,
    });
  });
});
