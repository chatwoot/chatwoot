import types from '../../../mutation-types';
import { mutations } from '../../conversations';

describe('#mutations', () => {
  describe('#EMPTY_ALL_CONVERSATION', () => {
    it('empty conversations', () => {
      const state = { allConversations: [{ id: 1 }], selectedChatId: 1 };
      mutations[types.EMPTY_ALL_CONVERSATION](state);
      expect(state.allConversations).toEqual([]);
      expect(state.selectedChatId).toEqual(null);
    });
  });

  describe('#UPDATE_MESSAGE_UNREAD_COUNT', () => {
    it('mark conversation as read', () => {
      const state = { allConversations: [{ id: 1 }] };
      const lastSeen = new Date().getTime() / 1000;
      mutations[types.UPDATE_MESSAGE_UNREAD_COUNT](state, { id: 1, lastSeen });
      expect(state.allConversations).toEqual([
        { id: 1, agent_last_seen_at: lastSeen, unread_count: 0 },
      ]);
    });

    it('doesnot send any mutation if chat doesnot exist', () => {
      const state = { allConversations: [] };
      const lastSeen = new Date().getTime() / 1000;
      mutations[types.UPDATE_MESSAGE_UNREAD_COUNT](state, { id: 1, lastSeen });
      expect(state.allConversations).toEqual([]);
    });
  });

  describe('#CLEAR_CURRENT_CHAT_WINDOW', () => {
    it('clears current chat window', () => {
      const state = { selectedChatId: 1 };
      mutations[types.CLEAR_CURRENT_CHAT_WINDOW](state);
      expect(state.selectedChatId).toEqual(null);
    });
  });

  describe('#ASSIGN_TEAM', () => {
    it('clears current chat window', () => {
      const state = { allConversations: [{ id: 1, meta: {} }] };
      mutations[types.UPDATE_CONVERSATION_LAST_ACTIVITY](state, {
        lastActivityAt: 1602256198,
        conversationId: 1,
      });

      expect(state.allConversations).toEqual([
        { id: 1, meta: {}, last_activity_at: 1602256198 },
      ]);
    });
  });
  describe('#UPDATE_CONVERSATION_LAST_ACTIVITY', () => {
    it('update conversation last activity', () => {
      const state = { allConversations: [{ id: 1, meta: {} }] };
      mutations[types.ASSIGN_TEAM](state, {
        team: { id: 1, name: 'Team 1' },
        conversationId: 1,
      });
      expect(state.allConversations).toEqual([
        { id: 1, meta: { team: { id: 1, name: 'Team 1' } } },
      ]);
    });
  });

  describe('#CHANGE_CHAT_SORT_FILTER', () => {
    it('update conversation sort filter', () => {
      const state = { chatSortFilter: 'latest' };
      mutations[types.CHANGE_CHAT_SORT_FILTER](state, {
        data: 'sort_on_created_at',
      });
      expect(state.chatSortFilter).toEqual({ data: 'sort_on_created_at' });
    });
  });

  describe('#SET_CURRENT_CHAT_WINDOW', () => {
    it('set current chat window', () => {
      const state = { selectedChatId: 1 };
      mutations[types.SET_CURRENT_CHAT_WINDOW](state, { id: 2 });
      expect(state.selectedChatId).toEqual(2);
    });

    it('does not set current chat window', () => {
      const state = { selectedChatId: 1 };
      mutations[types.SET_CURRENT_CHAT_WINDOW](state);
      expect(state.selectedChatId).toEqual(1);
    });
  });

  describe('#SET_CONVERSATION_CAN_REPLY', () => {
    it('set canReply flag', () => {
      const state = { allConversations: [{ id: 1, can_reply: false }] };
      mutations[types.SET_CONVERSATION_CAN_REPLY](state, {
        conversationId: 1,
        canReply: true,
      });
      expect(state.allConversations[0].can_reply).toEqual(true);
    });
  });

  describe('#ADD_MESSAGE', () => {
    it('does not add message to the store if conversation does not exist', () => {
      const state = { allConversations: [] };
      mutations[types.ADD_MESSAGE](state, { conversationId: 1 });
      expect(state.allConversations).toEqual([]);
    });

    it('add message to the conversation if it does not exist in the store', () => {
      global.bus = { $emit: jest.fn() };
      const state = {
        allConversations: [{ id: 1, messages: [] }],
        selectedChatId: -1,
      };
      mutations[types.ADD_MESSAGE](state, {
        conversation_id: 1,
        content: 'Test message',
        created_at: 1602256198,
      });
      expect(state.allConversations).toEqual([
        {
          id: 1,
          messages: [
            {
              conversation_id: 1,
              content: 'Test message',
              created_at: 1602256198,
            },
          ],
          unread_count: 0,
          timestamp: 1602256198,
        },
      ]);
      expect(global.bus.$emit).not.toHaveBeenCalled();
    });

    it('add message to the conversation and emit scrollToMessage if it does not exist in the store', () => {
      global.bus = { $emit: jest.fn() };
      const state = {
        allConversations: [{ id: 1, messages: [] }],
        selectedChatId: 1,
      };
      mutations[types.ADD_MESSAGE](state, {
        conversation_id: 1,
        content: 'Test message',
        created_at: 1602256198,
      });
      expect(state.allConversations).toEqual([
        {
          id: 1,
          messages: [
            {
              conversation_id: 1,
              content: 'Test message',
              created_at: 1602256198,
            },
          ],
          unread_count: 0,
          timestamp: 1602256198,
        },
      ]);
      expect(global.bus.$emit).toHaveBeenCalledWith('SCROLL_TO_MESSAGE');
    });

    it('update message if it exist in the store', () => {
      global.bus = { $emit: jest.fn() };
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                conversation_id: 1,
                content: 'Test message',
                created_at: 1602256198,
              },
            ],
          },
        ],
        selectedChatId: 1,
      };
      mutations[types.ADD_MESSAGE](state, {
        conversation_id: 1,
        content: 'Test message 1',
        created_at: 1602256198,
      });
      expect(state.allConversations).toEqual([
        {
          id: 1,
          messages: [
            {
              conversation_id: 1,
              content: 'Test message 1',
              created_at: 1602256198,
            },
          ],
        },
      ]);
      expect(global.bus.$emit).not.toHaveBeenCalled();
    });
  });

  describe('#CHANGE_CONVERSATION_STATUS', () => {
    it('updates the conversation status correctly', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [],
            status: 'open',
          },
        ],
      };

      mutations[types.CHANGE_CONVERSATION_STATUS](state, {
        conversationId: '1',
        status: 'resolved',
      });

      expect(state.allConversations).toEqual([
        {
          id: 1,
          messages: [],
          status: 'resolved',
        },
      ]);
    });

    describe('#UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES', () => {
      it('update conversation custom attributes', () => {
        const custom_attributes = { order_id: 1001 };
        const state = { allConversations: [{ id: 1 }], selectedChatId: 1 };
        mutations[types.UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES](state, {
          conversationId: 1,
          custom_attributes,
        });
        expect(
          state.allConversations[0].custom_attributes.custom_attributes
        ).toEqual(custom_attributes);
      });
    });
  });

  describe('#SET_CONVERSATION_FILTERS', () => {
    it('set conversation filter', () => {
      const appliedFilters = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'snoozed', name: 'Snoozed' }],
          query_operator: 'and',
        },
      ];
      mutations[types.SET_CONVERSATION_FILTERS](appliedFilters);
      expect(appliedFilters).toEqual([
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'snoozed', name: 'Snoozed' }],
          query_operator: 'and',
        },
      ]);
    });
  });

  describe('#CLEAR_CONVERSATION_FILTERS', () => {
    it('clears applied conversation filters', () => {
      const state = {
        appliedFilters: [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: [{ id: 'snoozed', name: 'Snoozed' }],
            query_operator: 'and',
          },
        ],
      };
      mutations[types.CLEAR_CONVERSATION_FILTERS](state);
      expect(state.appliedFilters).toEqual([]);
    });
  });

  describe('#SET_ALL_ATTACHMENTS', () => {
    it('set all attachments', () => {
      const state = {
        allConversations: [{ id: 1 }],
      };
      const data = [{ id: 1, name: 'test' }];
      mutations[types.SET_ALL_ATTACHMENTS](state, { id: 1, data });
      expect(state.allConversations[0].attachments).toEqual(data);
    });
    it('set attachments key even if the attachments are empty', () => {
      const state = {
        allConversations: [{ id: 1 }],
      };
      const data = [];
      mutations[types.SET_ALL_ATTACHMENTS](state, { id: 1, data });
      expect(state.allConversations[0].attachments).toEqual([]);
    });
  });

  describe('#ADD_CONVERSATION_ATTACHMENTS', () => {
    it('add conversation attachments', () => {
      const state = {
        allConversations: [{ id: 1, attachments: [] }],
      };
      const message = {
        conversation_id: 1,
        status: 'sent',
        attachments: [{ id: 1, name: 'test' }],
      };

      mutations[types.ADD_CONVERSATION_ATTACHMENTS](state, message);
      expect(state.allConversations[0].attachments).toEqual(
        message.attachments
      );
    });

    it('should not add duplicate attachments', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            attachments: [{ id: 1, name: 'existing' }],
          },
        ],
      };
      const message = {
        conversation_id: 1,
        status: 'sent',
        attachments: [
          { id: 1, name: 'existing' },
          { id: 2, name: 'new' },
        ],
      };

      mutations[types.ADD_CONVERSATION_ATTACHMENTS](state, message);
      expect(state.allConversations[0].attachments).toHaveLength(2);
      expect(state.allConversations[0].attachments).toContainEqual({
        id: 1,
        name: 'existing',
      });
      expect(state.allConversations[0].attachments).toContainEqual({
        id: 2,
        name: 'new',
      });
    });

    it('should not add attachments if chat not found', () => {
      const state = {
        allConversations: [{ id: 1, attachments: [] }],
      };
      const message = {
        conversation_id: 2,
        status: 'sent',
        attachments: [{ id: 1, name: 'test' }],
      };

      mutations[types.ADD_CONVERSATION_ATTACHMENTS](state, message);
      expect(state.allConversations[0].attachments).toHaveLength(0);
    });
  });

  describe('#DELETE_CONVERSATION_ATTACHMENTS', () => {
    it('delete conversation attachments', () => {
      const state = {
        allConversations: [{ id: 1, attachments: [{ id: 1, message_id: 1 }] }],
      };
      const message = {
        conversation_id: 1,
        status: 'sent',
        id: 1,
      };

      mutations[types.DELETE_CONVERSATION_ATTACHMENTS](state, message);
      expect(state.allConversations[0].attachments).toHaveLength(0);
    });

    it('should not delete attachments for non-matching message id', () => {
      const state = {
        allConversations: [{ id: 1, attachments: [{ id: 1, message_id: 1 }] }],
      };
      const message = {
        conversation_id: 1,
        status: 'sent',
        id: 2,
      };

      mutations[types.DELETE_CONVERSATION_ATTACHMENTS](state, message);
      expect(state.allConversations[0].attachments).toHaveLength(1);
    });

    it('should not delete attachments if chat not found', () => {
      const state = {
        allConversations: [{ id: 1, attachments: [{ id: 1, message_id: 1 }] }],
      };
      const message = {
        conversation_id: 2,
        status: 'sent',
        id: 1,
      };

      mutations[types.DELETE_CONVERSATION_ATTACHMENTS](state, message);
      expect(state.allConversations[0].attachments).toHaveLength(1);
    });
  });
});
