import { getters } from '../../contactConversations';

describe('#getters', () => {
  it('getContactConversation', () => {
    const state = {
      records: { 1: [{ id: 1, contact_id: 1, message: 'Hello' }] },
    };
    expect(getters.getContactConversation(state)(1)).toEqual([
      { id: 1, contact_id: 1, message: 'Hello' },
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
