import { getters } from '../../conversationTypingStatus';

describe('#getters', () => {
  it('getUserList', () => {
    const state = {
      records: {
        1: [
          { id: 1, name: 'user-1' },
          { id: 2, name: 'user-2' },
        ],
      },
    };
    expect(getters.getUserList(state)(1)).toEqual([
      { id: 1, name: 'user-1' },
      { id: 2, name: 'user-2' },
    ]);
    expect(getters.getUserList(state)(2)).toEqual([]);
  });
});
