import { describe, expect, it, vi } from 'vitest';

import App from '../App.vue';

const handleInitialMessage = App.methods.handleInitialMessage;
const setConversationHistoryFetchPromise =
  App.methods.setConversationHistoryFetchPromise;

const buildContext = ({
  conversationSize = 0,
  initialConversationFetchPromise = null,
  routeName = 'home',
  shouldShowPreChatForm = false,
} = {}) => ({
  conversationSize,
  initialConversationFetchPromise,
  initialMessageSequence: 0,
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

  it('keeps the newest initial message while waiting for conversation history', async () => {
    let resolveHistory;
    const initialConversationFetchPromise = new Promise(resolve => {
      resolveHistory = resolve;
    });
    const context = buildContext({ initialConversationFetchPromise });

    const oldResult = handleInitialMessage.call(context, 'Old draft');
    const newResult = handleInitialMessage.call(context, 'New draft');

    resolveHistory();
    await Promise.all([oldResult, newResult]);

    expect(context.setInitialMessage).toHaveBeenCalledTimes(1);
    expect(context.setInitialMessage).toHaveBeenCalledWith('New draft');
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

describe('App setConversationHistoryFetchPromise', () => {
  it('clears only the latest tracked conversation history fetch', async () => {
    let resolveFirstFetch;
    let resolveSecondFetch;
    const firstFetch = new Promise(resolve => {
      resolveFirstFetch = resolve;
    });
    const secondFetch = new Promise(resolve => {
      resolveSecondFetch = resolve;
    });
    const context = buildContext();

    setConversationHistoryFetchPromise.call(context, firstFetch);
    setConversationHistoryFetchPromise.call(context, secondFetch);

    resolveFirstFetch();
    await firstFetch;
    await Promise.resolve();

    expect(context.initialConversationFetchPromise).toBe(secondFetch);

    resolveSecondFetch();
    await secondFetch;
    await Promise.resolve();

    expect(context.initialConversationFetchPromise).toBeNull();
  });
});
