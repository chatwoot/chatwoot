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
});
