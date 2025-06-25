import { getters } from '../../conversationSearch';

describe('#getters', () => {
  it('getConversations', () => {
    const state = {
      records: [{ id: 1, messages: [{ id: 1, content: 'value' }] }],
    };
    expect(getters.getConversations(state)).toEqual([
      { id: 1, messages: [{ id: 1, content: 'value' }] },
    ]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: { isFetching: false },
    };
    expect(getters.getUIFlags(state)).toEqual({ isFetching: false });
  });
});
