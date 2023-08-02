import { actions } from '../../conversationV3/actions';
import { API } from 'widget/helpers/axios';
import { createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';

jest.mock('widget/helpers/axios');

const commit = jest.fn();

import { mockConversations } from './fixtures';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('actions', () => {
  describe('fetchAllConversations', () => {
    it('fetches all conversations successfully', async () => {
      API.get.mockResolvedValue({
        data: [mockConversations[0]],
      });

      await actions.fetchAllConversations({ commit }, {});
      expect(commit.mock.calls).toEqual([
        ['setUIFlag', { isFetching: true }],
        ['addConversationEntry', mockConversations[0]],
        ['addConversationId', 1],
        ['setConversationUIFlag', { uiFlags: {}, conversationId: 1 }],
        [
          'setConversationMeta',
          {
            meta: { userLastSeenAt: undefined, status: 'open' },
            conversationId: 1,
          },
        ],
        [
          'message/addMessagesEntry',
          { conversationId: 1, messages: [mockConversations[0].messages[1]] },
          { root: true },
        ],
        [
          'addMessageIdsToConversation',
          { conversationId: 1, messages: [mockConversations[0].messages[1]] },
        ],
        ['setUIFlag', { isFetching: false }],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      API.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.fetchAllConversations({ commit })).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        ['setUIFlag', { isFetching: true }],
        ['setUIFlag', { isFetching: false }],
      ]);
    });
  });

  describe('fetchOldMessagesIn', () => {
    it('fetches old messages in a conversation successfully', async () => {
      API.get.mockResolvedValue({
        data: [mockConversations[0].messages[0]],
      });

      const params = { conversationId: 1, beforeId: 2 };

      await actions.fetchOldMessagesIn({ commit }, params);
      expect(commit.mock.calls).toEqual([
        [
          'setConversationUIFlag',
          { uiFlags: { isFetching: true }, conversationId: 1 },
        ],
        [
          'message/addMessagesEntry',
          { conversationId: 1, messages: [mockConversations[0].messages[0]] },
          { root: true },
        ],
        [
          'prependMessageIdsToConversation',
          { conversationId: 1, messages: [mockConversations[0].messages[0]] },
        ],
        [
          'setConversationUIFlag',
          {
            uiFlags: { allFetched: true },
            conversationId: 1,
          },
        ],
        [
          'setConversationUIFlag',
          {
            uiFlags: { isFetching: false },
            conversationId: 1,
          },
        ],
      ]);
    });

    it('fetches old messages with fewer than 20 messages', async () => {
      const messages = Array(15).fill(mockConversations[0].messages[0]);
      API.get.mockResolvedValue({ data: messages });

      const params = { conversationId: 1, beforeId: 2 };

      await actions.fetchOldMessagesIn({ commit }, params);
      expect(commit.mock.calls).toEqual([
        [
          'setConversationUIFlag',
          { uiFlags: { isFetching: true }, conversationId: 1 },
        ],
        [
          'message/addMessagesEntry',
          { conversationId: 1, messages },
          { root: true },
        ],
        ['prependMessageIdsToConversation', { conversationId: 1, messages }],
        [
          'setConversationUIFlag',
          { conversationId: 1, uiFlags: { allFetched: true } },
        ],
        [
          'setConversationUIFlag',
          { uiFlags: { isFetching: false }, conversationId: 1 },
        ],
      ]);
    });

    it('handles API errors properly when fetching old messages', async () => {
      API.get.mockRejectedValue({ message: 'Something went wrong' });

      const params = { conversationId: 1, beforeId: 2 };

      await expect(
        actions.fetchOldMessagesIn({ commit }, params)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          'setConversationUIFlag',
          { uiFlags: { isFetching: true }, conversationId: 1 },
        ],
        [
          'setConversationUIFlag',
          { uiFlags: { isFetching: false }, conversationId: 1 },
        ],
      ]);
    });
  });

  describe('addConversation', () => {
    it('adds a new conversation successfully', async () => {
      const mockConversationData = mockConversations[0];

      const returnedConversationId = await actions.addConversation(
        { commit },
        mockConversationData
      );

      expect(commit.mock.calls).toEqual([
        ['addConversationEntry', mockConversationData],
        ['addConversationId', mockConversationData.id],
        [
          'setConversationUIFlag',
          {
            uiFlags: { isAgentTyping: false },
            conversationId: mockConversationData.id,
          },
        ],
        [
          'setConversationMeta',
          {
            meta: { userLastSeenAt: mockConversationData.contact_last_seen_at },
            conversationId: mockConversationData.id,
          },
        ],
        [
          'message/addMessagesEntry',
          {
            conversationId: mockConversationData.id,
            messages: mockConversationData.messages,
          },
          { root: true },
        ],
        [
          'addMessageIdsToConversation',
          {
            conversationId: mockConversationData.id,
            messages: mockConversationData.messages,
          },
        ],
      ]);

      expect(returnedConversationId).toEqual(mockConversationData.id);
    });
  });

  describe('createConversationWithMessage', () => {
    it('creates a new conversation with message successfully', async () => {
      const mockConversationParams = {
        content: 'Test message',
        contact: 'test@test.com',
      };

      const mockConversationData = mockConversations[0];

      API.post.mockResolvedValue({
        data: mockConversationData,
      });

      const returnedConversationId = await actions.createConversationWithMessage(
        { commit },
        mockConversationParams
      );

      expect(commit.mock.calls).toEqual([
        ['setUIFlag', { isCreating: true }],
        ['addConversationEntry', mockConversationData],
        ['addConversationId', mockConversationData.id],
        [
          'setConversationUIFlag',
          {
            uiFlags: { isAgentTyping: false },
            conversationId: mockConversationData.id,
          },
        ],
        [
          'setConversationMeta',
          {
            meta: { userLastSeenAt: mockConversationData.contact_last_seen_at },
            conversationId: mockConversationData.id,
          },
        ],
        [
          'message/addMessagesEntry',
          {
            conversationId: mockConversationData.id,
            messages: mockConversationData.messages,
          },
          { root: true },
        ],
        [
          'addMessageIdsToConversation',
          {
            conversationId: mockConversationData.id,
            messages: mockConversationData.messages,
          },
        ],
        ['setUIFlag', { isCreating: false }],
      ]);
      expect(returnedConversationId).toEqual(mockConversationData.id);
    });

    it('handles errors when creating a new conversation with message', async () => {
      const mockConversationParams = {
        content: 'Test message',
        contact: 'test@test.com',
      };

      API.post.mockRejectedValue(new Error('API Error'));

      await expect(
        actions.createConversationWithMessage(
          { commit },
          mockConversationParams
        )
      ).rejects.toThrow('API Error');
      expect(commit.mock.calls).toEqual([
        ['setUIFlag', { isCreating: true }],
        ['setUIFlag', { isCreating: false }],
      ]);
    });
  });
});
