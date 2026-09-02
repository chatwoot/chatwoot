import { describe, expect, it, vi } from 'vitest';

import App from '../App.vue';

const handleInitialMessage = App.methods.handleInitialMessage;
const handleSetUser = App.methods.handleSetUser;
const setConversationHistoryFetchPromise =
  App.methods.setConversationHistoryFetchPromise;

const buildContext = ({
  conversationSize = 0,
  initialConversationFetchPromise = null,
  pendingInitialMessage = '',
  routeName = 'home',
  shouldShowPreChatForm = false,
} = {}) => ({
  conversationSize,
  initialConversationFetchPromise,
  initialMessageSequence: 0,
  pendingInitialMessage,
  shouldShowPreChatForm,
  handleInitialMessage: vi.fn(),
  setInitialMessage: vi.fn(),
  unsetUnreadView: vi.fn(),
  setConversationHistoryFetchPromise: vi.fn(),
  $store: { dispatch: vi.fn() },
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
    expect(context.pendingInitialMessage).toBe('');
    expect(context.router.replace).toHaveBeenCalledWith({ name: 'messages' });
  });

  it('routes before publishing the initial message draft', async () => {
    const context = buildContext({
      shouldShowPreChatForm: true,
    });

    await handleInitialMessage.call(context, 'Need help with this item');

    expect(context.router.replace).toHaveBeenCalledWith({
      name: 'prechat-form',
    });
    expect(context.router.replace.mock.invocationCallOrder[0]).toBeLessThan(
      context.setInitialMessage.mock.invocationCallOrder[0]
    );
  });

  it('clears unread mode before showing the message composer', async () => {
    const context = buildContext({
      conversationSize: 1,
    });

    await handleInitialMessage.call(context, 'Need help with this item');

    expect(context.unsetUnreadView).toHaveBeenCalled();
    expect(context.router.replace).toHaveBeenCalledWith({ name: 'messages' });
    expect(context.unsetUnreadView.mock.invocationCallOrder[0]).toBeLessThan(
      context.router.replace.mock.invocationCallOrder[0]
    );
    expect(context.router.replace.mock.invocationCallOrder[0]).toBeLessThan(
      context.setInitialMessage.mock.invocationCallOrder[0]
    );
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

  it('cancels a pending initial message when the sequence is invalidated', async () => {
    let resolveHistory;
    const initialConversationFetchPromise = new Promise(resolve => {
      resolveHistory = resolve;
    });
    const context = buildContext({ initialConversationFetchPromise });

    const result = handleInitialMessage.call(context, 'Old draft');
    context.initialMessageSequence += 1;
    resolveHistory();
    await result;

    expect(context.setInitialMessage).not.toHaveBeenCalled();
    expect(context.router.replace).not.toHaveBeenCalled();
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

  it('clears initial message drafts without routing for empty updates', async () => {
    const context = buildContext({
      pendingInitialMessage: 'Need help with this item',
    });

    await handleInitialMessage.call(context, '');

    expect(context.pendingInitialMessage).toBe('');
    expect(context.setInitialMessage).toHaveBeenCalledWith('');
    expect(context.router.replace).not.toHaveBeenCalled();
  });

  it('cancels pending initial messages with empty updates', async () => {
    let resolveHistory;
    const initialConversationFetchPromise = new Promise(resolve => {
      resolveHistory = resolve;
    });
    const context = buildContext({ initialConversationFetchPromise });

    const result = handleInitialMessage.call(context, 'Old draft');
    await Promise.resolve();
    await handleInitialMessage.call(context, '');

    resolveHistory();
    await result;

    expect(context.setInitialMessage).toHaveBeenCalledTimes(1);
    expect(context.setInitialMessage).toHaveBeenCalledWith('');
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

describe('App handleSetUser', () => {
  it('replays a pending initial message after the identified user history fetch', () => {
    const setUserPromise = Promise.resolve();
    const message = { identifier: 'visitor-1' };
    const context = buildContext({
      pendingInitialMessage: 'Need help with this item',
    });
    context.$store.dispatch.mockReturnValue(setUserPromise);

    handleSetUser.call(context, message);

    expect(context.initialMessageSequence).toBe(1);
    expect(context.$store.dispatch).toHaveBeenCalledWith(
      'contacts/setUser',
      message
    );
    expect(context.setConversationHistoryFetchPromise).toHaveBeenCalledWith(
      setUserPromise
    );
    expect(context.handleInitialMessage).toHaveBeenCalledWith(
      'Need help with this item'
    );
  });

  it('does not replay an initial message after it has already been published', () => {
    const context = buildContext();
    context.$store.dispatch.mockResolvedValue();

    handleSetUser.call(context, { identifier: 'visitor-1' });

    expect(context.handleInitialMessage).not.toHaveBeenCalled();
  });
});
