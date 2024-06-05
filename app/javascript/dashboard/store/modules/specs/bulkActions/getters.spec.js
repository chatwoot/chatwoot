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
  it('getSelectedConversationIds', () => {
    const state = {
      selectedConversationIds: [1, 2, 3],
    };
    expect(getters.getSelectedConversationIds(state)).toEqual([1, 2, 3]);
  });
});
