import axios from 'axios';
import types from '../../../mutation-types';
import actions from '../../conversations/actions';
import { getMessageError } from 'dashboard/components-next/message/helpers/messageError';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';

global.axios = axios;
vi.mock('axios');

const pendingReply = () => ({
  id: 'temp-1',
  echo_id: 'temp-1',
  conversationId: 12,
  conversation_id: 12,
  message: 'Hello there',
  content: 'Hello there',
  private: false,
  status: 'progress',
  message_type: 1,
  created_at: 1700000000,
  attachments: null,
});

describe('#sendMessageWithData', () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it('marks a reply that failed on the network so the UI can explain it', async () => {
    axios.mockRejectedValue(new Error('Network Error'));
    const commit = vi.fn();

    await expect(
      actions.sendMessageWithData({ commit }, pendingReply())
    ).rejects.toThrow('Network Error');

    const failed = commit.mock.calls.at(-1)[1];
    expect(commit.mock.calls.at(-1)[0]).toBe(types.ADD_MESSAGE);
    expect(failed.status).toBe('failed');
    expect(
      getMessageError(useCamelCase(failed, { deep: true }), 'fallback')
    ).toBe('fallback');
  });

  it('re-creates the stored failed reply in the same conversation on retry', async () => {
    axios.mockResolvedValue({ data: { id: 99, conversation_id: 12 } });
    const commit = vi.fn();
    const storedFailedReply = {
      ...pendingReply(),
      status: 'failed',
      meta: { error: undefined },
    };

    await actions.sendMessageWithData({ commit }, storedFailedReply);

    expect(axios).toHaveBeenCalledWith(
      expect.objectContaining({
        method: 'post',
        url: expect.stringMatching(/\/conversations\/12\/messages$/),
        data: expect.objectContaining({
          content: 'Hello there',
          echo_id: 'temp-1',
        }),
      })
    );
    expect(commit).toHaveBeenCalledWith(
      types.ADD_MESSAGE,
      expect.objectContaining({ id: 99, status: 'sent' })
    );
  });

  it('keeps using the retry endpoint for a delivery failure reported by the server', async () => {
    axios.post.mockResolvedValue({ data: { id: 5, conversation_id: 12 } });
    const commit = vi.fn();

    await actions.sendMessageWithData(
      { commit },
      {
        id: 5,
        conversation_id: 12,
        status: 'failed',
        content_attributes: { external_error: 'Recipient blocked' },
      }
    );

    expect(axios.post).toHaveBeenCalledWith(
      expect.stringMatching(/\/conversations\/12\/messages\/5\/retry$/)
    );
    expect(axios).not.toHaveBeenCalled();
  });
});
