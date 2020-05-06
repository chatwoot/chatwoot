import { playNotificationAudio } from 'shared/helpers/AudioNotificationHelper';
import { actions } from '../../conversation';
import getUuid from '../../../../helpers/uuid';

jest.mock('../../../../helpers/uuid');
jest.mock('shared/helpers/AudioNotificationHelper', () => ({
  playNotificationAudio: jest.fn(),
}));

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
      actions.sendMessage({ commit }, { content: 'hello' });
      spy.mockRestore();
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
});
