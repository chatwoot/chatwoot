import axios from 'axios';
import actions, {
  hasMessageFailedWithExternalError,
} from '../../conversations/actions';
import types from '../../../mutation-types';
const dataToSend = {
  payload: [
    {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: ['open'],
      query_operator: null,
    },
  ],
};
import { dataReceived } from './testConversationResponse';

const commit = vi.fn();
const dispatch = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#hasMessageFailedWithExternalError', () => {
  it('returns false if message is sent', () => {
    const pendingMessage = {
      status: 'sent',
      content_attributes: {},
    };
    expect(hasMessageFailedWithExternalError(pendingMessage)).toBe(false);
  });
  it('returns false if status is not failed', () => {
    const pendingMessage = {
      status: 'progress',
      content_attributes: {},
    };
    expect(hasMessageFailedWithExternalError(pendingMessage)).toBe(false);
  });

  it('returns false if status is failed but no external error', () => {
    const pendingMessage = {
      status: 'failed',
      content_attributes: {},
    };
    expect(hasMessageFailedWithExternalError(pendingMessage)).toBe(false);
  });

  it('returns true if status is failed and has external error', () => {
    const pendingMessage = {
      status: 'failed',
      content_attributes: {
        external_error: 'error',
      },
    };
    expect(hasMessageFailedWithExternalError(pendingMessage)).toBe(true);
  });
});

