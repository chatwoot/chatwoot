import { describe, expect, it, vi } from 'vitest';

import App from '../App.vue';

const handleInitialMessage = App.methods.handleInitialMessage;
const handleSetUser = App.methods.handleSetUser;
const setConversationHistoryFetchPromise =
  App.methods.setConversationHistoryFetchPromise;

const buildContext = ({
  conversationSize = 0,
  currentUser = {},
  initialMessage = '',
  initialConversationFetchPromise = null,
  latestUserIdentifier = '',
  pendingInitialMessage = '',
  preChatFormEnabled = false,
  routeName = 'home',
  shouldShowPreChatForm = false,
} = {}) => ({
  conversationSize,
  currentUser,
  initialMessage,
  initialConversationFetchPromise,
  initialMessageSequence: 0,
  latestUserIdentifier,
  pendingInitialMessage,
  preChatFormEnabled,
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
      preChatFormEnabled: true,
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
      preChatFormEnabled: true,
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

    expect(context.unsetUnreadView).toHaveBeenCalledTimes(2);
    expect(context.router.replace).toHaveBeenCalledWith({ name: 'messages' });
    expect(context.unsetUnreadView.mock.invocationCallOrder[0]).toBeLessThan(
      context.router.replace.mock.invocationCallOrder[0]
    );
    expect(context.router.replace.mock.invocationCallOrder[0]).toBeLessThan(
      context.setInitialMessage.mock.invocationCallOrder[0]
    );
    expect(context.setInitialMessage.mock.invocationCallOrder[0]).toBeLessThan(
      context.unsetUnreadView.mock.invocationCallOrder[1]
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
      preChatFormEnabled: true,
    });

    await handleInitialMessage.call(context, 'Need help with this item');

    expect(context.setInitialMessage).toHaveBeenCalledWith(
      'Need help with this item'
    );
    expect(context.router.replace).toHaveBeenCalledWith({
      name: 'prechat-form',
    });
  });

  it('routes pre-chat enabled inboxes to the form when optional fields are disabled', async () => {
    const context = buildContext({
      initialConversationFetchPromise: Promise.resolve(),
      preChatFormEnabled: true,
      shouldShowPreChatForm: false,
    });

    await handleInitialMessage.call(context, 'Need help with this item');

    expect(context.router.replace).toHaveBeenCalledWith({
      name: 'prechat-form',
    });
    expect(context.setInitialMessage).toHaveBeenCalledWith(
      'Need help with this item'
    );
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

  it('ignores non-string initial message updates', async () => {
    const context = buildContext({
      pendingInitialMessage: 'Need help with this item',
    });

    await handleInitialMessage.call(context, { message: 'Broken draft' });

    expect(context.pendingInitialMessage).toBe('Need help with this item');
    expect(context.initialMessageSequence).toBe(0);
    expect(context.setInitialMessage).not.toHaveBeenCalled();
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

  it('does not publish an initial message when the sequence changes while routing', async () => {
    let resolveNavigation;
    const routeNavigation = new Promise(resolve => {
      resolveNavigation = resolve;
    });
    const context = buildContext({
      conversationSize: 1,
    });
    context.router.replace.mockReturnValue(routeNavigation);

    const result = handleInitialMessage.call(context, 'Old draft');
    await Promise.resolve();
    context.initialMessageSequence += 1;
    resolveNavigation();
    await result;

    expect(context.setInitialMessage).not.toHaveBeenCalled();
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
    expect(context.latestUserIdentifier).toBe('visitor-1');
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

  it('replays a published initial message while identifying an anonymous visitor', () => {
    const context = buildContext({
      currentUser: {},
      initialMessage: 'Edited draft',
    });
    context.$store.dispatch.mockResolvedValue();

    handleSetUser.call(context, { identifier: 'visitor-1' });

    expect(context.handleInitialMessage).toHaveBeenCalledWith('Edited draft');
  });

  it('does not replay a published initial message when changing identified visitors', () => {
    const context = buildContext({
      currentUser: { identifier: 'visitor-1' },
      initialMessage: 'Previous visitor draft',
    });
    context.$store.dispatch.mockResolvedValue();

    handleSetUser.call(context, { identifier: 'visitor-2' });

    expect(context.handleInitialMessage).not.toHaveBeenCalled();
    expect(context.setInitialMessage).toHaveBeenCalledWith('');
  });

  it('replays a published initial message when refreshing the same identified visitor', () => {
    const context = buildContext({
      currentUser: { identifier: 'visitor-1' },
      initialMessage: 'Edited draft',
    });
    context.$store.dispatch.mockResolvedValue();

    handleSetUser.call(context, { identifier: 'visitor-1' });

    expect(context.handleInitialMessage).toHaveBeenCalledWith('Edited draft');
  });

  it('drops pending initial messages when changing identified visitors', () => {
    const context = buildContext({
      currentUser: { identifier: 'visitor-1' },
      pendingInitialMessage: 'Previous visitor draft',
    });
    context.$store.dispatch.mockResolvedValue();

    handleSetUser.call(context, { identifier: 'visitor-2' });

    expect(context.pendingInitialMessage).toBe('');
    expect(context.setInitialMessage).toHaveBeenCalledWith('');
    expect(context.handleInitialMessage).not.toHaveBeenCalled();
  });

  it('drops pending initial messages when switching visitors before contact refresh completes', () => {
    const context = buildContext({
      currentUser: {},
      latestUserIdentifier: 'visitor-1',
      pendingInitialMessage: 'Previous visitor draft',
    });
    context.$store.dispatch.mockResolvedValue();

    handleSetUser.call(context, { identifier: 'visitor-2' });

    expect(context.pendingInitialMessage).toBe('');
    expect(context.setInitialMessage).toHaveBeenCalledWith('');
    expect(context.handleInitialMessage).not.toHaveBeenCalled();
    expect(context.latestUserIdentifier).toBe('visitor-2');
  });

  it('does not replay an initial message after it has already been published', () => {
    const context = buildContext();
    context.$store.dispatch.mockResolvedValue();

    handleSetUser.call(context, { identifier: 'visitor-1' });

    expect(context.handleInitialMessage).not.toHaveBeenCalled();
  });
});
