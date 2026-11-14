import { getters } from '../../conversation/getters';

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

  it('getIsCreating', () => {
    const state = { uiFlags: { isCreating: true } };
    expect(getters.getIsCreating(state)).toEqual(true);
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
          id: 1,
          content: 'hello',
        },
        2: {
          id: 2,
          content: 'hello1',
        },
      },
    };
    expect(getters.getEarliestMessage(state)).toEqual({
      id: 1,
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

  it('getGroupedConversation', () => {
    expect(
      getters.getGroupedConversation({
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
      })
    ).toEqual([
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

    expect(
      getters.getGroupedConversation({
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
            message_type: 2,
            content_type: 'form',
            content_attributes: {
              submitted_values: [{ name: 'text', value: 'sample text' }],
            },
          },
          6: {
            id: 6,
            content: 'How may I help you',
            created_at: 1576340626,
            message_type: 2,
            content_type: 'form',
          },
          7: {
            id: 7,
            content: 'How may I help you',
            created_at: 1576340626,
            message_type: 2,
            content_type: 'form',
            content_attributes: {
              submitted_values: [{ name: 'text', value: 'sample text' }],
            },
          },
        },
      })
    ).toEqual([
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
            showAvatar: true,
          },
          {
            id: 5,
            content: 'How may I help you',
            created_at: 1576340626,
            message_type: 2,
            content_type: 'form',
            content_attributes: {
              submitted_values: [{ name: 'text', value: 'sample text' }],
            },
            showAvatar: false,
          },
          {
            id: 6,
            content: 'How may I help you',
            created_at: 1576340626,
            message_type: 2,
            content_type: 'form',
            showAvatar: true,
          },
          {
            id: 7,
            content: 'How may I help you',
            created_at: 1576340626,
            message_type: 2,
            content_type: 'form',
            content_attributes: {
              submitted_values: [{ name: 'text', value: 'sample text' }],
            },

            showAvatar: false,
          },
        ],
      },
    ]);
  });

  describe('getUnreadMessageCount returns', () => {
    it('0 if there are no messages and last seen is undefined', () => {
      const state = {
        conversations: {},
        meta: {
          userLastSeenAt: undefined,
        },
      };
      expect(getters.getUnreadMessageCount(state)).toEqual(0);
    });

    it('0 if there are no messages and last seen is present', () => {
      const state = {
        conversations: {},
        meta: {
          userLastSeenAt: Date.now(),
        },
      };
      expect(getters.getUnreadMessageCount(state)).toEqual(0);
    });

    it('unread count if there are messages and last seen is before messages created-at', () => {
      const state = {
        conversations: {
          1: {
            id: 1,
            content: 'Thanks for the help',
            created_at: 1574075964,
            message_type: 1,
          },
          2: {
            id: 2,
            content: 'Yes, It makes sense',
            created_at: 1574092218,
            message_type: 1,
          },
        },
        meta: {
          userLastSeenAt: 1474075964,
        },
      };
      expect(getters.getUnreadMessageCount(state)).toEqual(2);
    });

    it('unread count if there are messages and last seen is after messages created-at', () => {
      const state = {
        conversations: {
          1: {
            id: 1,
            content: 'Thanks for the help',
            created_at: 1574075964,
            message_type: 1,
          },
          2: {
            id: 2,
            content: 'Yes, It makes sense',
            created_at: 1574092218,
            message_type: 1,
          },
          3: {
            id: 3,
            content: 'Yes, It makes sense',
            created_at: 1574092218,
            message_type: 0,
          },
        },
        meta: {
          userLastSeenAt: 1674075964,
        },
      };
      expect(getters.getUnreadMessageCount(state)).toEqual(0);
    });
  });

  describe('getUnreadTextMessages returns', () => {
    it('no messages if there are no messages and last seen is undefined', () => {
      const state = {
        conversations: {},
        meta: {
          userLastSeenAt: undefined,
        },
      };
      expect(
        getters.getUnreadTextMessages(state, { getUnreadMessageCount: 0 })
      ).toEqual([]);
    });

    it('0 if there are no messages and last seen is present', () => {
      const state = {
        conversations: {},
        meta: {
          userLastSeenAt: Date.now(),
        },
      };
      expect(
        getters.getUnreadTextMessages(state, { getUnreadMessageCount: 0 })
      ).toEqual([]);
    });

    it('only unread text messages from agent if there are messages and last seen is before messages created-at', () => {
      const state = {
        conversations: {
          1: {
            id: 1,
            content: 'Thanks for the help',
            created_at: 1574075964,
            message_type: 1,
          },
          2: {
            id: 2,
            content: 'Yes, It makes sense',
            created_at: 1574092218,
            message_type: 0,
          },
        },
      };
      expect(
        getters.getUnreadTextMessages(state, { getUnreadMessageCount: 1 })
      ).toEqual([
        {
          id: 1,
          content: 'Thanks for the help',
          created_at: 1574075964,
          message_type: 1,
        },
      ]);
    });

    it('unread messages omitting seen messages ', () => {
      const state = {
        conversations: {
          1: {
            id: 1,
            content: 'Thanks for the help',
            created_at: 1574075964,
            message_type: 1,
          },
          2: {
            id: 2,
            content: 'Yes, It makes sense',
            created_at: 1674075965,
            message_type: 1,
          },
          3: {
            id: 3,
            content: 'Yes, It makes sense',
            created_at: 1574092218,
            message_type: 0,
          },
        },
        meta: {
          userLastSeenAt: 1674075964,
        },
      };
      expect(
        getters.getUnreadTextMessages(state, { getUnreadMessageCount: 1 })
      ).toEqual([
        {
          id: 2,
          content: 'Yes, It makes sense',
          created_at: 1674075965,
          message_type: 1,
        },
      ]);
    });
  });

  it('getMessageCount', () => {
    const state = {
      conversations: {
        1: {
          content: 'hey, how are you?',
        },
      },
    };
    expect(getters.getMessageCount(state)).toEqual(1);
  });

  it('getLastMessage', () => {
    const state = {
      conversations: {
        1: {
          id: 1,
          content: 'Thanks for the help',
          created_at: 1574075964,
          message_type: 1,
        },
        2: {
          id: 2,
          content: 'Yes, It makes sense',
          created_at: 1574092218,
          message_type: 1,
        },
        3: {
          id: 3,
          content: 'Yes, It makes sense',
          created_at: 1574092218,
          message_type: 0,
        },
      },
      meta: {
        userLastSeenAt: 1674075964,
      },
    };
    expect(getters.getLastMessage(state).id).toEqual(3);
  });

  describe('when ids do not follow created_at', () => {
    // A message whose created_at is older than a message with a lower id: the store is
    // keyed by id, so Object.values iterates by id and not by time.
    const today = 1794614400; // 2026-11-14 00:00 UTC
    const april = 1776808080; // 2026-04-21 21:48 UTC
    const state = {
      conversations: {
        10: { id: 10, content: 'today, first', created_at: today + 3600 },
        11: { id: 11, content: 'today, second', created_at: today + 7200 },
        12: { id: 12, content: 'april', created_at: april },
        13: { id: 13, content: 'today, between', created_at: today + 5400 },
      },
      meta: { userLastSeenAt: 0 },
    };

    it('getGroupedConversation puts the older day first and orders messages by time', () => {
      const groups = getters.getGroupedConversation(state);
      expect(groups.map(group => group.messages.map(m => m.id))).toEqual([
        [12],
        [10, 13, 11],
      ]);
    });

    it('getEarliestMessage is the earliest in time, the cursor the API pages back from', () => {
      expect(getters.getEarliestMessage(state).id).toEqual(12);
    });

    it('getLastMessage is the latest in time', () => {
      expect(getters.getLastMessage(state).id).toEqual(11);
    });

    it('getEarliestMessage skips a temporary message, whose uuid is no cursor', () => {
      const pending = {
        conversations: {
          40: { id: 40, created_at: today },
          'b7c1e2f0-temp': { id: 'b7c1e2f0-temp', created_at: today - 60 },
        },
      };
      expect(getters.getEarliestMessage(pending).id).toEqual(40);
    });

    it('keeps a message being sent after stored replies when the visitor clock is behind', () => {
      const behind = {
        conversations: {
          50: { id: 50, created_at: today + 600, content: 'agent reply' },
          'c4d2-temp': {
            id: 'c4d2-temp',
            created_at: today,
            content: 'just sent',
          },
        },
      };
      expect(getters.getLastMessage(behind).id).toEqual('c4d2-temp');
      const [group] = getters.getGroupedConversation(behind);
      expect(group.messages.map(m => m.id)).toEqual([50, 'c4d2-temp']);
    });

    it('breaks a created_at tie by id', () => {
      const tied = {
        conversations: {
          21: { id: 21, created_at: today },
          20: { id: 20, created_at: today },
        },
      };
      expect(getters.getEarliestMessage(tied).id).toEqual(20);
      expect(getters.getLastMessage(tied).id).toEqual(21);
    });

    it('getUnreadTextMessages keeps the latest agent messages in time', () => {
      const outgoing = {
        conversations: {
          30: { id: 30, message_type: 1, created_at: today + 300 },
          31: { id: 31, message_type: 1, created_at: today + 400 },
          32: { id: 32, message_type: 1, created_at: april },
        },
        meta: { userLastSeenAt: 0 },
      };
      const unread = getters.getUnreadTextMessages(outgoing, {
        getUnreadMessageCount: 2,
      });
      expect(unread.map(m => m.id)).toEqual([30, 31]);
    });
  });
});
