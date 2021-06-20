import { getters } from '../../contactLabels';

describe('#getters', () => {
  it('getContactLabels', () => {
    const state = {
      records: { 1: ['customer-success', 'on-hold'] },
    };
    expect(getters.getContactLabels(state)(1)).toEqual([
      'customer-success',
      'on-hold',
    ]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
    });
  });
});
