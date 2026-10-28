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

    it('uses latest activity to order conversations with the same priority', () => {
      const state = {
        allConversations: [conversations[2], conversations[1]],
        chatSortFilter: 'priority_desc',
      };

      expect(getters.getAllConversations(state)).toEqual([
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

    it('returns waiting conversations before non-waiting conversations when sorting by shortest wait', () => {
      const state = {
        allConversations: [...conversations],
        chatSortFilter: 'waiting_since_desc',
      };
      expect(getters.getAllConversations(state)).toEqual([
        conversations[3],
        conversations[1],
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
  describe('#getParticipatingChats', () => {
    const conversationList = [
      { id: 1, inbox_id: 2, status: 1, meta: { assignee: { id: 1 } } },
      { id: 2, inbox_id: 2, status: 1, meta: {} },
      { id: 3, inbox_id: 3, status: 1, meta: { assignee: { id: 2 } } },
    ];

    it('returns all conversations when watchers are not loaded', () => {
      const state = {
        allConversations: conversationList,
        participatingConversationIds: {},
      };
      const rootGetters = {
        getCurrentUser: { id: 1 },
        'conversationWatchers/getByConversationId': () => undefined,
      };
      const result = getters.getParticipatingChats(
        state,
        {},
        {},
        rootGetters
      )({ status: 1 });
      expect(result).toEqual(conversationList);
    });

    it('filters out conversation when watchers loaded and user not participating', () => {
      const state = {
        allConversations: conversationList,
        participatingConversationIds: {},
      };
      const rootGetters = {
        getCurrentUser: { id: 1 },
        'conversationWatchers/getByConversationId': id => {
          if (id === 2) return [{ id: 3 }];
          return undefined;
        },
      };
      const result = getters.getParticipatingChats(
        state,
        {},
        {},
        rootGetters
      )({ status: 1 });
      expect(result).toEqual([conversationList[0], conversationList[2]]);
    });

    it('keeps conversation when watchers loaded and user is participating', () => {
      const state = {
        allConversations: conversationList,
        participatingConversationIds: {},
      };
      const rootGetters = {
        getCurrentUser: { id: 1 },
        'conversationWatchers/getByConversationId': id => {
          if (id === 1) return [{ id: 1 }, { id: 2 }];
          return undefined;
        },
      };
      const result = getters.getParticipatingChats(
        state,
        {},
        {},
        rootGetters
      )({ status: 1 });
      expect(result).toEqual(conversationList);
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

    it('Skips forwarded emails', () => {
      const state = {};
      const incomingEmail = {
        message_type: 0,
        content_attributes: { email: { from: 'why@how.my' } },
      };
      const getSelectedChat = {
        messages: [
          incomingEmail,
          {
            message_type: 1,
            content_attributes: {
              forwarded_message_id: 1,
              to_emails: ['vendor@example.com'],
            },
          },
        ],
      };
      expect(
        getters.getLastEmailInSelectedChat(state, { getSelectedChat })
      ).toEqual(incomingEmail);
    });
  });

  describe('#getSelectedChatAttachments', () => {
    it('Returns attachments in selected chat', () => {
      const attachments = {
        1: [
          { id: 1, file_name: 'test1' },
          { id: 2, file_name: 'test2' },
        ],
      };
      const selectedChatId = 1;
      expect(
        getters.getSelectedChatAttachments({ selectedChatId, attachments })
      ).toEqual([
        { id: 1, file_name: 'test1' },
        { id: 2, file_name: 'test2' },
      ]);
    });
  });

  describe('#getSelectedChatAttachmentsLoaded', () => {
    it('returns true when attachments have been fetched for the selected chat', () => {
      const state = { selectedChatId: 1, attachments: { 1: [] } };
      expect(getters.getSelectedChatAttachmentsLoaded(state)).toBe(true);
    });

    it('returns true when the fetched attachment list is non-empty', () => {
      const state = {
        selectedChatId: 1,
        attachments: { 1: [{ id: 1, file_name: 'test' }] },
      };
      expect(getters.getSelectedChatAttachmentsLoaded(state)).toBe(true);
    });

    it('returns false when attachments have not been fetched yet', () => {
      const state = { selectedChatId: 1, attachments: {} };
      expect(getters.getSelectedChatAttachmentsLoaded(state)).toBe(false);
    });

    it('returns false when no chat is selected', () => {
      const state = { selectedChatId: null, attachments: {} };
      expect(getters.getSelectedChatAttachmentsLoaded(state)).toBe(false);
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

  describe('#getCopilotAssistant', () => {
    it('get copilot assistant', () => {
      const state = {
        copilotAssistant: {
          id: 1,
          name: 'Assistant',
          description: 'Assistant description',
        },
      };
      expect(getters.getCopilotAssistant(state)).toEqual({
        id: 1,
        name: 'Assistant',
        description: 'Assistant description',
      });
    });
  });

  describe('#getFilteredConversations', () => {
    const mockConversations = [
      {
        id: 1,
        status: 'open',
        meta: { assignee: { id: 1 } },
        last_activity_at: 1000,
      },
      {
        id: 2,
        status: 'open',
        meta: {},
        last_activity_at: 2000,
      },
      {
        id: 3,
        status: 'resolved',
        meta: { assignee: { id: 2 } },
        last_activity_at: 3000,
      },
    ];

    const mockRootGetters = {
      getCurrentUser: {
        id: 1,
        accounts: [{ id: 1, role: 'agent', permissions: [] }],
      },
      getCurrentAccountId: 1,
    };

    it('filters conversations based on role permissions for administrator', () => {
      const state = {
        allConversations: mockConversations,
        chatSortFilter: 'last_activity_at_desc',
        appliedFilters: [],
      };

      const rootGetters = {
        ...mockRootGetters,
        getCurrentUser: {
          ...mockRootGetters.getCurrentUser,
          accounts: [{ id: 1, role: 'administrator', permissions: [] }],
        },
      };

      const result = getters.getFilteredConversations(
        state,
        {},
        {},
        rootGetters
      );

      expect(result).toEqual([
        mockConversations[2],
        mockConversations[1],
        mockConversations[0],
      ]);
    });

    it('filters conversations based on role permissions for agent', () => {
      const state = {
        allConversations: mockConversations,
        chatSortFilter: 'last_activity_at_desc',
        appliedFilters: [],
      };

      const rootGetters = {
        ...mockRootGetters,
        getCurrentUser: {
          ...mockRootGetters.getCurrentUser,
          accounts: [{ id: 1, role: 'agent', permissions: [] }],
        },
      };

      const result = getters.getFilteredConversations(
        state,
        {},
        {},
        rootGetters
      );

      expect(result).toEqual([
        mockConversations[2],
        mockConversations[1],
        mockConversations[0],
      ]);
    });

    it('filters conversations for custom role with conversation_manage permission', () => {
      const state = {
        allConversations: mockConversations,
        chatSortFilter: 'last_activity_at_desc',
        appliedFilters: [],
      };

      const rootGetters = {
        ...mockRootGetters,
        getCurrentUser: {
          ...mockRootGetters.getCurrentUser,
          accounts: [
            {
              id: 1,
              custom_role_id: 5,
              permissions: ['conversation_manage'],
            },
          ],
        },
      };

      const result = getters.getFilteredConversations(
        state,
        {},
        {},
        rootGetters
      );

      expect(result).toEqual([
        mockConversations[2],
        mockConversations[1],
        mockConversations[0],
      ]);
    });

    it('filters conversations for custom role with conversation_unassigned_manage permission', () => {
      const state = {
        allConversations: mockConversations,
        chatSortFilter: 'last_activity_at_desc',
        appliedFilters: [],
      };

      const rootGetters = {
        ...mockRootGetters,
        getCurrentUser: {
          ...mockRootGetters.getCurrentUser,
          accounts: [
            {
              id: 1,
              custom_role_id: 5,
              permissions: ['conversation_unassigned_manage'],
            },
          ],
        },
      };

      const result = getters.getFilteredConversations(
        state,
        {},
        {},
        rootGetters
      );

      // Should include conversation assigned to user (id: 1) and unassigned conversation
      expect(result).toEqual([mockConversations[1], mockConversations[0]]);
    });

    it('filters conversations for custom role with conversation_participating_manage permission', () => {
      const state = {
        allConversations: mockConversations,
        chatSortFilter: 'last_activity_at_desc',
        appliedFilters: [],
      };

      const rootGetters = {
        ...mockRootGetters,
        getCurrentUser: {
          ...mockRootGetters.getCurrentUser,
          accounts: [
            {
              id: 1,
              custom_role_id: 5,
              permissions: ['conversation_participating_manage'],
            },
          ],
        },
      };

      const result = getters.getFilteredConversations(
        state,
        {},
        {},
        rootGetters
      );

      // Should only include conversation assigned to user (id: 1)
      expect(result).toEqual([mockConversations[0]]);
    });

    it('filters conversations for custom role with no permissions', () => {
      const state = {
        allConversations: mockConversations,
        chatSortFilter: 'last_activity_at_desc',
        appliedFilters: [],
      };

      const rootGetters = {
        ...mockRootGetters,
        getCurrentUser: {
          ...mockRootGetters.getCurrentUser,
          accounts: [
            {
              id: 1,
              custom_role_id: 5,
              permissions: [],
            },
          ],
        },
      };

      const result = getters.getFilteredConversations(
        state,
        {},
        {},
        rootGetters
      );

      // Should return empty array as user has no permissions
      expect(result).toEqual([]);
    });

    it('applies filters and role permissions together', () => {
      const state = {
        allConversations: mockConversations,
        chatSortFilter: 'last_activity_at_desc',
        appliedFilters: [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['open'],
            query_operator: 'and',
          },
        ],
      };

      const rootGetters = {
        ...mockRootGetters,
        getCurrentUser: {
          ...mockRootGetters.getCurrentUser,
          accounts: [
            {
              id: 1,
              custom_role_id: 5,
              permissions: ['conversation_participating_manage'],
            },
          ],
        },
      };

      const result = getters.getFilteredConversations(
        state,
        {},
        {},
        rootGetters
      );

      // Should only include open conversation assigned to user (id: 1)
      expect(result).toEqual([mockConversations[0]]);
    });

    it('returns empty array when no conversations match filters', () => {
      const state = {
        allConversations: mockConversations,
        chatSortFilter: 'last_activity_at_desc',
        appliedFilters: [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['pending'],
            query_operator: 'and',
          },
        ],
      };

      const result = getters.getFilteredConversations(
        state,
        {},
        {},
        mockRootGetters
      );

      expect(result).toEqual([]);
    });

    it('sorts filtered conversations according to chatSortFilter', () => {
      const state = {
        allConversations: mockConversations,
        chatSortFilter: 'last_activity_at_asc',
        appliedFilters: [],
      };

      const result = getters.getFilteredConversations(
        state,
        {},
        {},
        mockRootGetters
      );

      expect(result).toEqual([
        mockConversations[0],
        mockConversations[1],
        mockConversations[2],
      ]);
    });

    it('sorts filtered conversations by unread count and then latest activity', () => {
      const state = {
        allConversations: [
          { ...mockConversations[0], unread_count: 1 },
          { ...mockConversations[1], unread_count: 2 },
          { ...mockConversations[2], unread_count: 2 },
        ],
        chatSortFilter: 'unread',
        appliedFilters: [],
      };

      const result = getters.getFilteredConversations(
        state,
        {},
        {},
        mockRootGetters
      );

      expect(result.map(conversation => conversation.id)).toEqual([3, 2, 1]);
    });
  });

  describe('#getAppliedContactFilter', () => {
    const contactFilter = {
      attribute_key: 'contact_id',
      attribute_model: 'standard',
      filter_operator: 'equal_to',
      query_operator: 'and',
      values: [{ id: 7, name: 'Jane Doe' }],
    };

    it('returns the contact a lone contact filter scopes the list to', () => {
      expect(
        getters.getAppliedContactFilter({ appliedFilters: [contactFilter] })
      ).toEqual({ id: 7, name: 'Jane Doe' });
    });

    it('returns null when no filters are applied', () => {
      expect(
        getters.getAppliedContactFilter({ appliedFilters: [] })
      ).toBeNull();
    });

    it('returns null when the applied filter is not a contact filter', () => {
      const state = {
        appliedFilters: [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['pending'],
          },
        ],
      };

      expect(getters.getAppliedContactFilter(state)).toBeNull();
    });

    it('returns null when the contact filter is combined with another filter', () => {
      const state = {
        appliedFilters: [
          contactFilter,
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['open'],
          },
        ],
      };

      expect(getters.getAppliedContactFilter(state)).toBeNull();
    });

    it('returns null for the single select shape the filter modal builds', () => {
      const state = {
        appliedFilters: [
          { ...contactFilter, values: { id: 7, name: 'Jane Doe' } },
        ],
      };

      expect(getters.getAppliedContactFilter(state)).toBeNull();
    });
  });

  describe('#getAutoTranslate', () => {
    const rootGetters = {
      getUISettings: { locale: 'en' },
      'accounts/getAccount': () => ({
        locale: 'en',
        settings: { auto_translate: true },
      }),
      getCurrentAccountId: 1,
      'accounts/isFeatureEnabledonAccount': () => true,
      'integrations/getIntegration': () => ({}),
    };
    const chatIn = language => ({
      getSelectedChat: {
        additional_attributes: { conversation_language: language },
      },
    });

    it('is active when the contact writes another language than the agent', () => {
      expect(
        getters.getAutoTranslate({}, chatIn('fr'), {}, rootGetters)
      ).toEqual({
        enabled: true,
        provider: 'captain',
        locale: 'en',
        sameLanguage: false,
        language: 'French',
        agentLanguage: 'English',
      });
    });

    it('stays off until the account switches it on', () => {
      const notSwitchedOn = {
        ...rootGetters,
        'accounts/getAccount': () => ({ locale: 'en' }),
      };

      expect(
        getters.getAutoTranslate({}, chatIn('fr'), {}, notSwitchedOn)
      ).toMatchObject({ enabled: false, language: '' });
    });

    it('is inactive for the agent language, an unknown language or a disabled flag', () => {
      expect(
        getters.getAutoTranslate({}, chatIn('en'), {}, rootGetters)
      ).toMatchObject({ sameLanguage: true });
      expect(
        getters.getAutoTranslate({}, chatIn(undefined), {}, rootGetters)
      ).toMatchObject({ language: '' });
      expect(
        getters.getAutoTranslate(
          {},
          chatIn('fr'),
          {},
          { ...rootGetters, 'accounts/isFeatureEnabledonAccount': () => false }
        )
      ).toMatchObject({ enabled: false, language: '' });
    });
  });

  describe('#getMessageTranslationState', () => {
    const stateFor = (messages, autoTranslating = {}) =>
      getters.getMessageTranslationState(
        { autoTranslating },
        {
          getAutoTranslate: {
            enabled: true,
            locale: 'en',
            language: 'French',
            sameLanguage: false,
          },
          getSelectedChat: { messages },
        }
      );

    it('treats the text reply of a bot like a contact message', () => {
      const translationState = stateFor(
        [
          {
            id: 9,
            message_type: 1,
            content_type: 'text',
            content: 'Bonjour',
            sender: { type: 'captain_assistant' },
            content_attributes: {},
          },
        ],
        { en: { 9: true } }
      );

      expect(translationState(9).pending).toBe(true);
    });

    it('keeps a message pending until its request settles', () => {
      const translationState = stateFor(
        [
          {
            id: 1,
            message_type: 0,
            content_type: 'text',
            content: 'Bonjour',
            content_attributes: {},
          },
          {
            id: 2,
            message_type: 0,
            content_type: 'text',
            content: 'Merci',
            content_attributes: {},
          },
          {
            id: 3,
            message_type: 1,
            content_type: 'text',
            status: 'progress',
            content: 'Hi',
            content_attributes: {},
          },
          {
            id: 4,
            message_type: 1,
            content_type: 'text',
            status: 'progress',
            content: 'Hi',
            private: true,
            content_attributes: {},
          },
          {
            id: 5,
            message_type: 1,
            content_type: 'text',
            status: 'progress',
            content: 'Fwd: Hi',
            content_attributes: { forwarded_message_id: 3 },
          },
        ],
        { en: { 1: true, 2: false } }
      );

      expect([1, 2, 3, 4, 5].map(id => translationState(id).pending)).toEqual([
        true,
        false,
        true,
        false,
        false,
      ]);
    });

    it('keeps a message pending for the agent locale although other locales have theirs', () => {
      const translationState = stateFor(
        [
          {
            id: 1,
            message_type: 0,
            content_type: 'text',
            content: 'Bonjour',
            content_attributes: { translations: { es: 'Hola' } },
          },
        ],
        { en: { 1: true } }
      );

      expect(translationState(1).pending).toBe(true);
    });

    it('keeps a reply pending until the send job has translated it', () => {
      const translationState = stateFor([
        {
          id: 1,
          message_type: 1,
          content_type: 'text',
          content: 'Hello',
          content_attributes: { translation_pending: true },
        },
      ]);

      expect(translationState(1).pending).toBe(true);
    });

    it('recognises a message already written in the agent language', () => {
      const translationState = stateFor([
        {
          id: 1,
          message_type: 0,
          content_type: 'text',
          content: 'ok thanks',
          content_attributes: { translations: { en: 'ok thanks' } },
        },
        {
          id: 2,
          message_type: 0,
          content_type: 'text',
          content: 'Bonjour',
          content_attributes: { translations: { en: 'Hello' } },
        },
      ]);

      expect(translationState(1)).toEqual({
        pending: false,
        failed: false,
        sameLanguage: true,
        sourceLanguage: 'French',
        originalLanguage: 'English',
      });
      expect(translationState(2)).toEqual({
        pending: false,
        failed: false,
        sameLanguage: false,
        sourceLanguage: 'French',
        originalLanguage: 'English',
      });
    });

    it('names the own text of a reply after the language it was written in', () => {
      const translationState = stateFor([
        {
          id: 1,
          message_type: 1,
          content_type: 'text',
          content: 'Merci',
          content_attributes: {
            translations: { ml: 'നന്ദി' },
            source_language: 'fr',
          },
        },
      ]);

      expect(translationState(1)).toMatchObject({
        sourceLanguage: 'French',
        originalLanguage: 'Malayalam',
      });
    });

    it('reports a reply the backend could not translate', () => {
      const translationState = stateFor([
        {
          id: 1,
          message_type: 1,
          content_type: 'text',
          content: 'Hi',
          content_attributes: { translation_failed: true },
        },
      ]);

      expect(translationState(1)).toMatchObject({
        failed: true,
        pending: false,
      });
    });

    it('labels a message with its own detected language when the thread switched later', () => {
      const translationState = stateFor([
        {
          id: 1,
          message_type: 0,
          content_type: 'text',
          content: '你好',
          content_attributes: {
            translations: { en: 'Hello' },
            source_language: 'zh',
          },
        },
      ]);

      expect(translationState(1).sourceLanguage).toBe('Chinese');
    });
  });
});
