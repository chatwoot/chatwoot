import { getters } from '../../conversationStats';

describe('#getters', () => {
  it('getCurrentPage', () => {
    const state = {
      mineCount: 1,
      unAssignedCount: 1,
      allCount: 2,
    };
    expect(getters.getStats(state)).toEqual({
      mineCount: 1,
      unAssignedCount: 1,
      allCount: 2,
    });
  });
});
