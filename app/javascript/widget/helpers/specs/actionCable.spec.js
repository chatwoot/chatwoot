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

  it('replaces the live connector when the pubsub token rotates', () => {
    const disconnect = vi.fn();
    window.actionCable = { disconnect };
    window.WOOT_WIDGET = app;

    ActionCableConnector.refreshConnector('rotated-pubsub');

    expect(disconnect).toHaveBeenCalled();
    expect(window.chatwootPubsubToken).toBe('rotated-pubsub');
    expect(window.actionCable).toBeInstanceOf(ActionCableConnector);
    expect(window.actionCable).not.toBe(connector);
  });

  it('clears presence timers when the connector is disposed', () => {
    expect(vi.getTimerCount()).toBeGreaterThan(0);
    connector.disconnect();
    expect(vi.getTimerCount()).toBe(0);
  });
});
