import { actions } from '../../conversation/actions';
import getUuid from '../../../../helpers/uuid';
import { API } from 'widget/helpers/axios';

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
        // dispatch is supplied because the action calls it; omitting it threw a
        // TypeError that the old catch-and-ignore hid, which is the very defect
        //  removes.
        { commit, dispatch },
        { contact: {}, message: 'This is a test message' }
      );
      expect(commit.mock.calls).toEqual([
        ['setConversationUIFlag', { isCreating: true, isCreateFailed: false }],
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

  describe('#sendAttachment', () => {
    it('sends correct mutations', () => {
      const mockDate = new Date(1466424490000);
      getUuid.mockImplementationOnce(() => '1111');
      const spy = vi.spyOn(global, 'Date').mockImplementation(() => mockDate);
      const thumbUrl = '';
      const attachment = { thumbUrl, fileType: 'file' };
      const state = { pendingCustomAttributes: {}, pendingLabels: [] };

      actions.sendAttachment(
        { commit, dispatch, state },
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

  // these two paths used to discard their errors entirely. Each test
  // below fails if the swallow is reintroduced.
  describe('#silent failure regressions', () => {
    beforeEach(() => {
      commit.mockClear();
      dispatch.mockClear();
    });

    it('createConversation flags the failure instead of discarding it', async () => {
      API.post.mockRejectedValue(new Error('network down'));
      await actions.createConversation(
        { commit, dispatch },
        { contact: {}, message: 'hi' }
      );

      const flags = commit.mock.calls
        .filter(([name]) => name === 'setConversationUIFlag')
        .map(([, payload]) => payload);

      expect(flags).toContainEqual(
        expect.objectContaining({ isCreateFailed: true })
      );
      // the loading flag must still be cleared, or the widget spins forever
      expect(flags).toContainEqual(
        expect.objectContaining({ isCreating: false })
      );
    });

    // The clear-on-retry path is covered by '#createConversation > sends correct
    // mutations' above, which now asserts the opening commit is
    // { isCreating: true, isCreateFailed: false }. A second test here would only
    // duplicate that, plus the window scaffolding it needs.
    it('syncLatestMessages flags the failure after every retry fails', async () => {
      API.get.mockRejectedValue(new Error('gateway'));
      const state = { lastMessageId: 1, conversations: {} };
      await actions.syncLatestMessages({ state, commit }, {});

      const flags = commit.mock.calls
        .filter(([name]) => name === 'setConversationUIFlag')
        .map(([, payload]) => payload);
      expect(flags).toContainEqual(
        expect.objectContaining({ isSyncFailed: true })
      );
      // Exactly the full retry budget: toBeGreaterThan(1) would also pass on a
      // single retry, so it would not catch the budget being cut.
      expect(API.get.mock.calls.length).toBe(3);
    });

    it('syncLatestMessages recovers on a retry and does not flag a failure', async () => {
      API.get
        .mockRejectedValueOnce(new Error('blip'))
        .mockResolvedValue({ data: { payload: [], meta: {} } });
      // start in the failed condition so the recovery is observable; a healthy
      // sync deliberately emits no state change at all
      const state = {
        lastMessageId: 1,
        conversations: {},
        uiFlags: { isSyncFailed: true },
      };
      await actions.syncLatestMessages({ state, commit }, {});

      const flags = commit.mock.calls
        .filter(([name]) => name === 'setConversationUIFlag')
        .map(([, payload]) => payload);
      expect(flags).not.toContainEqual(
        expect.objectContaining({ isSyncFailed: true })
      );
      expect(flags).toContainEqual(
        expect.objectContaining({ isSyncFailed: false })
      );
      // one failure then success: exactly two attempts, no more
      expect(API.get.mock.calls.length).toBe(2);
    });
  });
});
