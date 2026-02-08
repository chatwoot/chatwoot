import { getters } from '../../conversationWatchers';
import watchersData from './fixtures';

describe('#getters', () => {
  it('getByConversationId', () => {
    const state = { records: { 1: watchersData } };
    expect(getters.getByConversationId(state)(1)).toEqual(watchersData);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: false,
        isUpdating: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: false,
      isUpdating: false,
    });
  });
});
