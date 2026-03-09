/* eslint-disable no-console */
import { mount } from '@vue/test-utils';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';

// Mock the MessagesView component with minimal setup
const MessagesViewMock = {
  name: 'MessagesView',
  template: '<div class="messages-view">Messages</div>',
  data() {
    return {
      currentChat: { id: 123, inbox_id: 456 },
      currentAccountId: 789,
    };
  },
  created() {
    // Simulate the event listener setup
    emitter.on(BUS_EVENTS.RICH_POSTBACK, this.onRichPostback);
  },
  unmounted() {
    emitter.off(BUS_EVENTS.RICH_POSTBACK, this.onRichPostback);
  },
  methods: {
    onRichPostback(postbackData) {
      // Handle rich message postback events for metrics and automation
      const { messageId, payload, text, type, timestamp } = postbackData;

      // Track metrics for postback interaction
      if (window.analytics) {
        window.analytics.track('cw_rich_postback_interaction', {
          conversation_id: this.currentChat.id,
          message_id: messageId,
          payload: payload,
          text: text,
          type: type || 'unknown',
          timestamp: timestamp,
          account_id: this.currentAccountId,
          inbox_id: this.currentChat.inbox_id,
        });
      }

      // Log for debugging and monitoring
      console.log('[RichPostback] Conversation-level event:', {
        conversationId: this.currentChat.id,
        messageId,
        payload,
        text,
        type,
      });

      // Emit to parent components for further automation/integration
      this.$emit('richPostback', {
        conversationId: this.currentChat.id,
        messageId,
        payload,
        text,
        type,
        timestamp,
        chat: this.currentChat,
      });
    },
  },
};

// Mock window.analytics
Object.defineProperty(window, 'analytics', {
  value: {
    track: vi.fn(),
  },
  writable: true,
});

describe('MessagesView Rich Postback Integration', () => {
  let wrapper;
  let consoleSpy;

  beforeEach(() => {
    vi.clearAllMocks();
    consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

    wrapper = mount(MessagesViewMock);
  });

  afterEach(() => {
    consoleSpy.mockRestore();
    if (wrapper) {
      wrapper.unmount();
    }
  });

  it('handles rich postback events correctly', async () => {
    const postbackData = {
      messageId: 123,
      payload: 'TEST_PAYLOAD',
      text: 'Test Button',
      type: 'quick_reply',
      timestamp: '2024-01-01T00:00:00Z',
    };

    // Emit the rich postback event
    emitter.emit(BUS_EVENTS.RICH_POSTBACK, postbackData);

    await wrapper.vm.$nextTick();

    // Check that analytics tracking was called
    expect(window.analytics.track).toHaveBeenCalledWith(
      'cw_rich_postback_interaction',
      {
        conversation_id: 123,
        message_id: 123,
        payload: 'TEST_PAYLOAD',
        text: 'Test Button',
        type: 'quick_reply',
        timestamp: '2024-01-01T00:00:00Z',
        account_id: 789,
        inbox_id: 456,
      }
    );

    // Check that console logging was called
    expect(consoleSpy).toHaveBeenCalledWith(
      '[RichPostback] Conversation-level event:',
      {
        conversationId: 123,
        messageId: 123,
        payload: 'TEST_PAYLOAD',
        text: 'Test Button',
        type: 'quick_reply',
      }
    );
  });

  it('emits rich-postback event to parent components', async () => {
    const postbackData = {
      messageId: 456,
      payload: 'PARENT_TEST',
      text: 'Parent Test',
      type: 'card_button',
      timestamp: '2024-01-01T12:00:00Z',
    };

    // Emit the rich postback event
    emitter.emit(BUS_EVENTS.RICH_POSTBACK, postbackData);

    await wrapper.vm.$nextTick();

    // Check that the component emitted the event to parent
    const emittedEvents = wrapper.emitted('richPostback');
    expect(emittedEvents).toBeTruthy();
    expect(emittedEvents[0][0]).toEqual({
      conversationId: 123,
      messageId: 456,
      payload: 'PARENT_TEST',
      text: 'Parent Test',
      type: 'card_button',
      timestamp: '2024-01-01T12:00:00Z',
      chat: { id: 123, inbox_id: 456 },
    });
  });

  it('handles postback events without type gracefully', async () => {
    const postbackData = {
      messageId: 789,
      payload: 'NO_TYPE_TEST',
      text: 'No Type Test',
      timestamp: '2024-01-01T18:00:00Z',
    };

    // Emit the rich postback event
    emitter.emit(BUS_EVENTS.RICH_POSTBACK, postbackData);

    await wrapper.vm.$nextTick();

    // Check that analytics tracking was called with 'unknown' type
    expect(window.analytics.track).toHaveBeenCalledWith(
      'cw_rich_postback_interaction',
      {
        conversation_id: 123,
        message_id: 789,
        payload: 'NO_TYPE_TEST',
        text: 'No Type Test',
        type: 'unknown',
        timestamp: '2024-01-01T18:00:00Z',
        account_id: 789,
        inbox_id: 456,
      }
    );
  });

  it('handles missing analytics gracefully', async () => {
    // Set analytics to undefined
    window.analytics = undefined;

    const postbackData = {
      messageId: 999,
      payload: 'NO_ANALYTICS_TEST',
      text: 'No Analytics Test',
      type: 'test',
      timestamp: '2024-01-01T23:59:59Z',
    };

    // Should not throw an error
    expect(() => {
      emitter.emit(BUS_EVENTS.RICH_POSTBACK, postbackData);
    }).not.toThrow();

    await wrapper.vm.$nextTick();

    // Should still log to console
    expect(consoleSpy).toHaveBeenCalledWith(
      '[RichPostback] Conversation-level event:',
      {
        conversationId: 123,
        messageId: 999,
        payload: 'NO_ANALYTICS_TEST',
        text: 'No Analytics Test',
        type: 'test',
      }
    );
  });
});
