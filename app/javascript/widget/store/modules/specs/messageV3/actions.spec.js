import { actions } from '../../messageV3/actions';
import MessageAPI from 'widget/api/message';
import { sendMessageAPI, sendAttachmentAPI } from 'widget/api/conversationV3';

jest.mock('widget/api/message');
jest.mock('widget/api/conversationV3');

describe('messageV3/actions', () => {
  let commit;
  let dispatch;

  let mockFormData;
  const originalFormData = global.FormData;
  beforeEach(() => {
    commit = jest.fn();
    dispatch = jest.fn();

    mockFormData = {
      append: jest.fn(),
      get: jest.fn(),
      getAll: jest.fn(),
    };
    global.FormData = jest.fn(() => mockFormData);
  });

  afterEach(() => {
    jest.clearAllMocks();
    global.FormData = originalFormData; // restore original FormData
  });

  describe('addOrUpdate', () => {
    it('adds a message if its not present in store', async () => {
      const message = {
        conversation_id: '123',
        id: '456',
        echo_id: '789',
      };
      const getters = {
        messageById: jest.fn().mockReturnValueOnce(false),
      };
      await actions.addOrUpdate({ commit, getters }, message);

      expect(commit).toHaveBeenCalledTimes(3);
      expect(commit.mock.calls).toEqual([
        ['addMessagesEntry', { conversationId: '123', messages: [message] }],
        ['addMessageIds', { messages: [message] }],
        [
          'conversationV3/appendMessageIdsToConversation',
          { conversationId: message.conversation_id, messages: [message] },
          { root: true },
        ],
      ]);
    });
    it('updates a message if its not present in store', async () => {
      const message = {
        conversation_id: '123',
        id: '456',
        echo_id: '789',
      };
      const getters = {
        messageById: jest.fn().mockReturnValueOnce(true),
      };
      await actions.addOrUpdate({ commit, getters }, message);

      expect(commit).toHaveBeenCalledTimes(6);
      expect(commit.mock.calls).toEqual([
        [
          'conversationV3/removeMessageIdFromConversation',
          { conversationId: '123', messageId: '789' },
          { root: true },
        ],
        ['removeMessageEntry', '789'],
        ['removeMessageId', '789'],
        ['addMessagesEntry', { conversationId: '123', messages: [message] }],
        ['addMessageIds', { messages: [message] }],
        [
          'conversationV3/appendMessageIdsToConversation',
          { conversationId: message.conversation_id, messages: [message] },
          { root: true },
        ],
      ]);
    });
  });

  describe('sendMessageIn', () => {
    it('sends a message', async () => {
      const params = {
        content: 'hello',
        conversationId: '123',
      };

      sendMessageAPI.mockResolvedValue({ data: {} });

      await actions.sendMessageIn({ commit, dispatch }, params);

      expect(commit).toHaveBeenCalledTimes(5);
      expect(dispatch).toHaveBeenCalledTimes(1);
    });

    it('handles error while sending a message', async () => {
      const params = {
        content: 'hello',
        conversationId: '123',
      };

      sendMessageAPI.mockRejectedValue(new Error('Failed to send message'));

      await expect(
        actions.sendMessageIn({ commit, dispatch }, params)
      ).rejects.toThrow('Failed to send message');

      expect(commit).toHaveBeenCalledTimes(5);
      expect(dispatch).not.toHaveBeenCalled();
    });
  });

  describe('sendAttachmentIn', () => {
    beforeEach(() => {
      Object.defineProperty(window, 'referrerURL', {
        value: 'mocked_referrer_url',
        writable: true,
      });
    });

    it('sends an attachment correctly', async () => {
      const params = {
        attachment: {
          file: new File(['content'], 'filename.txt'),
          thumbUrl: 'url',
          fileType: 'image',
        },
        conversationId: '123',
      };

      sendAttachmentAPI.mockResolvedValue({ data: {} });

      await actions.sendAttachmentIn({ commit, dispatch }, params);

      expect(commit).toHaveBeenCalledTimes(5);
      expect(dispatch).toHaveBeenCalledTimes(1);

      expect(mockFormData.append).toHaveBeenCalledTimes(3);
      expect(mockFormData.append).toHaveBeenCalledWith(
        'message[attachments][]',
        params.attachment.file,
        params.attachment.file.name
      );
      expect(mockFormData.append).toHaveBeenCalledWith(
        'message[referer_url]',
        'mocked_referrer_url'
      );
      expect(typeof mockFormData.append.mock.calls[2][1]).toBe('string'); // This ensures timestamp was appended
    });

    it('handles error while sending an attachment', async () => {
      const params = {
        attachment: {
          file: new File(['content'], 'filename.txt'),
          thumbUrl: 'url',
          fileType: 'image',
        },
        conversationId: '123',
      };

      sendAttachmentAPI.mockRejectedValue(
        new Error('Failed to send attachment')
      );

      await expect(
        actions.sendAttachmentIn({ commit, dispatch }, params)
      ).rejects.toThrow('Failed to send attachment');

      expect(commit).toHaveBeenCalledTimes(5);
      expect(dispatch).not.toHaveBeenCalled();
    });
  });

  describe('update', () => {
    it('updates a message', async () => {
      const params = {
        email: 'test@example.com',
        messageId: '123',
        submittedValues: {},
      };

      MessageAPI.update.mockResolvedValue();

      await actions.update({ commit, dispatch }, params);

      expect(commit).toHaveBeenCalledTimes(3);
      expect(dispatch).toHaveBeenCalledTimes(1);
    });

    it('handles error while updating a message', async () => {
      const params = {
        email: 'test@example.com',
        messageId: '123',
        submittedValues: {},
      };

      MessageAPI.update.mockRejectedValue(
        new Error('Failed to update message')
      );

      await expect(
        actions.update({ commit, dispatch }, params)
      ).rejects.toThrow('Failed to update message');

      expect(commit).toHaveBeenCalledTimes(2);
      expect(dispatch).not.toHaveBeenCalled();
    });
  });
});
