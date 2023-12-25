import commonHelpers from '../../../../helper/commons';
import getters from '../../conversations/getters';

// loads .last() helper
commonHelpers();

describe('#getters', () => {
  describe('#getAllConversations', () => {
    it('order conversations based on last activity', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                content: 'test1',
              },
            ],
            created_at: 2466424490,
            last_activity_at: 2466424490,
          },
          {
            id: 2,
            messages: [{ content: 'test2' }],
            created_at: 1466424480,
            last_activity_at: 1466424480,
          },
        ],
      };

      expect(getters.getAllConversations(state)).toEqual([
        {
          id: 1,
          messages: [
            {
              content: 'test1',
            },
          ],
          created_at: 2466424490,
          last_activity_at: 2466424490,
        },
        {
          id: 2,
          messages: [{ content: 'test2' }],
          created_at: 1466424480,
          last_activity_at: 1466424480,
        },
      ]);
    });
    it('order conversations based on last activity with ascending order', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                content: 'test1',
              },
            ],
            created_at: 2466424490,
            last_activity_at: 2466424490,
          },
          {
            id: 2,
            messages: [{ content: 'test2' }],
            created_at: 1466424480,
            last_activity_at: 1466424480,
          },
        ],
        chatSortFilter: 'latest_last',
      };

      expect(getters.getAllConversations(state)).toEqual([
        {
          id: 2,
          messages: [{ content: 'test2' }],
          created_at: 1466424480,
          last_activity_at: 1466424480,
        },
        {
          id: 1,
          messages: [
            {
              content: 'test1',
            },
          ],
          created_at: 2466424490,
          last_activity_at: 2466424490,
        },
      ]);
    });

    it('order conversations based on created at', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                content: 'test1',
              },
            ],
            created_at: 1683645801, // Tuesday, 9 May 2023
            last_activity_at: 2466424490,
          },
          {
            id: 2,
            messages: [{ content: 'test2' }],
            created_at: 1652109801, // Monday, 9 May 2022
            last_activity_at: 1466424480,
          },
        ],
        chatSortFilter: 'created_at_last',
      };

      expect(getters.getAllConversations(state)).toEqual([
        {
          id: 2,
          messages: [{ content: 'test2' }],
          created_at: 1652109801,
          last_activity_at: 1466424480,
        },
        {
          id: 1,
          messages: [
            {
              content: 'test1',
            },
          ],
          created_at: 1683645801,
          last_activity_at: 2466424490,
        },
      ]);
    });

    it('order conversations based on created at with descending order', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                content: 'test1',
              },
            ],
            created_at: 1683645801, // Tuesday, 9 May 2023
            last_activity_at: 2466424490,
          },
          {
            id: 2,
            messages: [{ content: 'test2' }],
            created_at: 1652109801, // Monday, 9 May 2022
            last_activity_at: 1466424480,
          },
        ],
        chatSortFilter: 'created_at_first',
      };

      expect(getters.getAllConversations(state)).toEqual([
        {
          id: 1,
          messages: [
            {
              content: 'test1',
            },
          ],
          created_at: 1683645801,
          last_activity_at: 2466424490,
        },
        {
          id: 2,
          messages: [{ content: 'test2' }],
          created_at: 1652109801,
          last_activity_at: 1466424480,
        },
      ]);
    });

    it('order conversations based on default order', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                content: 'test1',
              },
            ],
            created_at: 2466424490,
            last_activity_at: 2466424490,
          },
          {
            id: 2,
            messages: [{ content: 'test2' }],
            created_at: 1466424480,
            last_activity_at: 1466424480,
          },
        ],
      };

      expect(getters.getAllConversations(state)).toEqual([
        {
          id: 1,
          messages: [
            {
              content: 'test1',
            },
          ],
          created_at: 2466424490,
          last_activity_at: 2466424490,
        },
        {
          id: 2,
          messages: [{ content: 'test2' }],
          created_at: 1466424480,
          last_activity_at: 1466424480,
        },
      ]);
    });
    it('order conversations based on priority', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                content: 'test1',
              },
            ],
            priority: 'low',
            created_at: 1683645801,
            last_activity_at: 2466424490,
          },
          {
            id: 2,
            messages: [{ content: 'test2' }],
            priority: 'urgent',
            created_at: 1652109801,
            last_activity_at: 1466424480,
          },
          {
            id: 3,
            messages: [{ content: 'test3' }],
            priority: 'medium',
            created_at: 1652109801,
            last_activity_at: 1466421280,
          },
        ],
        chatSortFilter: 'priority_first',
      };

      expect(getters.getAllConversations(state)).toEqual([
        {
          id: 2,
          messages: [{ content: 'test2' }],
          priority: 'urgent',
          created_at: 1652109801,
          last_activity_at: 1466424480,
        },
        {
          id: 3,
          messages: [{ content: 'test3' }],
          priority: 'medium',
          created_at: 1652109801,
          last_activity_at: 1466421280,
        },
        {
          id: 1,
          messages: [
            {
              content: 'test1',
            },
          ],
          priority: 'low',
          created_at: 1683645801,
          last_activity_at: 2466424490,
        },
      ]);
    });

    it('order conversations based on  with descending order', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                content: 'test1',
              },
            ],
            priority: 'low',
            created_at: 1683645801,
            last_activity_at: 2466424490,
          },
          {
            id: 2,
            messages: [{ content: 'test2' }],
            priority: 'urgent',
            created_at: 1652109801,
            last_activity_at: 1466424480,
          },
          {
            id: 3,
            messages: [{ content: 'test3' }],
            priority: 'medium',
            created_at: 1652109801,
            last_activity_at: 1466421280,
          },
        ],
        chatSortFilter: 'priority_last',
      };

      expect(getters.getAllConversations(state)).toEqual([
        {
          id: 1,
          messages: [
            {
              content: 'test1',
            },
          ],
          priority: 'low',
          created_at: 1683645801,
          last_activity_at: 2466424490,
        },
        {
          id: 3,
          messages: [{ content: 'test3' }],
          priority: 'medium',
          created_at: 1652109801,
          last_activity_at: 1466421280,
        },
        {
          id: 2,
          messages: [{ content: 'test2' }],
          priority: 'urgent',
          created_at: 1652109801,
          last_activity_at: 1466424480,
        },
      ]);
    });

    it('order conversations based on waiting_since', () => {
      const state = {
        allConversations: [
          {
            id: 3,
            created_at: 1683645800,
            waiting_since: 0,
          },
          {
            id: 4,
            created_at: 1683645799,
            waiting_since: 0,
          },
          {
            id: 1,
            created_at: 1683645801,
            waiting_since: 1683645802,
          },
          {
            id: 2,
            created_at: 1683645803,
            waiting_since: 1683645800,
          },
        ],
        chatSortFilter: 'waiting_since_last',
      };

      expect(getters.getAllConversations(state)).toEqual([
        {
          id: 2,
          created_at: 1683645803,
          waiting_since: 1683645800,
        },
        {
          id: 1,
          created_at: 1683645801,
          waiting_since: 1683645802,
        },
        {
          id: 4,
          created_at: 1683645799,
          waiting_since: 0,
        },
        {
          id: 3,
          created_at: 1683645800,
          waiting_since: 0,
        },
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
});
