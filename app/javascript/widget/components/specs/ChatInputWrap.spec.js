import { describe, expect, it, vi } from 'vitest';

import ChatInputWrap from '../ChatInputWrap.vue';

const initialMessageHandler = ChatInputWrap.watch.initialMessage.handler;
const userInputHandler = ChatInputWrap.watch.userInput;
const handleButtonClick = ChatInputWrap.methods.handleButtonClick;

describe('ChatInputWrap initial message draft', () => {
  it('keeps the shared initial message when copying it to local input', () => {
    const context = {
      userInput: '',
      hasInitialMessageDraft: false,
      focusInput: vi.fn(),
      $nextTick: callback => callback(),
      $store: { dispatch: vi.fn() },
    };

    initialMessageHandler.call(context, 'Need help with this item');

    expect(context.userInput).toBe('Need help with this item');
    expect(context.hasInitialMessageDraft).toBe(true);
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
      hasInitialMessageDraft: true,
      focusInput: vi.fn(),
      $nextTick: callback => callback(),
    };

    initialMessageHandler.call(context, '');

    expect(context.userInput).toBe('');
    expect(context.hasInitialMessageDraft).toBe(false);
    expect(context.focusInput).not.toHaveBeenCalled();
  });

  it('preserves edits by syncing active initial message drafts', () => {
    const context = {
      hasInitialMessageDraft: true,
      $store: { dispatch: vi.fn() },
    };

    userInputHandler.call(context, 'Edited draft');

    expect(context.$store.dispatch).toHaveBeenCalledWith(
      'conversation/setInitialMessage',
      'Edited draft'
    );
    expect(context.hasInitialMessageDraft).toBe(true);
  });

  it('does not sync regular composer input as an initial message draft', () => {
    const context = {
      hasInitialMessageDraft: false,
      $store: { dispatch: vi.fn() },
    };

    userInputHandler.call(context, 'Regular reply');

    expect(context.$store.dispatch).not.toHaveBeenCalled();
  });
});
