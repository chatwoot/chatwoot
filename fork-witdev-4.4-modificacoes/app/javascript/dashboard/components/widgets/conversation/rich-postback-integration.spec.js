import { describe, it, expect, beforeEach, vi } from 'vitest';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';

describe('Rich Postback Integration End-to-End', () => {
  let mockAnalytics;
  let consoleSpy;

  beforeEach(() => {
    vi.clearAllMocks();

    // Mock analytics
    mockAnalytics = {
      track: vi.fn(),
    };
    window.analytics = mockAnalytics;

    // Mock console.log
    consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleSpy.mockRestore();
  });

  it('should handle rich postback events from RichCards component', () => {
    const mockHandler = vi.fn();

    // Set up event listener (simulating MessagesView)
    emitter.on(BUS_EVENTS.RICH_POSTBACK, mockHandler);

    // Simulate RichCards component emitting postback event
    const postbackData = {
      messageId: 123,
      payload: 'CARD_BUTTON_PAYLOAD',
      text: 'Buy Now',
      type: 'card_button',
      timestamp: new Date().toISOString(),
    };

    emitter.emit(BUS_EVENTS.RICH_POSTBACK, postbackData);

    // Verify the event was received
    expect(mockHandler).toHaveBeenCalledWith(postbackData);

    // Clean up
    emitter.off(BUS_EVENTS.RICH_POSTBACK, mockHandler);
  });

  it('should handle rich postback events from QuickReplies component', () => {
    const mockHandler = vi.fn();

    // Set up event listener (simulating MessagesView)
    emitter.on(BUS_EVENTS.RICH_POSTBACK, mockHandler);

    // Simulate QuickReplies component emitting postback event
    const postbackData = {
      messageId: 456,
      payload: 'QUICK_REPLY_PAYLOAD',
      text: 'Yes',
      type: 'quick_reply',
      timestamp: new Date().toISOString(),
    };

    emitter.emit(BUS_EVENTS.RICH_POSTBACK, postbackData);

    // Verify the event was received
    expect(mockHandler).toHaveBeenCalledWith(postbackData);

    // Clean up
    emitter.off(BUS_EVENTS.RICH_POSTBACK, mockHandler);
  });

  it('should verify BUS_EVENTS.RICH_POSTBACK constant exists', () => {
    expect(BUS_EVENTS.RICH_POSTBACK).toBe('richPostback');
  });

  it('should handle multiple postback events in sequence', () => {
    const mockHandler = vi.fn();

    // Set up event listener
    emitter.on(BUS_EVENTS.RICH_POSTBACK, mockHandler);

    // Emit multiple events
    const events = [
      {
        messageId: 1,
        payload: 'FIRST_PAYLOAD',
        text: 'First Button',
        type: 'card_button',
      },
      {
        messageId: 2,
        payload: 'SECOND_PAYLOAD',
        text: 'Second Option',
        type: 'quick_reply',
      },
      {
        messageId: 3,
        payload: 'THIRD_PAYLOAD',
        text: 'Third Action',
        type: 'card_button',
      },
    ];

    events.forEach(event => {
      emitter.emit(BUS_EVENTS.RICH_POSTBACK, event);
    });

    // Verify all events were received
    expect(mockHandler).toHaveBeenCalledTimes(3);
    events.forEach((event, index) => {
      expect(mockHandler).toHaveBeenNthCalledWith(index + 1, event);
    });

    // Clean up
    emitter.off(BUS_EVENTS.RICH_POSTBACK, mockHandler);
  });

  it('should handle postback events with minimal data', () => {
    const mockHandler = vi.fn();

    // Set up event listener
    emitter.on(BUS_EVENTS.RICH_POSTBACK, mockHandler);

    // Emit event with minimal data
    const minimalEvent = {
      messageId: 999,
      payload: 'MINIMAL_PAYLOAD',
    };

    emitter.emit(BUS_EVENTS.RICH_POSTBACK, minimalEvent);

    // Verify the event was received
    expect(mockHandler).toHaveBeenCalledWith(minimalEvent);

    // Clean up
    emitter.off(BUS_EVENTS.RICH_POSTBACK, mockHandler);
  });
});
