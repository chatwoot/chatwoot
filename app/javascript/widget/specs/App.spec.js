import { describe, expect, it, vi } from 'vitest';

import App from '../App.vue';

const handleInitialMessage = App.methods.handleInitialMessage;

const buildContext = ({
  conversationSize = 0,
  initialConversationFetchPromise = null,
  routeName = 'home',
  shouldShowPreChatForm = false,
} = {}) => ({
  conversationSize,
  initialConversationFetchPromise,
  shouldShowPreChatForm,
  setInitialMessage: vi.fn(),
  $route: { name: routeName },
  router: { replace: vi.fn() },
});

describe('App handleInitialMessage', () => {
  it('waits for the initial conversation history fetch before choosing a route', async () => {
    let resolveHistory;
    const initialConversationFetchPromise = new Promise(resolve => {
      resolveHistory = resolve;
    });
    const context = buildContext({
      conversationSize: 0,
      initialConversationFetchPromise,
      shouldShowPreChatForm: true,
    });

    const result = handleInitialMessage.call(
      context,
      'Need help with this item'
    );
    await Promise.resolve();

    expect(context.setInitialMessage).not.toHaveBeenCalled();
    expect(context.router.replace).not.toHaveBeenCalled();

    context.conversationSize = 1;
    resolveHistory();
    await result;

    expect(context.setInitialMessage).toHaveBeenCalledWith(
      'Need help with this item'
    );
    expect(context.router.replace).toHaveBeenCalledWith({ name: 'messages' });
  });

  it('routes new visitors to the pre-chat form when it is enabled', async () => {
    const context = buildContext({
      initialConversationFetchPromise: Promise.resolve(),
      shouldShowPreChatForm: true,
    });

    await handleInitialMessage.call(context, 'Need help with this item');

    expect(context.setInitialMessage).toHaveBeenCalledWith(
      'Need help with this item'
    );
    expect(context.router.replace).toHaveBeenCalledWith({
      name: 'prechat-form',
    });
  });

  it('ignores empty initial messages', async () => {
    const context = buildContext();

    await handleInitialMessage.call(context, '');

    expect(context.setInitialMessage).not.toHaveBeenCalled();
    expect(context.router.replace).not.toHaveBeenCalled();
  });
});
