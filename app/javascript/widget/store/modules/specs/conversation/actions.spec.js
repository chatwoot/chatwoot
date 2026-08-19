import { API } from 'widget/helpers/axios';
import getUuid from '../../../../helpers/uuid';
import { actions } from '../../conversation/actions';
import { mutations } from '../../conversation/mutations';

const rootStateWith = id => ({ conversationAttributes: { id } });

vi.mock('../../../../helpers/uuid');
vi.mock('widget/helpers/axios');

const commit = vi.fn();
const dispatch = vi.fn();

describe('#actions', () => {
  describe('#createConversation', () => {
    it('sends correct mutations', async () => {
      API.post.mockResolvedValue({
        data: {
          contact: { name: 'contact-name' },
          messages: [{ id: 1, content: 'This is a test message' }],
        },
      });

      let windowSpy = vi.spyOn(window, 'window', 'get');
      windowSpy.mockImplementation(() => ({
        WOOT_WIDGET: {
          $root: {
            $i18n: {
              locale: 'el',
            },
          },
        },
        location: {
          search: '?param=1',
        },
      }));
      await actions.createConversation(
        { commit },
        { contact: {}, message: 'This is a test message' }
      );
      expect(commit.mock.calls).toEqual([
        ['setConversationUIFlag', { isCreating: true }],
        [
          'pushMessageToConversation',
          { id: 1, content: 'This is a test message' },
        ],
        ['setConversationUIFlag', { isCreating: false }],
      ]);
      windowSpy.mockRestore();
    });
  });

  describe('#addOrUpdateMessage', () => {
    it('sends correct actions for non-deleted message', () => {
      actions.addOrUpdateMessage(
        { commit },
        {
          id: 1,
          content: 'Hey',
          content_attributes: {},
        }
      );
      expect(commit).toBeCalledWith('pushMessageToConversation', {
        id: 1,
        content: 'Hey',
        content_attributes: {},
      });
    });
    it('sends correct actions for non-deleted message', () => {
      actions.addOrUpdateMessage(
        { commit },
        {
          id: 1,
          content: 'Hey',
          content_attributes: { deleted: true },
        }
      );
      expect(commit).toBeCalledWith('deleteMessage', 1);
    });

    it('plays audio when agent sends a message', () => {
      actions.addOrUpdateMessage({ commit }, { id: 1, message_type: 1 });
      expect(commit).toBeCalledWith('pushMessageToConversation', {
        id: 1,
        message_type: 1,
      });
    });
  });

  describe('#toggleAgentTyping', () => {
    it('sends correct mutations', () => {
      actions.toggleAgentTyping({ commit }, { status: true });
      expect(commit).toBeCalledWith('toggleAgentTypingStatus', {
        status: true,
      });
    });
  });

  describe('#sendMessage', () => {
    it('sends correct mutations', async () => {
      const mockDate = new Date(1466424490000);
      getUuid.mockImplementationOnce(() => '1111');
      const spy = vi.spyOn(global, 'Date').mockImplementation(() => mockDate);
      const windowSpy = vi.spyOn(window, 'window', 'get');
      windowSpy.mockImplementation(() => ({
        WOOT_WIDGET: {
          $root: {
            $i18n: {
              locale: 'ar',
            },
          },
        },
        location: {
          search: '?param=1',
        },
      }));
      const state = { pendingCustomAttributes: {}, pendingLabels: [] };
      await actions.sendMessage(
        { commit, dispatch, state },
        { content: 'hello', replyTo: 124 }
      );
      spy.mockRestore();
      windowSpy.mockRestore();
      expect(dispatch).toBeCalledWith('sendMessageWithData', {
        message: {
          attachments: undefined,
          content: 'hello',
          created_at: 1466424490,
          id: '1111',
          message_type: 0,
          replyTo: 124,
          status: 'in_progress',
        },
        pendingCustomAttributes: {},
        pendingLabels: [],
      });
    });

    it('includes pending metadata when available', async () => {
      const mockDate = new Date(1466424490000);
      getUuid.mockImplementationOnce(() => '2222');
      const spy = vi.spyOn(global, 'Date').mockImplementation(() => mockDate);
      const state = {
        pendingCustomAttributes: { plan: 'enterprise' },
        pendingLabels: ['vip'],
      };
      await actions.sendMessage(
        { commit, dispatch, state },
        { content: 'hello' }
      );
      spy.mockRestore();
      expect(dispatch).toBeCalledWith('sendMessageWithData', {
        message: expect.objectContaining({ content: 'hello' }),
        pendingCustomAttributes: { plan: 'enterprise' },
        pendingLabels: ['vip'],
      });
    });
  });

  describe('#sendMessageWithData', () => {
    const mockWindow = () =>
      vi.spyOn(window, 'window', 'get').mockImplementation(() => ({
        WOOT_WIDGET: { $root: { $i18n: { locale: 'en' } } },
        location: { search: '' },
      }));

    it('drops the old thread when the server replies with a different conversation', async () => {
      API.post.mockResolvedValue({
        data: { id: 2, content: 'hello', conversation_id: 99 },
      });
      const windowSpy = mockWindow();
      const state = { conversations: { 1: { id: 1, conversation_id: 55 } } };

      await actions.sendMessageWithData(
        { commit, dispatch, state, rootState: rootStateWith(55) },
        { message: { id: 'temp', content: 'hello' } }
      );
      windowSpy.mockRestore();

      expect(commit).toBeCalledWith('deleteMessage', 1);
      expect(dispatch).toBeCalledWith(
        'conversationAttributes/getAttributes',
        {},
        { root: true }
      );
      expect(dispatch).toBeCalledWith('fetchOldConversations');
    });

    it('replaces the failed message when the retry succeeds', async () => {
      API.post.mockResolvedValue({
        data: { id: 2, content: 'hello', message_type: 0, conversation_id: 55 },
      });
      const windowSpy = mockWindow();
      const state = {
        conversations: {
          temp: {
            id: 'temp',
            content: 'hello',
            message_type: 0,
            status: 'failed',
          },
        },
      };
      const applyMutation = (type, payload) => mutations[type](state, payload);

      await actions.sendMessageWithData(
        {
          commit: applyMutation,
          dispatch,
          state,
          rootState: rootStateWith(55),
        },
        { message: state.conversations.temp }
      );
      windowSpy.mockRestore();

      expect(Object.keys(state.conversations)).toEqual(['2']);
    });

    it('keeps messages already received for the new conversation', async () => {
      API.post.mockResolvedValue({
        data: { id: 2, content: 'hello', conversation_id: 99 },
      });
      const windowSpy = mockWindow();
      const state = {
        conversations: {
          1: { id: 1, conversation_id: 55 },
          77: { id: 77, content: 'greeting', conversation_id: 99 },
          temp: { id: 'temp', content: 'hello' },
        },
      };

      await actions.sendMessageWithData(
        { commit, dispatch, state, rootState: rootStateWith(55) },
        { message: { id: 'temp', content: 'hello' } }
      );
      windowSpy.mockRestore();

      expect(commit).toBeCalledWith('deleteMessage', 1);
      expect(commit).not.toBeCalledWith('deleteMessage', 77);
      expect(commit).not.toBeCalledWith('deleteMessage', 'temp');
    });

    it('refreshes when the attributes are stale and there is nothing to drop', async () => {
      API.post.mockResolvedValue({
        data: { id: 2, content: 'hello', conversation_id: 99 },
      });
      const windowSpy = mockWindow();
      const state = { conversations: {} };

      await actions.sendMessageWithData(
        { commit, dispatch, state, rootState: rootStateWith(55) },
        { message: { id: 'temp', content: 'hello' } }
      );
      windowSpy.mockRestore();

      expect(dispatch).toBeCalledWith(
        'conversationAttributes/getAttributes',
        {},
        { root: true }
      );
      expect(dispatch).toBeCalledWith('fetchOldConversations');
    });

    it('lets the replacement thread page back to older messages', async () => {
      API.post.mockResolvedValue({
        data: { id: 2, content: 'hello', conversation_id: 99 },
      });
      const windowSpy = mockWindow();
      const state = { conversations: { 1: { id: 1, conversation_id: 55 } } };
      const localCommit = vi.fn();

      await actions.sendMessageWithData(
        { commit: localCommit, dispatch, state, rootState: rootStateWith(55) },
        { message: { id: 'temp', content: 'hello' } }
      );
      windowSpy.mockRestore();

      expect(localCommit).toBeCalledWith('setConversationUIFlag', {
        allMessagesLoaded: false,
      });
    });

    it('drops old thread messages that arrive while the attributes refresh', async () => {
      API.post.mockResolvedValue({
        data: { id: 2, content: 'hello', conversation_id: 99 },
      });
      const windowSpy = mockWindow();
      const state = { conversations: { 1: { id: 1, conversation_id: 55 } } };
      const localCommit = vi.fn();
      const localDispatch = vi.fn(action => {
        if (action === 'conversationAttributes/getAttributes') {
          state.conversations[3] = { id: 3, conversation_id: 55 };
        }
        return Promise.resolve();
      });

      await actions.sendMessageWithData(
        {
          commit: localCommit,
          dispatch: localDispatch,
          state,
          rootState: rootStateWith(55),
        },
        { message: { id: 'temp', content: 'hello' } }
      );
      windowSpy.mockRestore();

      expect(localCommit).toBeCalledWith('deleteMessage', 3);
    });

    it('ignores a late response from a superseded conversation', async () => {
      API.post.mockResolvedValue({
        data: { id: 2, content: 'hello', conversation_id: 55 },
      });
      const windowSpy = mockWindow();
      // the widget has already switched to conversation 99
      const state = { conversations: { 1: { id: 1, conversation_id: 99 } } };
      const localCommit = vi.fn();
      const localDispatch = vi.fn(() => Promise.resolve());

      await actions.sendMessageWithData(
        {
          commit: localCommit,
          dispatch: localDispatch,
          state,
          rootState: rootStateWith(99),
        },
        { message: { id: 'temp', content: 'hello' } }
      );
      windowSpy.mockRestore();

      expect(localCommit).not.toBeCalledWith('deleteMessage', 1);
      expect(localDispatch).not.toBeCalledWith(
        'conversationAttributes/getAttributes',
        {},
        { root: true }
      );
      expect(localDispatch).not.toBeCalledWith('fetchOldConversations');
      // the response itself stays out of the thread on screen
      expect(localCommit).not.toBeCalledWith('pushMessageToConversation', {
        id: 2,
        content: 'hello',
        conversation_id: 55,
        status: 'sent',
      });
      expect(localCommit).toBeCalledWith('deleteMessage', 'temp');
    });

    it('keeps the thread when the message lands in the same conversation', async () => {
      API.post.mockResolvedValue({
        data: { id: 2, content: 'hello', conversation_id: 55 },
      });
      const windowSpy = mockWindow();
      const state = { conversations: { 1: { id: 1, conversation_id: 55 } } };

      await actions.sendMessageWithData(
        { commit, dispatch, state, rootState: rootStateWith(55) },
        { message: { id: 'temp', content: 'hello' } }
      );
      windowSpy.mockRestore();

      expect(commit).not.toBeCalledWith('deleteMessage', 1);
      expect(commit).toBeCalledWith('pushMessageToConversation', {
        id: 2,
        content: 'hello',
        conversation_id: 55,
        status: 'sent',
      });
    });
  });

  describe('#sendAttachment', () => {
    it('sends correct mutations', () => {
      const mockDate = new Date(1466424490000);
      getUuid.mockImplementationOnce(() => '1111');
      const spy = vi.spyOn(global, 'Date').mockImplementation(() => mockDate);
      const thumbUrl = '';
      const attachment = { thumbUrl, fileType: 'file' };
      const state = {
        conversations: {},
        pendingCustomAttributes: {},
        pendingLabels: [],
      };

      actions.sendAttachment(
        { commit, dispatch, state, rootState: rootStateWith(55) },
        { attachment, replyTo: 135 }
      );
      spy.mockRestore();
      expect(commit).toBeCalledWith('pushMessageToConversation', {
        id: '1111',
        content: undefined,
        status: 'in_progress',
        created_at: 1466424490,
        message_type: 0,
        replyTo: 135,
        attachments: [
          {
            thumb_url: '',
            data_url: '',
            file_type: 'file',
            status: 'in_progress',
          },
        ],
      });
    });

    it('drops the old thread when the server replies with a different conversation', async () => {
      API.post.mockResolvedValue({
        data: { id: 2, conversation_id: 99 },
      });
      const windowSpy = vi
        .spyOn(window, 'window', 'get')
        .mockImplementation(() => ({
          WOOT_WIDGET: { $root: { $i18n: { locale: 'en' } } },
          location: { search: '' },
        }));
      const state = {
        conversations: { 1: { id: 1, conversation_id: 55 } },
        pendingCustomAttributes: {},
        pendingLabels: [],
      };

      await actions.sendAttachment(
        { commit, dispatch, state, rootState: rootStateWith(55) },
        {
          attachment: {
            thumbUrl: '',
            fileType: 'file',
            file: 'data:image/png',
          },
        }
      );
      windowSpy.mockRestore();

      expect(commit).toBeCalledWith('deleteMessage', 1);
      expect(dispatch).toBeCalledWith(
        'conversationAttributes/getAttributes',
        {},
        { root: true }
      );
    });
  });

  describe('#setUserLastSeen', () => {
    it('sends correct mutations', async () => {
      API.post.mockResolvedValue({ data: { success: true } });
      await actions.setUserLastSeen({
        commit,
        getters: { getConversationSize: 2 },
      });
      expect(commit.mock.calls[0][0]).toEqual('setMetaUserLastSeenAt');
    });
    it('sends correct mutations', async () => {
      API.post.mockResolvedValue({ data: { success: true } });
      await actions.setUserLastSeen({
        commit,
        getters: { getConversationSize: 0 },
      });
      expect(commit.mock.calls).toEqual([]);
    });
  });

  describe('#setCustomAttributes', () => {
    it('queues to pending state when no conversation exists', async () => {
      const rootGetters = {
        'conversationAttributes/getConversationParams': { id: '' },
      };
      await actions.setCustomAttributes(
        { commit, rootGetters },
        { plan: 'enterprise' }
      );
      expect(commit).toBeCalledWith('setPendingCustomAttributes', {
        plan: 'enterprise',
      });
    });

    it('calls API when conversation exists', async () => {
      API.post.mockResolvedValue({ data: {} });
      const rootGetters = {
        'conversationAttributes/getConversationParams': { id: 123 },
      };
      await actions.setCustomAttributes(
        { commit, rootGetters },
        { plan: 'enterprise' }
      );
      expect(commit).not.toBeCalledWith(
        'setPendingCustomAttributes',
        expect.anything()
      );
    });
  });

  describe('#deleteCustomAttribute', () => {
    it('removes from pending state when no conversation exists', async () => {
      const rootGetters = {
        'conversationAttributes/getConversationParams': { id: '' },
      };
      await actions.deleteCustomAttribute({ commit, rootGetters }, 'plan');
      expect(commit).toBeCalledWith('removePendingCustomAttribute', 'plan');
    });

    it('calls API when conversation exists', async () => {
      API.post.mockResolvedValue({ data: {} });
      const rootGetters = {
        'conversationAttributes/getConversationParams': { id: 123 },
      };
      await actions.deleteCustomAttribute({ commit, rootGetters }, 'plan');
      expect(commit).not.toBeCalledWith(
        'removePendingCustomAttribute',
        expect.anything()
      );
    });
  });

  describe('#clearConversations', () => {
    it('sends correct mutations', () => {
      actions.clearConversations({ commit });
      expect(commit).toBeCalledWith('clearConversations');
    });
  });

  describe('#fetchOldConversations', () => {
    it('sends correct actions', async () => {
      API.get.mockResolvedValue({
        data: {
          payload: [
            {
              id: 1,
              text: 'hey',
              content_attributes: {},
            },
            {
              id: 2,
              text: 'welcome',
              content_attributes: { deleted: true },
            },
          ],
          meta: {
            contact_last_seen_at: 1466424490,
          },
        },
      });
      await actions.fetchOldConversations({ commit }, {});
      expect(commit.mock.calls).toEqual([
        ['setConversationListLoading', true],
        ['conversation/setMetaUserLastSeenAt', 1466424490, { root: true }],
        [
          'setMessagesInConversation',
          [
            {
              id: 1,
              text: 'hey',
              content_attributes: {},
            },
          ],
        ],
        ['setConversationListLoading', false],
      ]);
    });

    it('cancels a history request that a thread switch supersedes', async () => {
      let signal;
      API.get.mockImplementationOnce(
        (url, config) =>
          new Promise(() => {
            signal = config.signal;
          })
      );
      actions.fetchOldConversations({ commit }, {});
      await Promise.resolve();
      expect(signal.aborted).toBe(false);

      API.post.mockResolvedValue({
        data: { id: 2, content: 'hello', conversation_id: 99 },
      });
      const windowSpy = vi
        .spyOn(window, 'window', 'get')
        .mockImplementation(() => ({
          WOOT_WIDGET: { $root: { $i18n: { locale: 'en' } } },
          location: { search: '' },
        }));
      await actions.sendMessageWithData(
        {
          commit,
          dispatch,
          state: { conversations: {} },
          rootState: rootStateWith(55),
        },
        { message: { id: 'temp', content: 'hello' } }
      );
      windowSpy.mockRestore();

      expect(signal.aborted).toBe(true);
    });

    it('cancels an earlier read when a second one starts', async () => {
      const signals = [];
      API.get.mockImplementation(
        (url, config) =>
          new Promise(() => {
            signals.push(config.signal);
          })
      );
      actions.fetchOldConversations({ commit }, {});
      actions.fetchOldConversations({ commit }, {});
      await Promise.resolve();

      expect(signals).toHaveLength(2);
      expect(signals[0].aborted).toBe(true);
      expect(signals[1].aborted).toBe(false);
    });

    it('cancels a reconnect sync that a thread switch supersedes', async () => {
      let signal;
      API.get.mockImplementationOnce(
        (url, config) =>
          new Promise(() => {
            signal = config.signal;
          })
      );
      actions.syncLatestMessages({
        state: { lastMessageId: 1, conversations: {} },
        commit,
      });
      await Promise.resolve();
      expect(signal.aborted).toBe(false);

      API.post.mockResolvedValue({
        data: { id: 2, content: 'hello', conversation_id: 99 },
      });
      const windowSpy = vi
        .spyOn(window, 'window', 'get')
        .mockImplementation(() => ({
          WOOT_WIDGET: { $root: { $i18n: { locale: 'en' } } },
          location: { search: '' },
        }));
      await actions.sendMessageWithData(
        {
          commit,
          dispatch,
          state: { conversations: {} },
          rootState: rootStateWith(55),
        },
        { message: { id: 'temp', content: 'hello' } }
      );
      windowSpy.mockRestore();

      expect(signal.aborted).toBe(true);
    });
  });

  describe('#syncLatestMessages', () => {
    it('latest message should append to end of list', async () => {
      const state = {
        uiFlags: { allMessagesLoaded: false },
        conversations: {
          454: {
            id: 454,
            content: 'hi',
            message_type: 0,
            content_type: 'text',
            content_attributes: {},
            created_at: 1682244355, //  Sunday, 23 April 2023 10:05:55
            conversation_id: 20,
          },
          463: {
            id: 463,
            content: 'ss',
            message_type: 0,
            content_type: 'text',
            content_attributes: {},
            created_at: 1682490729, // Wednesday, 26 April 2023 06:32:09
            conversation_id: 20,
          },
        },
        lastMessageId: 463,
      };
      API.get.mockResolvedValue({
        data: {
          payload: [
            {
              id: 465,
              content: 'hi',
              message_type: 0,
              content_type: 'text',
              content_attributes: {},
              created_at: 1682504326, // Wednesday, 26 April 2023 10:18:46
              conversation_id: 20,
            },
          ],
          meta: {
            contact_last_seen_at: 1466424490,
          },
        },
      });
      await actions.syncLatestMessages({ state, commit }, {});
      expect(commit.mock.calls).toEqual([
        ['conversation/setMetaUserLastSeenAt', 1466424490, { root: true }],
        [
          'setMissingMessagesInConversation',

          {
            454: {
              id: 454,
              content: 'hi',
              message_type: 0,
              content_type: 'text',
              content_attributes: {},
              created_at: 1682244355,
              conversation_id: 20,
            },
            463: {
              id: 463,
              content: 'ss',
              message_type: 0,
              content_type: 'text',
              content_attributes: {},
              created_at: 1682490729,
              conversation_id: 20,
            },
            465: {
              id: 465,
              content: 'hi',
              message_type: 0,
              content_type: 'text',
              content_attributes: {},
              created_at: 1682504326,
              conversation_id: 20,
            },
          },
        ],
      ]);
    });

    it('old message should insert to exact position', async () => {
      const state = {
        uiFlags: { allMessagesLoaded: false },
        conversations: {
          454: {
            id: 454,
            content: 'hi',
            message_type: 0,
            content_type: 'text',
            content_attributes: {},
            created_at: 1682244355, //  Sunday, 23 April 2023 10:05:55
            conversation_id: 20,
          },
          463: {
            id: 463,
            content: 'ss',
            message_type: 0,
            content_type: 'text',
            content_attributes: {},
            created_at: 1682490729, // Wednesday, 26 April 2023 06:32:09
            conversation_id: 20,
          },
        },
        lastMessageId: 463,
      };
      API.get.mockResolvedValue({
        data: {
          payload: [
            {
              id: 460,
              content: 'Hi how are you',
              message_type: 0,
              content_type: 'text',
              content_attributes: {},
              created_at: 1682417926, // Tuesday, 25 April 2023 10:18:46
              conversation_id: 20,
            },
          ],
          meta: {
            contact_last_seen_at: 14664223490,
          },
        },
      });
      await actions.syncLatestMessages({ state, commit }, {});

      expect(commit.mock.calls).toEqual([
        ['conversation/setMetaUserLastSeenAt', 14664223490, { root: true }],
        [
          'setMissingMessagesInConversation',

          {
            454: {
              id: 454,
              content: 'hi',
              message_type: 0,
              content_type: 'text',
              content_attributes: {},
              created_at: 1682244355,
              conversation_id: 20,
            },
            460: {
              id: 460,
              content: 'Hi how are you',
              message_type: 0,
              content_type: 'text',
              content_attributes: {},
              created_at: 1682417926,
              conversation_id: 20,
            },
            463: {
              id: 463,
              content: 'ss',
              message_type: 0,
              content_type: 'text',
              content_attributes: {},
              created_at: 1682490729,
              conversation_id: 20,
            },
          },
        ],
      ]);
    });

    it('abort syncing if there is no missing messages ', async () => {
      const state = {
        uiFlags: { allMessagesLoaded: false },
        conversation: {
          454: {
            id: 454,
            content: 'hi',
            message_type: 0,
            content_type: 'text',
            content_attributes: {},
            created_at: 1682244355, //  Sunday, 23 April 2023 10:05:55
            conversation_id: 20,
          },
          463: {
            id: 463,
            content: 'ss',
            message_type: 0,
            content_type: 'text',
            content_attributes: {},
            created_at: 1682490729, // Wednesday, 26 April 2023 06:32:09
            conversation_id: 20,
          },
        },
        lastMessageId: 463,
      };
      API.get.mockResolvedValue({
        data: {
          payload: [],
          meta: {
            contact_last_seen_at: 14664223490,
          },
        },
      });
      await actions.syncLatestMessages({ state, commit }, {});

      expect(commit.mock.calls).toEqual([]);
    });
  });
});
