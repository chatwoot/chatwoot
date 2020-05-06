import { getters } from '../../conversation';

describe('#getters', () => {
  it('getConversation', () => {
    const state = {
      conversations: {
        1: {
          content: 'hello',
        },
      },
    };
    expect(getters.getConversation(state)).toEqual({
      1: {
        content: 'hello',
      },
    });
  });

  it('getConversationSize', () => {
    const state = {
      conversations: {
        1: {
          content: 'hello',
        },
      },
    };
    expect(getters.getConversationSize(state)).toEqual(1);
  });

  it('getEarliestMessage', () => {
    const state = {
      conversations: {
        1: {
          content: 'hello',
        },
        2: {
          content: 'hello1',
        },
      },
    };
    expect(getters.getEarliestMessage(state)).toEqual({
      content: 'hello',
    });
  });

  it('uiFlags', () => {
    const state = {
      uiFlags: {
        allMessagesLoaded: false,
        isFetchingList: false,
        isAgentTyping: false,
      },
    };
    expect(getters.getAllMessagesLoaded(state)).toEqual(false);
    expect(getters.getIsFetchingList(state)).toEqual(false);
    expect(getters.getIsAgentTyping(state)).toEqual(false);
  });

  it('uiFlags', () => {
    const state = {
      conversations: {
        1: {
          id: 1,
          content: 'Thanks for the help',
          created_at: 1574075964,
          message_type: 0,
        },
        2: {
          id: 2,
          content: 'Yes, It makes sense',
          created_at: 1574092218,
          message_type: 0,
        },
        3: {
          id: 3,
          content: 'Hey',
          created_at: 1574092218,
          message_type: 1,
        },
        4: {
          id: 4,
          content: 'Hey',
          created_at: 1576340623,
        },
        5: {
          id: 5,
          content: 'How may I help you',
          created_at: 1576340626,
        },
      },
    };
    expect(getters.getGroupedConversation(state)).toEqual([
      {
        date: 'Nov 18, 2019',
        messages: [
          {
            id: 1,
            content: 'Thanks for the help',
            created_at: 1574075964,
            showAvatar: false,
            message_type: 0,
          },
          {
            id: 2,
            content: 'Yes, It makes sense',
            created_at: 1574092218,
            showAvatar: true,
            message_type: 0,
          },
          {
            id: 3,
            content: 'Hey',
            created_at: 1574092218,
            showAvatar: true,
            message_type: 1,
          },
        ],
      },
      {
        date: 'Dec 14, 2019',
        messages: [
          {
            id: 4,
            content: 'Hey',
            created_at: 1576340623,
            showAvatar: false,
          },
          {
            id: 5,
            content: 'How may I help you',
            created_at: 1576340626,
            showAvatar: true,
          },
        ],
      },
    ]);
  });
});
