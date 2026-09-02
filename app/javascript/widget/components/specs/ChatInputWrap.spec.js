import { describe, expect, it, vi } from 'vitest';

import ChatInputWrap from '../ChatInputWrap.vue';

const initialMessageHandler = ChatInputWrap.watch.initialMessage.handler;
const handleButtonClick = ChatInputWrap.methods.handleButtonClick;

describe('ChatInputWrap initial message draft', () => {
  it('keeps the shared initial message when copying it to local input', () => {
    const context = {
      userInput: '',
      focusInput: vi.fn(),
      $nextTick: callback => callback(),
      $store: { dispatch: vi.fn() },
    };

    initialMessageHandler.call(context, 'Need help with this item');

    expect(context.userInput).toBe('Need help with this item');
    expect(context.$store.dispatch).not.toHaveBeenCalledWith(
      'conversation/clearInitialMessage'
    );
    expect(context.focusInput).toHaveBeenCalled();
  });

  it('clears the shared initial message only after sending', () => {
    const context = {
      userInput: 'Need help with this item',
      focusInput: vi.fn(),
      onSendMessage: vi.fn(),
      $store: { dispatch: vi.fn() },
    };

    handleButtonClick.call(context);

    expect(context.onSendMessage).toHaveBeenCalledWith(
      'Need help with this item'
    );
    expect(context.$store.dispatch).toHaveBeenCalledWith(
      'conversation/clearInitialMessage'
    );
    expect(context.userInput).toBe('');
  });

  it('clears the local input when the shared initial message is cleared', () => {
    const context = {
      userInput: 'Previous identity draft',
      focusInput: vi.fn(),
      $nextTick: callback => callback(),
    };

    initialMessageHandler.call(context, '');

    expect(context.userInput).toBe('');
    expect(context.focusInput).not.toHaveBeenCalled();
  });
});