describe('#actions', () => {
  describe('#getConversation', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: { id: 1, meta: { sender: { id: 1, name: 'Contact 1' } } },
      });
      await actions.getConversation({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [
          types.UPDATE_CONVERSATION,
          { id: 1, meta: { sender: { id: 1, name: 'Contact 1' } } },
        ],
        ['contacts/SET_CONTACT_ITEM', { id: 1, name: 'Contact 1' }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.getConversation({ commit });
      expect(commit.mock.calls).toEqual([]);
    });
  });
  describe('#muteConversation', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue(null);
      await actions.muteConversation({ commit }, 1);
      expect(commit.mock.calls).toEqual([[types.MUTE_CONVERSATION]]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.getConversation({ commit });
      expect(commit.mock.calls).toEqual([]);
    });
  });

  describe('#updateConversation', () => {
    it('sends setContact action and update_conversation mutation', () => {
      const conversation = {
        id: 1,
        messages: [],
        meta: { sender: { id: 1, name: 'john-doe' } },
        labels: ['support'],
      };
      actions.updateConversation(
        { commit, rootState: { route: { name: 'home' } }, dispatch },
        conversation
      );
      expect(commit.mock.calls).toEqual([
        [types.UPDATE_CONVERSATION, conversation],
      ]);
      expect(dispatch.mock.calls).toEqual([
        [
          'conversationLabels/setConversationLabel',
          { id: 1, data: ['support'] },
        ],
        [
          'contacts/setContact',
          {
            id: 1,
            name: 'john-doe',
          },
        ],
      ]);
    });
  });

  describe('#addConversation', () => {
    it('doesnot send mutation if conversation is from a different inbox', () => {
      const conversation = {
        id: 1,
        messages: [],
        meta: { sender: { id: 1, name: 'john-doe' } },
        inbox_id: 2,
      };
      actions.addConversation(
        {
          commit,
          rootState: { route: { name: 'home' } },
          dispatch,
          state: { currentInbox: 1, appliedFilters: [] },
        },
        conversation
      );
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([]);
    });

    it('doesnot send mutation if conversation filters are applied', () => {
      const conversation = {
        id: 1,
        messages: [],
        meta: { sender: { id: 1, name: 'john-doe' } },
        inbox_id: 1,
      };
      actions.addConversation(
        {
          commit,
          rootState: { route: { name: 'home' } },
          dispatch,
          state: { currentInbox: 1, appliedFilters: [{ id: 'random-filter' }] },
        },
        conversation
      );
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([]);
    });

    it('doesnot send mutation if the view is conversation mentions', () => {
      const conversation = {
        id: 1,
        messages: [],
        meta: { sender: { id: 1, name: 'john-doe' } },
        inbox_id: 1,
      };
      actions.addConversation(
        {
          commit,
          rootState: { route: { name: 'conversation_mentions' } },
          dispatch,
          state: { currentInbox: 1, appliedFilters: [{ id: 'random-filter' }] },
        },
        conversation
      );
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([]);
    });

    it('doesnot send mutation if the view is conversation folders', () => {
      const conversation = {
        id: 1,
        messages: [],
        meta: { sender: { id: 1, name: 'john-doe' } },
        inbox_id: 1,
      };
      actions.addConversation(
        {
          commit,
          rootState: { route: { name: 'folder_conversations' } },
          dispatch,
          state: { currentInbox: 1, appliedFilters: [{ id: 'random-filter' }] },
        },
        conversation
      );
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([]);
    });

    it('sends correct mutations', () => {
      const conversation = {
        id: 1,
        messages: [],
        meta: { sender: { id: 1, name: 'john-doe' } },
        inbox_id: 1,
      };
      actions.addConversation(
        {
          commit,
          rootState: { route: { name: 'home' } },
          dispatch,
          state: { currentInbox: 1, appliedFilters: [] },
        },
        conversation
      );
      expect(commit.mock.calls).toEqual([
        [types.ADD_CONVERSATION, conversation],
      ]);
      expect(dispatch.mock.calls).toEqual([
        [
          'contacts/setContact',
          {
            id: 1,
            name: 'john-doe',
          },
        ],
      ]);
    });

    it('sends correct mutations if inbox filter is not available', () => {
      const conversation = {
        id: 1,
        messages: [],
        meta: { sender: { id: 1, name: 'john-doe' } },
        inbox_id: 1,
      };
      actions.addConversation(
        {
          commit,
          rootState: { route: { name: 'home' } },
          dispatch,
          state: { appliedFilters: [] },
        },
        conversation
      );
      expect(commit.mock.calls).toEqual([
        [types.ADD_CONVERSATION, conversation],
      ]);
      expect(dispatch.mock.calls).toEqual([
        [
          'contacts/setContact',
          {
            id: 1,
            name: 'john-doe',
          },
        ],
      ]);
    });
  });

  describe('#addMessage', () => {
    it('sends correct mutations if message is incoming', () => {
      const message = {
        id: 1,
        message_type: 0,
        conversation_id: 1,
      };
      actions.addMessage({ commit }, message);
      expect(commit.mock.calls).toEqual([
        [types.ADD_MESSAGE, message],
        [
          types.SET_CONVERSATION_CAN_REPLY,
          { conversationId: 1, canReply: true },
        ],
        [types.ADD_CONVERSATION_ATTACHMENTS, message],
      ]);
    });
    it('sends correct mutations if message is not an incoming message', () => {
      const message = {
        id: 1,
        message_type: 1,
        conversation_id: 1,
      };
      actions.addMessage({ commit }, message);
      expect(commit.mock.calls).toEqual([[types.ADD_MESSAGE, message]]);
    });
  });

  describe('#markMessagesRead', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    it('sends correct mutations if api is successful', async () => {
      const lastSeen = new Date().getTime() / 1000;
      axios.post.mockResolvedValue({
        data: { id: 1, agent_last_seen_at: lastSeen },
      });
      await actions.markMessagesRead({ commit }, { id: 1 });
      vi.runAllTimers();
      expect(commit).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([
        [types.UPDATE_MESSAGE_UNREAD_COUNT, { id: 1, lastSeen }],
      ]);
    });
    it('sends correct mutations if api is unsuccessful', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await actions.markMessagesRead({ commit }, { id: 1 });
      expect(commit.mock.calls).toEqual([]);
    });
  });

  describe('#markMessagesUnread', () => {
    it('sends correct mutations if API is successful', async () => {
      const lastSeen = new Date().getTime() / 1000;
      axios.post.mockResolvedValue({
        data: { id: 1, agent_last_seen_at: lastSeen, unread_count: 1 },
      });
      await actions.markMessagesUnread({ commit }, { id: 1 });
      vi.runAllTimers();
      expect(commit).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([
        [
          types.UPDATE_MESSAGE_UNREAD_COUNT,
          { id: 1, lastSeen, unreadCount: 1 },
        ],
      ]);
    });
    it('sends correct mutations if API is unsuccessful', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.markMessagesUnread({ commit }, { id: 1 })
      ).rejects.toThrow(Error);
    });
  });

  describe('#sendEmailTranscript', () => {
    it('sends correct mutations if api is successful', async () => {
      axios.post.mockResolvedValue({});
      await actions.sendEmailTranscript(
        { commit },
        { conversationId: 1, email: 'testemail@example.com' }
      );
      expect(commit).toHaveBeenCalledTimes(0);
      expect(commit.mock.calls).toEqual([]);
    });
  });

  describe('#assignAgent', () => {
    it('sends correct mutations if assignment is successful', async () => {
      axios.post.mockResolvedValue({
        data: { id: 1, name: 'User' },
      });
      await actions.assignAgent({ commit }, { conversationId: 1, agentId: 1 });
      expect(commit).toHaveBeenCalledTimes(0);
      expect(commit.mock.calls).toEqual([]);
    });
  });

  describe('#setCurrentChatAssignee', () => {
    it('sends correct mutations if assignment is successful', async () => {
      axios.post.mockResolvedValue({
        data: { id: 1, name: 'User' },
      });
      await actions.setCurrentChatAssignee({ commit }, { id: 1, name: 'User' });
      expect(commit).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([
        ['ASSIGN_AGENT', { id: 1, name: 'User' }],
      ]);
    });
  });

  describe('#toggleStatus', () => {
    it('sends correct mutations if toggle status is successful', async () => {
      axios.post.mockResolvedValue({
        data: {
          payload: {
            conversation_id: 1,
            current_status: 'snoozed',
            snoozed_until: null,
          },
        },
      });
      await actions.toggleStatus(
        { commit },
        { conversationId: 1, status: 'snoozed' }
      );
      expect(commit).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([
        [
          'CHANGE_CONVERSATION_STATUS',
          { conversationId: 1, status: 'snoozed', snoozedUntil: null },
        ],
      ]);
    });
  });

  describe('#assignTeam', () => {
    it('sends correct mutations if assignment is successful', async () => {
      axios.post.mockResolvedValue({
        data: { id: 1, name: 'Team' },
      });
      await actions.assignTeam({ commit }, { conversationId: 1, teamId: 1 });
      expect(commit).toHaveBeenCalledTimes(0);
      expect(commit.mock.calls).toEqual([]);
    });
  });

  describe('#setCurrentChatTeam', () => {
    it('sends correct mutations if assignment is successful', async () => {
      axios.post.mockResolvedValue({
        data: { id: 1, name: 'Team' },
      });
      await actions.setCurrentChatTeam(
        { commit },
        { team: { id: 1, name: 'Team' }, conversationId: 1 }
      );
      expect(commit).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([
        ['ASSIGN_TEAM', { team: { id: 1, name: 'Team' }, conversationId: 1 }],
      ]);
    });
  });

  describe('#fetchFilteredConversations', () => {
    it('fetches filtered conversations with a mock commit', async () => {
      axios.post.mockResolvedValue({
        data: dataReceived,
      });
      await actions.fetchFilteredConversations({ commit }, dataToSend);
      expect(commit).toHaveBeenCalledTimes(2);
      expect(commit.mock.calls).toEqual([
        ['SET_LIST_LOADING_STATUS'],
        ['SET_ALL_CONVERSATION', dataReceived.payload],
      ]);
    });
  });

  describe('#setConversationFilter', () => {
    it('commits the correct mutation and sets filter state', () => {
      const filters = [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'snoozed', name: 'Snoozed' }],
          query_operator: 'and',
        },
      ];
      actions.setConversationFilters({ commit }, filters);
      expect(commit.mock.calls).toEqual([
        [types.SET_CONVERSATION_FILTERS, filters],
      ]);
    });
  });

  describe('#clearConversationFilter', () => {
    it('commits the correct mutation and clears filter state', () => {
      actions.clearConversationFilters({ commit });
      expect(commit.mock.calls).toEqual([[types.CLEAR_CONVERSATION_FILTERS]]);
    });
  });

  describe('#updateConversationLastActivity', () => {
    it('sends correct action', async () => {
      await actions.updateConversationLastActivity(
        { commit },
        { conversationId: 1, lastActivityAt: 12121212 }
      );
      expect(commit.mock.calls).toEqual([
        [
          'UPDATE_CONVERSATION_LAST_ACTIVITY',
          { conversationId: 1, lastActivityAt: 12121212 },
        ],
      ]);
    });
  });

  describe('#setChatSortFilter', () => {
    it('sends correct action', async () => {
      await actions.setChatSortFilter(
        { commit },
        { data: 'sort_on_created_at' }
      );
      expect(commit.mock.calls).toEqual([
        ['CHANGE_CHAT_SORT_FILTER', { data: 'sort_on_created_at' }],
      ]);
    });
  });
});

