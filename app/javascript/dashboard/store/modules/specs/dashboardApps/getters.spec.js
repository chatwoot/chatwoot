import { getters } from '../../dashboardApps';

describe('#getters', () => {
  it('getRecords', () => {
    const state = {
      records: [
        {
          title: '1',
          content: [{ link: 'https://google.com', type: 'frame' }],
        },
      ],
    };
    expect(getters.getRecords(state)).toEqual(state.records);
  });
  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
      isDeleting: false,
    });
  });

  it('getAppsOnSidebar', () => {
    const state = {
      records: [
        {
          id: 1,
          title: 'Zebra App',
          show_on_sidebar: true,
        },
        {
          id: 2,
          title: 'Alpha App',
          show_on_sidebar: true,
        },
        {
          id: 3,
          title: 'Beta App',
          show_on_sidebar: false,
        },
      ],
    };
    const result = getters.getAppsOnSidebar(state);
    expect(result).toHaveLength(2);
    expect(result[0].title).toEqual('Alpha App');
    expect(result[1].title).toEqual('Zebra App');
  });
});
