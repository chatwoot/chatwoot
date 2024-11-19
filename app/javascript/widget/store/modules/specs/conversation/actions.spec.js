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
      await actions.sendMessage(
        { commit, dispatch },
        { content: 'hello', replyTo: 124 }
      );
      spy.mockRestore();
      windowSpy.mockRestore();
      expect(dispatch).toBeCalledWith('sendMessageWithData', {
        attachments: undefined,
        content: 'hello',
        created_at: 1466424490,
        id: '1111',
        message_type: 0,
        replyTo: 124,
        status: 'in_progress',
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

      actions.sendAttachment(
        { commit, dispatch },
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
});
