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

    it('renders a message for the conversation on screen and keeps its row current', () => {
      connector.onMessageCreated({ ...message, conversation_id: 1 });

      expect(mockDispatch).toBeCalledWith('conversation/addOrUpdateMessage', {
        ...message,
        conversation_id: 1,
      });
      expect(mockDispatch).toBeCalledWith(
        'conversationList/updateLastMessage',
        {
          ...message,
          conversation_id: 1,
        }
      );
      expect(mockDispatch).not.toBeCalledWith('conversationList/fetch');
    });

    it('applies message updates only to the conversation on screen', () => {
      connector.onMessageUpdated({ ...message, conversation_id: 1 });
      connector.onMessageUpdated(message);

      expect(mockDispatch.mock.calls).toEqual([
        ['conversation/addOrUpdateMessage', { ...message, conversation_id: 1 }],
      ]);
    });

    it('ignores message updates of earlier conversations on a new thread', () => {
      app.$store.getters = {
        ...getters,
        'conversationAttributes/getConversationParams': { id: '' },
      };

      connector.onMessageUpdated(message);

      expect(mockDispatch).not.toBeCalled();
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

    it('attaches the conversation a new thread became while its first message is saved', () => {
      app.$store.getters = {
        ...getters,
        'conversationAttributes/getConversationParams': { id: '' },
        'conversation/getIsCreating': true,
      };

      connector.onMessageCreated(message);

      expect(mockDispatch).toBeCalledWith('conversationList/attach', 2);
      expect(mockDispatch).not.toBeCalledWith('conversationList/open', 2);
      expect(mockDispatch).toBeCalledWith(
        'conversation/addOrUpdateMessage',
        message
      );
    });

    it('never lets the visitor own messages from elsewhere take over a new thread', () => {
      app.$store.getters = {
        ...getters,
        'conversationAttributes/getConversationParams': { id: '' },
      };
      const ownMessage = { ...message, message_type: 0 };

      connector.onMessageCreated(ownMessage);

      expect(mockDispatch).toBeCalledWith('conversationList/fetch');
      expect(mockDispatch).not.toBeCalledWith('conversationList/open', 2);
      expect(mockDispatch).not.toBeCalledWith(
        'conversation/addOrUpdateMessage',
        ownMessage
      );
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

    it('applies message updates while no conversation is known yet', () => {
      app.$store.getters = {
        'conversationAttributes/getConversationParams': { id: '' },
      };

      connector.onMessageUpdated({ id: 10, conversation_id: 2 });

      expect(mockDispatch).toBeCalledWith('conversation/addOrUpdateMessage', {
        id: 10,
        conversation_id: 2,
      });
    });

    it('moves to a newly created conversation', () => {
      connector.onConversationCreated();

      expect(mockDispatch.mock.calls).toEqual([
        ['conversationAttributes/getAttributes'],
      ]);
    });
  });

  describe('typing indicator', () => {
    const typing = conversationId => ({
      conversation: { id: conversationId },
      is_private: false,
    });

    beforeEach(() => {
      app.$store.getters = {
        'conversationAttributes/getConversationParams': { id: 1 },
      };
    });

    it('keeps it when an agent stops typing in another conversation', () => {
      connector.onTypingOn(typing(1));
      mockDispatch.mockClear();

      connector.onTypingOff(typing(2));

      expect(mockDispatch).not.toBeCalled();
    });

    it('clears it when the agent stops typing in the conversation on screen', () => {
      connector.onTypingOn(typing(1));
      connector.onTypingOff(typing(1));

      expect(mockDispatch).toHaveBeenLastCalledWith(
        'conversation/toggleAgentTyping',
        { status: 'off' }
      );
    });

    it('clears it on its own after 30 seconds', () => {
      connector.onTypingOn(typing(1));
      mockDispatch.mockClear();

      vi.advanceTimersByTime(30000);

      expect(mockDispatch).toBeCalledWith('conversation/toggleAgentTyping', {
        status: 'off',
      });
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
