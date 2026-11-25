import axios from 'axios';
import messagesModule from '../../internalChat/messages';

const { actions } = messagesModule;

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('#sendThreadReply', () => {
    it('sends a plain JSON payload when there are no files', async () => {
      axios.post.mockResolvedValue({ data: { id: 7, parent_id: 3 } });

      await actions.sendThreadReply(
        { commit },
        {
          channelId: 1,
          parentMessageId: 3,
          data: { content: 'hi', also_send_in_channel: false },
        }
      );

      const [, payload] = axios.post.mock.calls[0];
      expect(payload).toEqual({
        content: 'hi',
        also_send_in_channel: false,
        parent_id: 3,
      });
      expect(commit).toHaveBeenCalledWith('ADD_THREAD_REPLY', {
        parentMessageId: 3,
        reply: { id: 7, parent_id: 3 },
      });
    });

    it('sends multipart form data including the files when files are passed', async () => {
      axios.post.mockResolvedValue({ data: { id: 8, parent_id: 3 } });
      const file = new File(['png-bytes'], 'image.png', { type: 'image/png' });

      await actions.sendThreadReply(
        { commit },
        {
          channelId: 1,
          parentMessageId: 3,
          data: { content: '', also_send_in_channel: true },
          files: [file],
        }
      );

      const [, payload] = axios.post.mock.calls[0];
      expect(payload).toBeInstanceOf(FormData);
      expect(payload.getAll('attachments[][file]')).toEqual([file]);
      expect(payload.get('parent_id')).toBe('3');
      expect(payload.get('also_send_in_channel')).toBe('true');
      expect(payload.get('content')).toBeNull();
      expect(commit).toHaveBeenCalledWith('ADD_THREAD_REPLY', {
        parentMessageId: 3,
        reply: { id: 8, parent_id: 3 },
      });
    });

    it('adds the reply to the channel when also_send_in_channel is set on the response', async () => {
      axios.post.mockResolvedValue({
        data: {
          id: 9,
          parent_id: 3,
          content_attributes: { also_send_in_channel: true },
        },
      });

      await actions.sendThreadReply(
        { commit },
        {
          channelId: 1,
          parentMessageId: 3,
          data: { content: 'broadcast', also_send_in_channel: true },
        }
      );

      expect(commit).toHaveBeenCalledWith('ADD_MESSAGE', {
        channelId: 1,
        message: expect.objectContaining({ id: 9 }),
      });
    });
  });

  describe('#sendMessage', () => {
    it('sends multipart form data including the files when files are passed', async () => {
      axios.post.mockResolvedValue({ data: { id: 10 } });
      const file = new File(['png-bytes'], 'image.png', { type: 'image/png' });

      await actions.sendMessage(
        { commit },
        { channelId: 1, data: { content: 'hello' }, files: [file] }
      );

      const [, payload] = axios.post.mock.calls[0];
      expect(payload).toBeInstanceOf(FormData);
      expect(payload.getAll('attachments[][file]')).toEqual([file]);
      expect(payload.get('content')).toBe('hello');
      expect(commit).toHaveBeenCalledWith('ADD_MESSAGE', {
        channelId: 1,
        message: { id: 10 },
      });
    });
  });
});
