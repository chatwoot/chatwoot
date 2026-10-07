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

  it('getConversationNeighbours', () => {
    const state = { neighbours: { 13: [{ id: 11 }, { id: 13 }] } };
    expect(getters.getConversationNeighbours(state)(13)).toEqual([
      { id: 11 },
      { id: 13 },
    ]);
    expect(getters.getConversationNeighbours(state)(99)).toEqual([]);
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
