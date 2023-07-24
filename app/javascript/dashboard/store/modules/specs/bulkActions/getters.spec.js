import { getters } from '../../bulkActions';

describe('#getters', () => {
  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isUpdating: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isUpdating: false,
    });
  });
});
