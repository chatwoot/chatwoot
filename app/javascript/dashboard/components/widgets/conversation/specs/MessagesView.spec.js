import MessagesView from '../MessagesView.vue';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';

const { handleMessageRetry } = MessagesView.methods;

describe('MessagesView#handleMessageRetry', () => {
  it('retries the stored message, not the camelCased list copy', async () => {
    const file = new File(['hi'], 'hi.txt', { type: 'text/plain' });
    const storedFailedReply = {
      id: 'temp-1',
      echo_id: 'temp-1',
      conversationId: 12,
      conversation_id: 12,
      message: 'Hello there',
      files: [file],
      status: 'failed',
      meta: { error: undefined },
    };
    const dispatch = vi.fn();
    const ctx = {
      currentChat: { messages: [storedFailedReply] },
      $store: { dispatch },
    };
    // MessageList hands the deep camelCased copy to the retry event.
    const listCopy = useCamelCase(storedFailedReply, { deep: true });

    await handleMessageRetry.call(ctx, listCopy);

    expect(dispatch).toHaveBeenCalledWith(
      'sendMessageWithData',
      storedFailedReply
    );
    expect(dispatch.mock.calls[0][1].files[0]).toBe(file);
  });

  it('falls back to the snake_cased copy when the message is not in the store', async () => {
    const dispatch = vi.fn();
    const ctx = { currentChat: { messages: [] }, $store: { dispatch } };

    await handleMessageRetry.call(ctx, {
      id: 5,
      conversationId: 12,
      contentAttributes: { externalError: 'Recipient blocked' },
    });

    expect(dispatch).toHaveBeenCalledWith('sendMessageWithData', {
      id: 5,
      conversation_id: 12,
      content_attributes: { external_error: 'Recipient blocked' },
    });
  });
});