describe('#deleteMessage', () => {
  it('sends correct actions if API is success', async () => {
    const [conversationId, messageId] = [1, 1];
    axios.delete.mockResolvedValue({
      data: { id: 1, content: 'deleted' },
    });
    await actions.deleteMessage({ commit }, { conversationId, messageId });
    expect(commit.mock.calls).toEqual([
      [types.ADD_MESSAGE, { id: 1, content: 'deleted' }],
      [types.DELETE_CONVERSATION_ATTACHMENTS, { id: 1, content: 'deleted' }],
    ]);
  });
  it('sends no actions if API is error', async () => {
    const [conversationId, messageId] = [1, 1];
    axios.delete.mockRejectedValue({ message: 'Incorrect header' });
    await expect(
      actions.deleteMessage({ commit }, { conversationId, messageId })
    ).rejects.toThrow(Error);
    expect(commit.mock.calls).toEqual([]);
  });

  describe('#updateCustomAttributes', () => {
    it('update conversation custom attributes', async () => {
      axios.post.mockResolvedValue({
        data: { custom_attributes: { order_d: '1001' } },
      });
      await actions.updateCustomAttributes(
        { commit },
        {
          conversationId: 1,
          customAttributes: { order_d: '1001' },
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES, { order_d: '1001' }],
      ]);
    });
  });
});

