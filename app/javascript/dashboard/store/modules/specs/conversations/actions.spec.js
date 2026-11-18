import axios from 'axios';
import { emitter } from 'shared/helpers/mitt';
import { createStore } from 'vuex';
import types from '../../../mutation-types';
import conversationMetadata from '../../conversationMetadata';
import { mutations } from '../../conversations';
import actions, {
  hasMessageFailedWithExternalError,
} from '../../conversations/actions';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { dataReceived } from './testConversationResponse';
const dataToSend = {
  page: 1,
  queryData: {
    payload: [
      {
        attribute_key: 'status',
        filter_operator: 'equal_to',
        values: ['open'],
        query_operator: null,
      },
    ],
  },
};

const commit = vi.fn();
const dispatch = vi.fn();
global.axios = axios;
vi.mock('axios');
vi.mock('shared/helpers/mitt', () => ({ emitter: { emit: vi.fn() } }));

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
  describe('conversation history loading', () => {
    let store;
    let conversationA;
    let conversationB;

    beforeEach(() => {
      conversationA = { id: 42, messages: [{ id: 100 }] };
      conversationB = { id: 43, messages: [{ id: 200 }] };
      store = createStore({
        state: {
          allConversations: [conversationA, conversationB],
          selectedChatId: null,
        },
        getters: { getAutoTranslate: () => ({ enabled: false }) },
        actions,
        mutations,
        modules: {
          conversationMetadata: {
            ...conversationMetadata,
            state: { records: {} },
          },
        },
      });
    });

    it('shares pending history when switching A to B to A and keeps responses in their own conversations', async () => {
      let resolveA;
      let resolveB;
      axios.get
        .mockImplementationOnce(
          () =>
            new Promise(resolve => {
              resolveA = resolve;
            })
        )
        .mockImplementationOnce(
          () =>
            new Promise(resolve => {
              resolveB = resolve;
            })
        );

      const firstA = store.dispatch('setActiveChat', { data: conversationA });
      const firstB = store.dispatch('setActiveChat', { data: conversationB });
      const secondA = store.dispatch('setActiveChat', { data: conversationA });

      expect(axios.get).toHaveBeenCalledTimes(2);
      expect(conversationA.dataFetched).toBeUndefined();

      resolveB({ data: { meta: {}, payload: [{ id: 199 }] } });
      await firstB;
      expect(store.state.selectedChatId).toBe(42);
      expect(conversationA.messages).toEqual([{ id: 100 }]);
      expect(conversationB.messages).toEqual([{ id: 199 }, { id: 200 }]);

      resolveA({ data: { meta: {}, payload: [{ id: 99 }] } });
      await Promise.all([firstA, secondA]);
      expect(conversationA.messages).toEqual([{ id: 99 }, { id: 100 }]);
      expect(conversationA.dataFetched).toBe(true);
      expect(conversationB.dataFetched).toBe(true);
    });

    it('leaves failed history unfetched and retries when the conversation is reopened', async () => {
      axios.get.mockRejectedValueOnce(new Error('Network error'));

      await store.dispatch('setActiveChat', { data: conversationA });

      expect(conversationA.dataFetched).toBeUndefined();
      expect(conversationA.messages).toEqual([{ id: 100 }]);
      expect(conversationA.allMessagesLoaded).toBe(false);

      axios.get.mockResolvedValueOnce({
        data: { meta: {}, payload: [{ id: 99 }] },
      });
      await store.dispatch('setActiveChat', { data: conversationA });

      expect(axios.get).toHaveBeenCalledTimes(2);
      expect(conversationA.messages).toEqual([{ id: 99 }, { id: 100 }]);
      expect(conversationA.dataFetched).toBe(true);
    });

    it.each(['before', 'after'])(
      'loads distinct %s cursors independently and allows a completed request again',
      async cursor => {
        let resolveHistory;
        const response = new Promise(resolve => {
          resolveHistory = resolve;
        });
        axios.get.mockReturnValue(response);
        const firstParams = { conversationId: 42, [cursor]: 90 };
        const secondParams = { conversationId: 42, [cursor]: 80 };

        const first = store.dispatch('fetchPreviousMessages', firstParams);
        const second = store.dispatch('fetchPreviousMessages', secondParams);
        expect(axios.get).toHaveBeenCalledTimes(2);

        resolveHistory({ data: { meta: {}, payload: [] } });
        await Promise.all([first, second]);
        await store.dispatch('fetchPreviousMessages', firstParams);
        expect(axios.get).toHaveBeenCalledTimes(3);
      }
    );
  });

  describe('#getConversation', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          id: 1,
          labels: ['support'],
          meta: { sender: { id: 1, name: 'Contact 1' } },
        },
      });
      await actions.getConversation({ commit, dispatch }, 1);
      expect(commit.mock.calls).toEqual([
        [
          types.SET_ALL_CONVERSATION,
          [
            {
              id: 1,
              labels: ['support'],
              meta: { sender: { id: 1, name: 'Contact 1' } },
            },
          ],
        ],
        ['contacts/SET_CONTACT_ITEM', { id: 1, name: 'Contact 1' }],
      ]);
      expect(dispatch).toHaveBeenCalledWith(
        'conversationLabels/setConversationLabel',
        { id: 1, data: ['support'] }
      );
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
        ['autoTranslateMessages', 1],
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
      actions.addMessage({ commit, dispatch }, message);
      expect(commit.mock.calls).toEqual([
        [types.ADD_MESSAGE, message],
        [
          types.SET_CONVERSATION_CAN_REPLY,
          { conversationId: 1, canReply: true },
        ],
        [types.ADD_CONVERSATION_ATTACHMENTS, message],
      ]);
      expect(dispatch).toHaveBeenCalledWith('autoTranslateMessages', 1);
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

  describe('#updateMessage', () => {
    it('refreshes loaded conversations sharing the same contact inbox source after terminal contact info updates', () => {
      const localCommit = vi.fn();
      const localDispatch = vi.fn();
      const message = {
        id: 1,
        conversation_id: 10,
        status: 'sent',
        content_attributes: {
          whatsapp_contact_info: {
            type: 'request',
            state: 'identity_conflict',
          },
        },
        conversation: {
          contact_inbox: { source_id: 'IN.2081978709342942' },
        },
      };
      const state = {
        allConversations: [
          { id: 10, messages: [message] },
          {
            id: 20,
            messages: [
              {
                conversation: {
                  contact_inbox: { source_id: 'IN.2081978709342942' },
                },
              },
            ],
          },
          {
            id: 30,
            messages: [
              {
                conversation: {
                  contact_inbox: { source_id: 'IN.3109889333218546' },
                },
              },
            ],
          },
        ],
      };

      actions.updateMessage(
        {
          commit: localCommit,
          dispatch: localDispatch,
          rootGetters: {},
          state,
        },
        message
      );

      expect(localCommit.mock.calls).toEqual([[types.ADD_MESSAGE, message]]);
      expect(localDispatch.mock.calls).toEqual([
        ['getConversation', 10],
        ['getConversation', 20],
      ]);
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
    const owner = { id: 2, name: 'Owner' };
    const getters = {
      getConversationById: () => ({
        meta: { assignee: owner, assignee_type: 'User' },
      }),
    };

    it('commits the optimistic assignee and then the server response', async () => {
      axios.post.mockResolvedValue({
        data: { id: 1, name: 'User' },
      });
      await actions.assignAgent(
        { commit, getters },
        {
          conversationId: 1,
          assignee: { id: 1, name: 'User' },
          assigneeType: 'AgentBot',
        }
      );
      expect(commit.mock.calls).toEqual([
        [
          'ASSIGN_AGENT',
          {
            conversationId: 1,
            assignee: { id: 1, name: 'User' },
            assigneeType: 'AgentBot',
          },
        ],
        [
          'ASSIGN_AGENT',
          {
            conversationId: 1,
            assignee: { id: 1, name: 'User' },
            assigneeType: 'AgentBot',
          },
        ],
      ]);
    });

    // Without the rollback the agent keeps seeing their own name in the
    // assignee field and believes they own a conversation they were denied.
    it('rolls back to the previous assignee and rethrows when rejected', async () => {
      const error = {
        response: { status: 409, data: { agent_name: 'Owner' } },
      };
      axios.post.mockRejectedValue(error);

      await expect(
        actions.assignAgent(
          { commit, dispatch, getters },
          {
            conversationId: 1,
            assignee: { id: 1, name: 'User' },
            assigneeType: 'User',
          }
        )
      ).rejects.toEqual(error);

      expect(commit.mock.calls[1]).toEqual([
        'ASSIGN_AGENT',
        { conversationId: 1, assignee: owner, assigneeType: 'User' },
      ]);
    });

    // The rolled-back snapshot is the thing that went stale during a
    // concurrent claim, so the conflict has to be reconciled with the server.
    it('re-reads the conversation when the assignment was refused', async () => {
      dispatch.mockClear();
      axios.post.mockRejectedValue({
        response: { status: 409, data: { agent_name: 'Owner' } },
      });

      await expect(
        actions.assignAgent(
          { commit, dispatch, getters },
          { conversationId: 1, assignee: { id: 1, name: 'User' } }
        )
      ).rejects.toBeTruthy();

      expect(dispatch).toHaveBeenCalledWith('getConversation', 1);
    });

    it('does not re-read the conversation on an unrelated failure', async () => {
      dispatch.mockClear();
      axios.post.mockRejectedValue({ response: { status: 500 } });

      await expect(
        actions.assignAgent(
          { commit, dispatch, getters },
          { conversationId: 1, assignee: { id: 1, name: 'User' } }
        )
      ).rejects.toBeTruthy();

      expect(dispatch).not.toHaveBeenCalledWith('getConversation', 1);
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

    // Reopening self-assigns the agent, so a protected inbox refuses the whole
    // request. Swallowing that left every caller announcing a status change
    // that never happened.
    it('rethrows and reconciles when the status change is refused', async () => {
      const error = {
        response: { status: 409, data: { agent_name: 'Owner' } },
      };
      axios.post.mockRejectedValue(error);
      dispatch.mockClear();

      await expect(
        actions.toggleStatus(
          { commit, dispatch },
          { conversationId: 1, status: 'open' }
        )
      ).rejects.toEqual(error);

      expect(dispatch).toHaveBeenCalledWith('getConversation', 1);
    });
  });

  describe('#assignTeam', () => {
    const previousTeam = { id: 9, name: 'Previous' };
    const team = { id: 1, name: 'Team' };
    const getters = {
      getConversationById: () => ({ meta: { team: previousTeam } }),
    };

    it('commits the optimistic team and then the server response', async () => {
      axios.post.mockResolvedValue({ data: team });

      await actions.assignTeam(
        { commit, dispatch, getters },
        { conversationId: 1, team }
      );

      expect(commit.mock.calls).toEqual([
        ['ASSIGN_TEAM', { team, conversationId: 1 }],
        ['ASSIGN_TEAM', { team, conversationId: 1 }],
      ]);
    });

    // Picking a team that excludes the current assignee moves the assignee too,
    // so a protected inbox refuses the whole thing.
    it('rolls back and reconciles when the team change is refused', async () => {
      const error = {
        response: { status: 409, data: { agent_name: 'Owner' } },
      };
      axios.post.mockRejectedValue(error);
      dispatch.mockClear();

      await expect(
        actions.assignTeam(
          { commit, dispatch, getters },
          { conversationId: 1, team }
        )
      ).rejects.toEqual(error);

      expect(commit.mock.calls[1]).toEqual([
        'ASSIGN_TEAM',
        { team: previousTeam, conversationId: 1 },
      ]);
      expect(dispatch).toHaveBeenCalledWith('getConversation', 1);
    });
  });

  describe('#fetchFilteredConversations', () => {
    it('ignores an older open-list response after applying an all-status filter', async () => {
      let resolveOpenResponse;
      axios.get.mockReturnValue(
        new Promise(resolve => {
          resolveOpenResponse = resolve;
        })
      );
      const openRequest = actions.fetchAllConversations({
        commit,
        dispatch,
        state: { conversationFilters: { status: 'open', assigneeType: 'all' } },
      });
      const filteredResponse = {
        payload: [],
        meta: { all_count: 10757 },
      };
      axios.post.mockResolvedValue({ data: filteredResponse });

      await actions.fetchFilteredConversations(
        {
          commit,
          dispatch,
          state: {
            appliedFiltersSortBy: null,
            chatSortFilter: 'last_activity_at_desc',
          },
        },
        {
          queryData: {
            payload: [
              {
                attribute_key: 'status',
                filter_operator: 'equal_to',
                values: ['all'],
              },
            ],
          },
          page: 1,
        }
      );
      resolveOpenResponse({
        data: { data: { payload: [], meta: { all_count: 30 } } },
      });
      await openRequest;

      expect(
        dispatch.mock.calls.filter(
          ([action]) => action === 'conversationStats/set'
        )
      ).toEqual([
        [
          'conversationStats/set',
          { meta: filteredResponse.meta, request: undefined },
        ],
      ]);
    });

    it('fetches filtered conversations with a mock commit', async () => {
      axios.post.mockResolvedValue({
        data: dataReceived,
      });
      await actions.fetchFilteredConversations(
        {
          commit,
          dispatch,
          state: {
            appliedFiltersSortBy: null,
            chatSortFilter: 'last_activity_at_desc',
          },
        },
        dataToSend
      );
      expect(commit).toHaveBeenCalledTimes(4);
      expect(commit.mock.calls).toEqual([
        ['SET_LIST_LOADING_STATUS'],
        ['SET_ALL_CONVERSATION', dataReceived.payload],
        ['CLEAR_LIST_LOADING_STATUS'],
        [
          `contacts/${types.SET_CONTACTS}`,
          dataReceived.payload.map(chat => chat.meta.sender),
        ],
      ]);
      expect(axios.post).toHaveBeenCalledWith(
        '/api/v1/conversations/filter',
        dataToSend.queryData,
        expect.objectContaining({
          params: {
            page: dataToSend.page,
            sort_by: 'last_activity_at_desc',
          },
        })
      );
    });

    it('clears the loading state and rethrows if the request fails', async () => {
      axios.post.mockRejectedValue(new Error('Request failed'));
      await expect(
        actions.fetchFilteredConversations(
          {
            commit,
            dispatch,
            state: {
              appliedFiltersSortBy: null,
              chatSortFilter: 'last_activity_at_desc',
            },
          },
          dataToSend
        )
      ).rejects.toThrow('Request failed');
      expect(commit.mock.calls).toEqual([
        ['SET_LIST_LOADING_STATUS'],
        ['CLEAR_LIST_LOADING_STATUS'],
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

  describe('#reconcileConversationTab', () => {
    const filters = { assigneeType: 'unassigned', status: 'open' };
    const onScreen = [
      { id: 1, inbox_id: 7 },
      { id: 2, inbox_id: 7 },
      { id: 3, inbox_id: 8 },
    ];
    const fresh = (id, updatedAt = 200) => ({
      id,
      updated_at: updatedAt,
      meta: { assignee: { id: 42 } },
    });
    const inStore = { 1: { id: 1, updated_at: 100 } };

    const contextWith = (
      payload,
      chats = onScreen,
      stored = inStore,
      selectedChatId = null
    ) => {
      axios.post.mockResolvedValue({ data: { payload } });
      return {
        commit,
        state: { selectedChatId },
        getters: {
          getUnAssignedChats: () => chats,
          getConversationById: id => stored[id],
        },
      };
    };

    beforeEach(() => {
      commit.mockClear();
      dispatch.mockClear();
      axios.post.mockReset();
    });

    // Evicting would take the conversation out of "all" and out of its new owner's "mine" too,
    // since every tab reads the same cache.
    it('refreshes the stale rows instead of evicting them', async () => {
      const payload = [fresh(1), fresh(2), fresh(3)];
      const removed = await actions.reconcileConversationTab(
        contextWith(payload),
        filters
      );

      expect(commit.mock.calls).toEqual([
        [types.SET_ALL_CONVERSATION, payload],
      ]);
      expect(removed).toEqual([]);
    });

    it('removes only what the server did not return at all', async () => {
      const payload = [fresh(2)];
      const removed = await actions.reconcileConversationTab(
        contextWith(payload),
        filters
      );

      expect(commit.mock.calls).toEqual([
        [types.SET_ALL_CONVERSATION, payload],
        [types.REMOVE_CONVERSATIONS, [1, 3]],
      ]);
      expect(removed).toEqual([
        { id: 1, inboxId: 7 },
        { id: 3, inboxId: 8 },
      ]);
    });

    // The endpoint serializes full conversations and refuses an oversized batch, so a caller that
    // scrolled through several pages has to split the question rather than have it rejected.
    it('splits a list longer than one page into page-sized requests', async () => {
      const many = Array.from({ length: 60 }, (_, i) => ({
        id: i + 1,
        inbox_id: 7,
      }));
      axios.post.mockResolvedValue({ data: { payload: [] } });

      await actions.reconcileConversationTab(
        {
          commit,
          getters: {
            getUnAssignedChats: () => many,
            getConversationById: () => undefined,
          },
        },
        filters
      );

      expect(axios.post).toHaveBeenCalledTimes(3);
      expect(axios.post.mock.calls.map(call => call[1].ids.length)).toEqual([
        25, 25, 10,
      ]);
    });

    it('asks only about the conversations on screen', async () => {
      await actions.reconcileConversationTab(
        contextWith([fresh(1), fresh(2), fresh(3)]),
        filters
      );

      expect(axios.post).toHaveBeenCalledWith(
        expect.stringContaining('/conversations/sync'),
        { ids: [1, 2, 3] }
      );
    });

    // The answer is about the list as it was when the request went out. A conversation that
    // arrives over the cable mid-flight is missing from that answer because it was never asked
    // about, and removing it would undo a live event.
    it('leaves alone a conversation that arrived while the request was in flight', async () => {
      const chats = [...onScreen];
      axios.post.mockImplementation(() => {
        chats.push({ id: 99, inbox_id: 7 });
        return Promise.resolve({
          data: { payload: [fresh(1), fresh(2), fresh(3)] },
        });
      });

      const removed = await actions.reconcileConversationTab(
        {
          commit,
          state: { selectedChatId: null },
          getters: {
            getUnAssignedChats: () => chats,
            getConversationById: () => undefined,
          },
        },
        filters
      );

      expect(removed).toEqual([]);
      expect(commit.mock.calls).toEqual([
        [types.SET_ALL_CONVERSATION, [fresh(1), fresh(2), fresh(3)]],
      ]);
    });

    // A cable event can beat the response home. Writing the older row back would regress the status
    // or the assignee, and hide the conversation with nothing watching to bring it back.
    it('drops a row the store already holds a newer copy of', async () => {
      const payload = [fresh(1, 50), fresh(2, 300), fresh(3, 300)];
      await actions.reconcileConversationTab(contextWith(payload), filters);

      expect(commit.mock.calls).toEqual([
        [types.SET_ALL_CONVERSATION, [fresh(2, 300), fresh(3, 300)]],
      ]);
    });

    it('keeps a row the store holds an older copy of', async () => {
      const payload = [fresh(1, 500)];
      await actions.reconcileConversationTab(contextWith(payload), filters);

      expect(commit.mock.calls).toEqual([
        [types.SET_ALL_CONVERSATION, [fresh(1, 500)]],
        [types.REMOVE_CONVERSATIONS, [2, 3]],
      ]);
    });

    // The store has no router, so removing the conversation the panel is showing is announced and
    // the component that owns the route acts on it.
    it('announces when it removed the conversation the panel is showing', async () => {
      await actions.reconcileConversationTab(
        contextWith([fresh(2)], onScreen, inStore, 3),
        filters
      );

      expect(emitter.emit).toHaveBeenCalledWith(
        BUS_EVENTS.OPEN_CONVERSATION_GONE
      );
    });

    it('stays quiet when the open conversation survived', async () => {
      await actions.reconcileConversationTab(
        contextWith([fresh(2), fresh(3)], onScreen, inStore, 3),
        filters
      );

      expect(emitter.emit).not.toHaveBeenCalledWith(
        BUS_EVENTS.OPEN_CONVERSATION_GONE
      );
    });

    it('does not call out when the tab is empty on screen', async () => {
      const removed = await actions.reconcileConversationTab(
        contextWith([], []),
        filters
      );

      expect(axios.post).not.toHaveBeenCalled();
      expect(removed).toEqual([]);
    });

    // Mentions and participating carry an assigneeType but are narrowed by a membership the store
    // cannot reproduce, so what is on screen there is not the tab this would judge it against.
    it('does nothing on a view the store cannot reproduce', async () => {
      const removed = await actions.reconcileConversationTab(contextWith([]), {
        ...filters,
        conversationType: 'mention',
      });

      expect(axios.post).not.toHaveBeenCalled();
      expect(removed).toEqual([]);
    });

    it('does nothing on a view that has no tab getter', async () => {
      const removed = await actions.reconcileConversationTab(contextWith([]), {
        assigneeType: 'appliedFilters',
      });

      expect(axios.post).not.toHaveBeenCalled();
      expect(commit.mock.calls).toEqual([]);
      expect(removed).toEqual([]);
    });

    it('keeps the list as is when the request fails', async () => {
      axios.post.mockRejectedValue({ message: 'Network error' });
      const removed = await actions.reconcileConversationTab(
        {
          commit,
          state: { selectedChatId: null },
          getters: {
            getUnAssignedChats: () => onScreen,
            getConversationById: () => undefined,
          },
        },
        filters
      );

      expect(commit.mock.calls).toEqual([]);
      expect(removed).toEqual([]);
    });
  });

  describe('#deleteConversation', () => {
    it('send correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({
        data: { id: 1 },
      });
      await actions.deleteConversation({ commit, dispatch }, 1);
      expect(commit.mock.calls).toEqual([[types.DELETE_CONVERSATION, 1]]);
      expect(dispatch.mock.calls).toEqual([['conversationStats/get']]);
    });

    it('send no actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.deleteConversation({ commit, dispatch }, 1)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([]);
    });
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
        [
          types.UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES,
          {
            conversationId: 1,
            customAttributes: { order_d: '1001' },
          },
        ],
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
    expect(dispatch).toHaveBeenCalledWith('autoTranslateMessages', 1);
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

  // The server answers a bounded window per call. An agent away long enough to miss more
  // than one of them was handed the first window and told the catch-up was over: the cursor
  // was cleared and nothing fetched the rest until the conversation was opened again.
  it('#syncActiveConversationMessages walks past a full window', async () => {
    const firstWindow = Array.from({ length: 100 }, (_, index) => ({
      id: index + 2,
      content: `page one ${index}`,
    }));
    axios.get
      .mockResolvedValueOnce({ data: { payload: firstWindow, meta: {} } })
      .mockResolvedValueOnce({
        data: { payload: [{ id: 500, content: 'page two' }], meta: {} },
      });

    await actions.syncActiveConversationMessages(
      {
        commit,
        dispatch,
        state: {
          allConversations: [{ id: 1, messages: [], inbox_id: 1 }],
          syncConversationsMessages: { 1: 1 },
        },
      },
      { conversationId: 1 }
    );

    expect(axios.get.mock.calls.length).toBe(2);
    // The second call starts above the highest id the first window carried, not above the
    // cursor it was given.
    expect(axios.get.mock.calls[1][1]).toEqual({ params: { after: 101 } });
    const written = commit.mock.calls.find(
      ([name]) => name === 'SET_MISSING_MESSAGES'
    );
    expect(written[1].data.map(message => message.id)).toContain(500);
  });

  // A full window that carries nothing above the cursor would be asked for again for ever.
  it('#syncActiveConversationMessages stops on a window that does not advance', async () => {
    const stuck = Array.from({ length: 100 }, () => ({
      id: 1,
      content: 'same',
    }));
    axios.get.mockResolvedValue({ data: { payload: stuck, meta: {} } });

    await actions.syncActiveConversationMessages(
      {
        commit,
        dispatch,
        state: {
          allConversations: [{ id: 1, messages: [], inbox_id: 1 }],
          syncConversationsMessages: { 1: 1 },
        },
      },
      { conversationId: 1 }
    );

    expect(axios.get.mock.calls.length).toBe(1);
  });

  // The cursor is the highest id the client holds, not the last row of a list sorted by
  // time: an imported message is stamped with when it was sent and takes its id from the
  // INSERT, so taking the newest by time set the cursor above rows never received.
  it('#setConversationLastMessageId takes the highest id, not the newest', async () => {
    await actions.setConversationLastMessageId(
      {
        commit,
        state: {
          allConversations: [
            { id: 1, messages: [{ id: 90 }, { id: 91 }, { id: 42 }] },
          ],
        },
      },
      { conversationId: 1 }
    );

    expect(commit.mock.calls).toEqual([
      [
        'SET_LAST_MESSAGE_ID_FOR_SYNC_CONVERSATION',
        { conversationId: 1, messageId: 91 },
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

  describe('#setActiveChat', () => {
    it('should commit SET_CHAT_DATA_FETCHED with conversation ID after fetch', async () => {
      const localCommit = vi.fn();
      const localDispatch = vi.fn().mockResolvedValue();
      const data = { id: 42, messages: [{ id: 100 }] };

      await actions.setActiveChat(
        { commit: localCommit, dispatch: localDispatch },
        { data, after: 99 }
      );

      expect(localCommit.mock.calls).toEqual([
        [types.SET_CURRENT_CHAT_WINDOW, data],
        [types.CLEAR_ALL_MESSAGES_LOADED, 42],
        [types.SET_CHAT_DATA_FETCHED, 42],
      ]);
      expect(localDispatch).toHaveBeenCalledWith('fetchPreviousMessages', {
        after: 99,
        before: 100,
        conversationId: 42,
      });
    });

    it('should not dispatch fetchPreviousMessages if dataFetched is already set', async () => {
      const localCommit = vi.fn();
      const localDispatch = vi.fn();
      const data = { id: 42, messages: [{ id: 100 }], dataFetched: true };

      await actions.setActiveChat(
        { commit: localCommit, dispatch: localDispatch },
        { data }
      );

      expect(localCommit.mock.calls).toEqual([
        [types.SET_CURRENT_CHAT_WINDOW, data],
      ]);
      expect(localDispatch).not.toHaveBeenCalled();
    });

    it('should fetch without a cursor when the conversation has no messages', async () => {
      const localCommit = vi.fn();
      const localDispatch = vi.fn().mockResolvedValue();
      const data = { id: 42, messages: [] };

      await actions.setActiveChat(
        { commit: localCommit, dispatch: localDispatch },
        { data }
      );

      expect(localDispatch).toHaveBeenCalledWith('fetchPreviousMessages', {
        after: undefined,
        before: undefined,
        conversationId: 42,
      });
      expect(localCommit).toHaveBeenCalledWith(types.SET_CHAT_DATA_FETCHED, 42);
    });

    it('should commit SET_CHAT_DATA_FETCHED by ID, not mutate the data object directly (race condition fix)', async () => {
      const localCommit = vi.fn();
      const localDispatch = vi.fn().mockResolvedValue();
      const data = { id: 42, messages: [{ id: 100 }] };

      await actions.setActiveChat(
        { commit: localCommit, dispatch: localDispatch },
        { data }
      );

      // The action must NOT set dataFetched on the data object directly
      expect(data.dataFetched).toBeUndefined();

      // Instead it commits a mutation that finds the conversation by ID in the store
      expect(localCommit).toHaveBeenCalledWith(types.SET_CHAT_DATA_FETCHED, 42);
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

  describe('#updateConversation', () => {
    it('re-checks translation once the conversation language may have changed', () => {
      const localDispatch = vi.fn();

      actions.updateConversation(
        { commit: vi.fn(), dispatch: localDispatch, rootGetters: {} },
        {
          id: 7,
          labels: [],
          additional_attributes: { conversation_language: 'fr' },
        }
      );

      expect(localDispatch).toHaveBeenCalledWith('autoTranslateMessages', 7);
    });
  });

  describe('#autoTranslateMessages', () => {
    const messages = [
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
        content: 'Hello',
        content_attributes: { translations: { en: 'Hello' } },
      },
      {
        id: 3,
        message_type: 1,
        content_type: 'text',
        content: 'Hi',
        content_attributes: {},
      },
      {
        id: 4,
        message_type: 0,
        content_type: 'text',
        content: 'Merci',
        content_attributes: {},
      },
    ];
    const getters = {
      getAutoTranslate: { enabled: true, locale: 'en', sameLanguage: false },
      getSelectedChat: { id: 7, messages },
    };
    const state = { selectedChatId: 7, autoTranslating: { en: { 4: false } } };

    it('queues the incoming messages that have no translation yet and keeps them pending', async () => {
      const localCommit = vi.fn();
      axios.post.mockResolvedValue({});

      await actions.autoTranslateMessages(
        { state, commit: localCommit, getters },
        7
      );

      expect(axios.post).toHaveBeenCalledWith(
        expect.stringContaining('/conversations/7/messages/auto_translate'),
        { message_ids: [1] }
      );
      expect(localCommit.mock.calls).toEqual([
        [
          types.SET_AUTO_TRANSLATING,
          { locale: 'en', messageIds: [1], translating: true },
        ],
      ]);
    });

    it('requests bot replies, which are written in the contact language, but not agent replies', async () => {
      axios.post.mockResolvedValue({});
      const botMessages = [
        {
          id: 5,
          message_type: 1,
          content_type: 'text',
          content: 'Bonjour',
          sender: { type: 'captain_assistant' },
          content_attributes: {},
        },
        {
          id: 8,
          message_type: 1,
          content_type: 'text',
          content: 'Bonjour',
          sender: { type: 'user' },
          content_attributes: {},
        },
      ];

      await actions.autoTranslateMessages(
        {
          state: { selectedChatId: 7, autoTranslating: {} },
          commit,
          getters: {
            ...getters,
            getSelectedChat: { id: 7, messages: botMessages },
          },
        },
        7
      );

      expect(axios.post).toHaveBeenCalledWith(
        expect.stringContaining('/conversations/7/messages/auto_translate'),
        { message_ids: [5] }
      );
    });

    it('skips call bubbles and other non-text messages', async () => {
      axios.post.mockResolvedValue({});
      const chatMessages = [
        {
          id: 5,
          message_type: 0,
          content_type: 'text',
          content: 'Bonjour',
          content_attributes: {},
        },
        {
          id: 6,
          message_type: 0,
          content_type: 'voice_call',
          content: 'WhatsApp Call',
          content_attributes: {},
        },
      ];

      await actions.autoTranslateMessages(
        {
          state: { selectedChatId: 7, autoTranslating: {} },
          commit,
          getters: {
            ...getters,
            getSelectedChat: { id: 7, messages: chatMessages },
          },
        },
        7
      );

      expect(axios.post).toHaveBeenCalledWith(
        expect.stringContaining('/conversations/7/messages/auto_translate'),
        { message_ids: [5] }
      );
    });

    it('does nothing for another conversation or a disabled flag', async () => {
      await actions.autoTranslateMessages({ state, commit, getters }, 8);
      await actions.autoTranslateMessages(
        {
          state,
          commit,
          getters: {
            getAutoTranslate: { ...getters.getAutoTranslate, enabled: false },
          },
        },
        7
      );

      expect(axios.post).not.toHaveBeenCalled();
    });

    it('alerts and leaves the messages retryable when the request fails', async () => {
      const localCommit = vi.fn();
      const emit = vi.spyOn(emitter, 'emit');
      axios.post.mockRejectedValue({
        response: {
          status: 422,
          data: { error: 'You are out of Copilot credits.' },
        },
      });

      await actions.autoTranslateMessages(
        { state, commit: localCommit, getters },
        7
      );

      expect(localCommit).toHaveBeenLastCalledWith(types.SET_AUTO_TRANSLATING, {
        locale: 'en',
        messageIds: [1],
        translating: undefined,
      });
      expect(emit).toHaveBeenCalledWith('newToastMessage', {
        message: 'You are out of Copilot credits.',
        action: null,
      });
    });

    it('stays quiet when the feature is off for the account', async () => {
      const emit = vi.spyOn(emitter, 'emit');
      axios.post.mockRejectedValue({
        response: { status: 403, data: { error: 'Auto translate is off.' } },
      });

      await actions.autoTranslateMessages(
        { state, commit: vi.fn(), getters },
        7
      );

      expect(emit).not.toHaveBeenCalledWith(
        'newToastMessage',
        expect.anything()
      );
    });

    it('requests nothing in a conversation switched off', async () => {
      const localCommit = vi.fn();

      await actions.autoTranslateMessages(
        {
          state,
          commit: localCommit,
          getters: {
            ...getters,
            getAutoTranslate: {
              ...getters.getAutoTranslate,
              disabledInConversation: true,
            },
          },
        },
        7
      );

      expect(axios.post).not.toHaveBeenCalled();
      expect(localCommit).not.toHaveBeenCalled();
    });
  });

  describe('#setConversationAutoTranslate', () => {
    it('saves the switch on the conversation', async () => {
      axios.patch.mockResolvedValue({ data: {} });

      await actions.setConversationAutoTranslate(
        {},
        { conversationId: 7, disabled: true }
      );

      expect(axios.patch).toHaveBeenCalledWith(
        expect.stringContaining('/conversations/7'),
        { auto_translate_disabled: true }
      );
    });
  });
});
