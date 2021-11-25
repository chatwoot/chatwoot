import axios from 'axios';
import actions from '../../conversations/actions';
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

const commit = jest.fn();
const dispatch = jest.fn();
global.axios = axios;
jest.mock('axios');

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
      };
      actions.updateConversation({ commit, dispatch }, conversation);
      expect(commit.mock.calls).toEqual([
        [types.UPDATE_CONVERSATION, conversation],
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
        { commit, dispatch, state: { appliedFilters: [] } },
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
      jest.useFakeTimers();
    });

    it('sends correct mutations if api is successful', async () => {
      const lastSeen = new Date().getTime() / 1000;
      axios.post.mockResolvedValue({
        data: { id: 1, agent_last_seen_at: lastSeen },
      });
      await actions.markMessagesRead({ commit }, { id: 1 });
      jest.runAllTimers();
      expect(commit).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([
        [types.MARK_MESSAGE_READ, { id: 1, lastSeen }],
      ]);
    });
    it('sends correct mutations if api is unsuccessful', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await actions.markMessagesRead({ commit }, { id: 1 });
      expect(commit.mock.calls).toEqual([]);
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
      await actions.setCurrentChatTeam({ commit }, { id: 1, name: 'Team' });
      expect(commit).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([
        ['ASSIGN_TEAM', { id: 1, name: 'Team' }],
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
});

describe('#deleteMessage', () => {
  it('sends correct actions if API is success', async () => {
    const [conversationId, messageId] = [1, 1];
    axios.delete.mockResolvedValue({ data: { id: 1, content: 'deleted' } });
    await actions.deleteMessage({ commit }, { conversationId, messageId });
    expect(commit.mock.calls).toEqual([
      [types.ADD_MESSAGE, { id: 1, content: 'deleted' }],
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
