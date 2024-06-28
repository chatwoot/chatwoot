import commonHelpers from '../../../../helper/commons';
import getters from '../../conversations/getters';
/*
  Order of conversations in the fixture is as follows:
  - lastActivity: c0 < c3 < c2 < c1
  - createdAt: c3 < c2 < c1 < c0
  - priority: c1 < c2 < c0 < c3
  - waitingSince: c1 > c3 > c0 < c2
*/
import conversations from './conversations.fixtures';

// loads .last() helper
commonHelpers();

describe('#getters', () => {
  describe('#getAllConversations', () => {
    it('returns conversations ordered by lastActivityAt in descending order if no sort order is available', () => {
      const state = { allConversations: [...conversations] };
      expect(getters.getAllConversations(state)).toEqual([
        conversations[1],
        conversations[2],
        conversations[3],
        conversations[0],
      ]);
    });

    it('returns conversations ordered by lastActivityAt in descending order if invalid sort order is available', () => {
      const state = {
        allConversations: [...conversations],
        chatSortFilter: 'latest',
      };
      expect(getters.getAllConversations(state)).toEqual([
        conversations[1],
        conversations[2],
        conversations[3],
        conversations[0],
      ]);
    });

    it('returns conversations ordered by lastActivityAt in descending order if chatStatusFilter = last_activity_at_desc', () => {
      const state = {
        allConversations: [...conversations],
        chatSortFilter: 'last_activity_at_desc',
      };
      expect(getters.getAllConversations(state)).toEqual([
        conversations[1],
        conversations[2],
        conversations[3],
        conversations[0],
      ]);
    });

    it('returns conversations ordered by lastActivityAt in ascending order if chatStatusFilter = last_activity_at_asc', () => {
      const state = {
        allConversations: [...conversations],
        chatSortFilter: 'last_activity_at_asc',
      };
      expect(getters.getAllConversations(state)).toEqual([
        conversations[0],
        conversations[3],
        conversations[2],
        conversations[1],
      ]);
    });

    it('returns conversations ordered by createdAt in descending order if chatStatusFilter = created_at_desc', () => {
      const state = {
        allConversations: [...conversations],
        chatSortFilter: 'created_at_desc',
      };
      expect(getters.getAllConversations(state)).toEqual([
        conversations[0],
        conversations[1],
        conversations[2],
        conversations[3],
      ]);
    });

    it('returns conversations ordered by createdAt in ascending order if chatStatusFilter = created_at_asc', () => {
      const state = {
        allConversations: [...conversations],
        chatSortFilter: 'created_at_asc',
      };
      expect(getters.getAllConversations(state)).toEqual([
        conversations[3],
        conversations[2],
        conversations[1],
        conversations[0],
      ]);
    });

    it('returns conversations ordered by priority in descending order if chatStatusFilter = priority_desc', () => {
      const state = {
        allConversations: [...conversations],
        chatSortFilter: 'priority_desc',
      };
      expect(getters.getAllConversations(state)).toEqual([
        conversations[3],
        conversations[0],
        conversations[1],
        conversations[2],
      ]);
    });

    it('returns conversations ordered by priority in ascending order if chatStatusFilter = priority_asc', () => {
      const state = {
        allConversations: [...conversations],
        chatSortFilter: 'priority_asc',
      };
      expect(getters.getAllConversations(state)).toEqual([
        conversations[1],
        conversations[2],
        conversations[0],
        conversations[3],
      ]);
    });

    it('returns conversations ordered by longest waiting if chatStatusFilter = waiting_since_asc', () => {
      const state = {
        allConversations: [...conversations],
        chatSortFilter: 'waiting_since_asc',
      };
      expect(getters.getAllConversations(state)).toEqual([
        conversations[1],
        conversations[3],
        conversations[2],
        conversations[0],
      ]);
    });
  });
  describe('#getUnAssignedChats', () => {
    it('order returns only chats assigned to user', () => {
      const conversationList = [
        {
          id: 1,
          inbox_id: 2,
          status: 1,
          meta: { assignee: { id: 1 } },
          labels: ['sales', 'dev'],
        },
        {
          id: 2,
          inbox_id: 2,
          status: 1,
          meta: {},
          labels: ['dev'],
        },
        {
          id: 11,
          inbox_id: 3,
          status: 1,
          meta: { assignee: { id: 1 } },
          labels: [],
        },
        {
          id: 22,
          inbox_id: 4,
          status: 1,
          meta: { team: { id: 5 } },
          labels: ['sales'],
        },
      ];

      expect(
        getters.getUnAssignedChats({ allConversations: conversationList })({
          status: 1,
        })
      ).toEqual([
        {
          id: 2,
          inbox_id: 2,
          status: 1,
          meta: {},
          labels: ['dev'],
        },
        {
          id: 22,
          inbox_id: 4,
          status: 1,
          meta: { team: { id: 5 } },
          labels: ['sales'],
        },
      ]);
    });
  });
  describe('#getConversationById', () => {
    it('get conversations based on id', () => {
      const state = {
        allConversations: [
          {
            id: 1,
          },
        ],
      };
      expect(getters.getConversationById(state)(1)).toEqual({ id: 1 });
    });
  });

  describe('#getAppliedConversationFilters', () => {
    it('getAppliedConversationFilters', () => {
      const filtersList = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'snoozed', name: 'Snoozed' }],
          query_operator: 'and',
        },
      ];
      const state = {
        appliedFilters: filtersList,
      };
      expect(getters.getAppliedConversationFilters(state)).toEqual(filtersList);
    });
  });

  describe('#getLastEmailInSelectedChat', () => {
    it('Returns cc in last email', () => {
      const state = {};
      const getSelectedChat = {
        messages: [
          {
            message_type: 1,
            content_attributes: {
              email: {
                from: 'why@how.my',
                cc: ['nithin@me.co', 'we@who.why'],
              },
            },
          },
        ],
      };
      expect(
        getters.getLastEmailInSelectedChat(state, { getSelectedChat })
      ).toEqual({
        message_type: 1,
        content_attributes: {
          email: {
            from: 'why@how.my',
            cc: ['nithin@me.co', 'we@who.why'],
          },
        },
      });
    });
  });

  describe('#getSelectedChatAttachments', () => {
    it('Returns attachments in selected chat', () => {
      const state = {};
      const getSelectedChat = {
        attachments: [
          {
            id: 1,
            file_name: 'test1',
          },
          {
            id: 2,
            file_name: 'test2',
          },
        ],
      };
      expect(
        getters.getSelectedChatAttachments(state, { getSelectedChat })
      ).toEqual([
        {
          id: 1,
          file_name: 'test1',
        },
        {
          id: 2,
          file_name: 'test2',
        },
      ]);
    });
  });

  describe('#getContextMenuChatId', () => {
    it('returns the context menu chat id', () => {
      const state = { contextMenuChatId: 1 };
      expect(getters.getContextMenuChatId(state)).toEqual(1);
    });
  });

  describe('#getChatListFilters', () => {
    it('get chat list filters', () => {
      const conversationFilters = {
        inboxId: 1,
        assigneeType: 'me',
        status: 'open',
        sortBy: 'created_at',
        page: 1,
        labels: ['label'],
        teamId: 1,
        conversationType: 'mention',
      };
      const state = { conversationFilters: conversationFilters };
      expect(getters.getChatListFilters(state)).toEqual(conversationFilters);
    });
  });

  describe('#getAppliedConversationFiltersQuery', () => {
    it('get applied conversation filters query', () => {
      const filtersList = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'snoozed', name: 'Snoozed' }],
          query_operator: 'and',
        },
      ];
      const state = { appliedFilters: filtersList };
      expect(getters.getAppliedConversationFiltersQuery(state)).toEqual({
        payload: [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            query_operator: undefined,
            values: ['snoozed'],
          },
        ],
      });
    });
  });
});
