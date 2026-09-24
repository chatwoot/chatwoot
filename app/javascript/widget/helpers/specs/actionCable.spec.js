import { describe, it, beforeEach, afterEach, expect, vi } from 'vitest';
import ActionCableConnector from '../actionCable';
import { IFrameHelper } from 'widget/helpers/utils';

vi.mock('@rails/actioncable', () => ({
  createConsumer: () => ({
    subscriptions: { create: () => ({}) },
    disconnect: vi.fn(),
  }),
}));

vi.mock('widget/helpers/utils', async importOriginal => {
  const utils = await importOriginal();
  return {
    ...utils,
    IFrameHelper: {
      ...utils.IFrameHelper,
      isIFrame: vi.fn(),
      sendMessage: vi.fn(),
    },
  };
});

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

  describe('with multiple conversations enabled', () => {
    const message = { id: 10, conversation_id: 2, sender_type: 'Contact' };
    const getters = {
      'conversationAttributes/getConversationParams': { id: 1 },
      'appConfig/getIsWidgetOpen': false,
    };

    beforeEach(() => {
      window.chatwootWebChannel = {
        enabledFeatures: ['multiple_conversations'],
      };
      mockDispatch.mockResolvedValue(undefined);
      app.$store.getters = getters;
      IFrameHelper.isIFrame.mockReturnValue(true);
    });

    afterEach(() => {
      delete window.chatwootWebChannel;
    });

    it('renders a message for the conversation on screen', () => {
      connector.onMessageCreated({ ...message, conversation_id: 1 });

      expect(mockDispatch).toBeCalledWith('conversation/addOrUpdateMessage', {
        ...message,
        conversation_id: 1,
      });
      expect(mockDispatch).not.toBeCalledWith('conversationList/fetch');
    });

    it('switches to the conversation of a new message while the widget is closed', () => {
      connector.onMessageCreated(message);

      expect(mockDispatch).toBeCalledWith('conversationList/open', 2);
      expect(mockDispatch).toBeCalledWith(
        'conversation/addOrUpdateMessage',
        message
      );
      expect(IFrameHelper.sendMessage).toBeCalledWith(
        expect.objectContaining({ event: 'onEvent', data: message })
      );
    });

    it('switches to the conversation of a new message while no conversation is open', () => {
      app.$store.getters = {
        ...getters,
        'conversationAttributes/getConversationParams': { id: '' },
        'appConfig/getIsWidgetOpen': true,
      };

      connector.onMessageCreated(message);

      expect(mockDispatch).toBeCalledWith('conversationList/open', 2);
    });

    it('only refreshes the list when the visitor is viewing another conversation', () => {
      app.$store.getters = { ...getters, 'appConfig/getIsWidgetOpen': true };

      connector.onMessageCreated(message);

      expect(mockDispatch).toBeCalledWith('conversationList/fetch');
      expect(mockDispatch).not.toBeCalledWith(
        'conversation/addOrUpdateMessage',
        message
      );
      expect(IFrameHelper.sendMessage).toBeCalledWith(
        expect.objectContaining({ event: 'onEvent', data: message })
      );
    });

    it('refreshes the list instead of moving to a newly created conversation', () => {
      connector.onConversationCreated();

      expect(mockDispatch.mock.calls).toEqual([['conversationList/fetch']]);
    });

    it('refreshes the list on status changes and reconnects', () => {
      connector.onStatusChange({ id: 2, status: 'resolved' });
      connector.onReconnect();

      expect(mockDispatch).toBeCalledWith('conversationAttributes/update', {
        id: 2,
        status: 'resolved',
      });
      expect(
        mockDispatch.mock.calls.filter(
          ([action]) => action === 'conversationList/fetch'
        )
      ).toHaveLength(2);
    });
  });

  describe('with multiple conversations disabled', () => {
    beforeEach(() => {
      mockDispatch.mockResolvedValue(undefined);
      app.$store.getters = {
        'conversationAttributes/getConversationParams': { id: 1 },
      };
    });

    it('ignores messages of other conversations entirely', () => {
      connector.onMessageCreated({ id: 10, conversation_id: 2 });

      expect(mockDispatch).not.toBeCalled();
      expect(IFrameHelper.sendMessage).not.toBeCalled();
    });

    it('moves to a newly created conversation', () => {
      connector.onConversationCreated();

      expect(mockDispatch.mock.calls).toEqual([
        ['conversationAttributes/getAttributes'],
      ]);
    });
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
});
