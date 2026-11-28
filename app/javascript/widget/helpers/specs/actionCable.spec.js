import { describe, it, beforeEach, afterEach, expect, vi } from 'vitest';
import ActionCableConnector from '../actionCable';

vi.mock('@rails/actioncable', () => ({
  createConsumer: () => ({
    subscriptions: { create: () => ({}) },
    disconnect: vi.fn(),
  }),
}));

describe('Widget ActionCableConnector', () => {
  let app;
  let mockDispatch;
  let connector;

  beforeEach(() => {
    vi.useFakeTimers();
    mockDispatch = vi.fn();
    app = {
      $store: {
        dispatch: mockDispatch,
        getters: {
          getCurrentAccountId: 1,
          getCurrentUserID: 1,
          'conversationAttributes/getConversationParams': { id: 7 },
        },
      },
    };
    connector = new ActionCableConnector(app, 'test-token');
    mockDispatch.mockClear();
  });

  afterEach(() => {
    vi.clearAllMocks();
    vi.useRealTimers();
  });

  it('registers the conversation.status_changed event handler', () => {
    expect(connector.events['conversation.status_changed']).toBe(
      connector.onStatusChange
    );
  });

  it('re-fetches conversation attributes on reconnect so a status change missed while disconnected is reflected', () => {
    connector.onReconnect();

    expect(mockDispatch).toHaveBeenCalledWith(
      'conversation/syncLatestMessages'
    );
    expect(mockDispatch).toHaveBeenCalledWith(
      'conversationAttributes/getAttributes'
    );
  });

  describe('typing off', () => {
    it('dismisses the typing indicator when an agent or bot explicitly stops typing', () => {
      connector.onTypingOff({ conversation: { id: 7 }, is_private: false });

      expect(mockDispatch).toHaveBeenCalledWith(
        'conversation/toggleAgentTyping',
        { status: 'off', dismiss: true }
      );
    });

    it('does not dismiss it when typing only timed out', () => {
      connector.onTypingOn({ conversation: { id: 7 }, is_private: false });
      mockDispatch.mockClear();

      vi.advanceTimersByTime(30000);

      expect(mockDispatch).toHaveBeenCalledWith(
        'conversation/toggleAgentTyping',
        { status: 'off', dismiss: false }
      );
    });

    it('dismisses it while the active conversation id is still loading', () => {
      app.$store.getters['conversationAttributes/getConversationParams'] = {
        id: '',
      };

      connector.onTypingOff({ conversation: { id: 7 }, is_private: false });

      expect(mockDispatch).toHaveBeenCalledWith(
        'conversation/toggleAgentTyping',
        { status: 'off', dismiss: true }
      );
    });

    it('does not dismiss it for a private note or another conversation', () => {
      connector.onTypingOff({ conversation: { id: 7 }, is_private: true });
      connector.onTypingOff({ conversation: { id: 8 }, is_private: false });

      expect(mockDispatch).toHaveBeenNthCalledWith(
        1,
        'conversation/toggleAgentTyping',
        { status: 'off', dismiss: false }
      );
      expect(mockDispatch).toHaveBeenNthCalledWith(
        2,
        'conversation/toggleAgentTyping',
        { status: 'off', dismiss: false }
      );
    });
  });
});
