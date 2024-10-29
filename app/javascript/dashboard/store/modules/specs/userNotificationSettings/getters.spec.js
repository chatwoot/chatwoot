import { getters } from '../../userNotificationSettings';

describe('#getters', () => {
  it('getSelectedEmailFlags', () => {
    const state = {
      record: {
        selected_email_flags: ['conversation_creation'],
      },
    };
    expect(getters.getSelectedEmailFlags(state)).toEqual([
      'conversation_creation',
    ]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        fetchingList: false,
        fetchingItem: false,
        creatingItem: false,
        updatingItem: false,
        deletingItem: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      fetchingList: false,
      fetchingItem: false,
      creatingItem: false,
      updatingItem: false,
      deletingItem: false,
    });
  });
});