describe('#addMentions', () => {
  it('does not send mutations if the view is not mentions', () => {
    actions.addMentions(
      { commit, dispatch, rootState: { route: { name: 'home' } } },
      { id: 1 }
    );
    expect(commit.mock.calls).toEqual([]);
    expect(dispatch.mock.calls).toEqual([]);
  });

  it('send mutations if the view is mentions', () => {
    actions.addMentions(
      {
        dispatch,
        rootState: { route: { name: 'conversation_mentions' } },
      },
      { id: 1, meta: { sender: { id: 1 } } }
    );
    expect(dispatch.mock.calls).toEqual([
      ['updateConversation', { id: 1, meta: { sender: { id: 1 } } }],
    ]);
  });

  it('#syncActiveConversationMessages', async () => {
    const conversations = [
      {
        id: 1,
        messages: [
          {
            id: 1,
            content: 'Hello',
          },
        ],
        meta: { sender: { id: 1, name: 'john-doe' } },
        inbox_id: 1,
      },
    ];
    axios.get.mockResolvedValue({
      data: {
        payload: [{ id: 2, content: 'Welcome' }],
        meta: {
          agent_last_seen_at: '2023-04-20T05:22:42.990Z',
        },
      },
    });
    await actions.syncActiveConversationMessages(
      {
        commit,
        dispatch,
        state: {
          allConversations: conversations,
          syncConversationsMessages: {
            1: 1,
          },
        },
      },
      { conversationId: 1 }
    );
    expect(commit.mock.calls).toEqual([
      [
        'conversationMetadata/SET_CONVERSATION_METADATA',
        {
          id: 1,
          data: {
            agent_last_seen_at: '2023-04-20T05:22:42.990Z',
          },
        },
      ],
      [
        'SET_MISSING_MESSAGES',
        {
          id: 1,
          data: [
            { id: 1, content: 'Hello' },
            { id: 2, content: 'Welcome' },
          ],
        },
      ],
      [
        'SET_LAST_MESSAGE_ID_FOR_SYNC_CONVERSATION',
        { conversationId: 1, messageId: null },
      ],
    ]);
  });

  describe('#fetchAllAttachments', () => {
    it('fetches all attachments', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: [
            {
              id: 1,
              message_id: 1,
              file_type: 'image',
              data_url: '',
              thumb_url: '',
            },
          ],
        },
      });
      await actions.fetchAllAttachments({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [
          types.SET_ALL_ATTACHMENTS,
          {
            id: 1,
            data: [
              {
                id: 1,
                message_id: 1,
                file_type: 'image',
                data_url: '',
                thumb_url: '',
              },
            ],
          },
        ],
      ]);
    });
  });

  describe('#setContextMenuChatId', () => {
    it('sets the context menu chat id', () => {
      actions.setContextMenuChatId({ commit }, 1);
      expect(commit.mock.calls).toEqual([[types.SET_CONTEXT_MENU_CHAT_ID, 1]]);
    });
  });

  describe('#setChatListFilters', () => {
    it('set chat list filters', () => {
      const filters = {
        inboxId: 1,
        assigneeType: 'me',
        status: 'open',
        sortBy: 'created_at',
        page: 1,
        labels: ['label'],
        teamId: 1,
        conversationType: 'mention',
      };
      actions.setChatListFilters({ commit }, filters);
      expect(commit.mock.calls).toEqual([
        [types.SET_CHAT_LIST_FILTERS, filters],
      ]);
    });
  });

  describe('#updateChatListFilters', () => {
    it('update chat list filters', () => {
      actions.updateChatListFilters({ commit }, { updatedWithin: 20 });
      expect(commit.mock.calls).toEqual([
        [types.UPDATE_CHAT_LIST_FILTERS, { updatedWithin: 20 }],
      ]);
    });
  });

  describe('#getInboxCaptainAssistantById', () => {
    it('fetches inbox assistant by id', async () => {
      axios.get.mockResolvedValue({
        data: {
          id: 1,
          name: 'Assistant',
          description: 'Assistant description',
        },
      });
      await actions.getInboxCaptainAssistantById({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [
          types.SET_INBOX_CAPTAIN_ASSISTANT,
          { id: 1, name: 'Assistant', description: 'Assistant description' },
        ],
      ]);
    });
  });
});
