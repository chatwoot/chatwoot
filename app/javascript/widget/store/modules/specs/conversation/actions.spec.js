import { playNotificationAudio } from 'shared/helpers/AudioNotificationHelper';
import { actions } from '../../conversation/actions';
import getUuid from '../../../../helpers/uuid';
import { API } from 'widget/helpers/axios';

jest.mock('../../../../helpers/uuid');
jest.mock('shared/helpers/AudioNotificationHelper', () => ({
  playNotificationAudio: jest.fn(),
}));
jest.mock('widget/helpers/axios');

const commit = jest.fn();

describe('#actions', () => {
  describe('#addMessage', () => {
    it('sends correct mutations', () => {
      actions.addMessage({ commit }, { id: 1 });
      expect(commit).toBeCalledWith('pushMessageToConversation', { id: 1 });
    });

    it('plays audio when agent sends a message', () => {
      actions.addMessage({ commit }, { id: 1, message_type: 1 });
      expect(playNotificationAudio).toBeCalled();
      expect(commit).toBeCalledWith('pushMessageToConversation', {
        id: 1,
        message_type: 1,
      });
    });
  });

  describe('#createConversation', () => {
    it('sends correct mutations', async () => {
      API.post.mockResolvedValue({
        data: {
          contact: { name: 'contact-name' },
          messages: [{ id: 1, content: 'This is a test message' }],
        },
      });
      let windowSpy = jest.spyOn(window, 'window', 'get');
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

  describe('#updateMessage', () => {
    it('sends correct mutations', () => {
      actions.updateMessage({ commit }, { id: 1 });
      expect(commit).toBeCalledWith('pushMessageToConversation', { id: 1 });
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
    it('sends correct mutations', () => {
      const mockDate = new Date(1466424490000);
      getUuid.mockImplementationOnce(() => '1111');
      const spy = jest.spyOn(global, 'Date').mockImplementation(() => mockDate);
      const windowSpy = jest.spyOn(window, 'window', 'get');
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
      actions.sendMessage({ commit }, { content: 'hello' });
      spy.mockRestore();
      windowSpy.mockRestore();
      expect(commit).toBeCalledWith('pushMessageToConversation', {
        id: '1111',
        content: 'hello',
        status: 'in_progress',
        created_at: 1466424490,
        message_type: 0,
      });
    });
  });

  describe('#sendAttachment', () => {
    it('sends correct mutations', () => {
      const mockDate = new Date(1466424490000);
      getUuid.mockImplementationOnce(() => '1111');
      const spy = jest.spyOn(global, 'Date').mockImplementation(() => mockDate);
      const thumbUrl = '';
      const attachment = { thumbUrl, fileType: 'file' };

      actions.sendAttachment({ commit }, { attachment });
      spy.mockRestore();
      expect(commit).toBeCalledWith('pushMessageToConversation', {
        id: '1111',
        content: undefined,
        status: 'in_progress',
        created_at: 1466424490,
        message_type: 0,
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
});
