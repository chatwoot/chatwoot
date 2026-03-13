import { describe, expect, it, vi } from 'vitest';
import ReplyBox from '../ReplyBox.vue';

describe('ReplyBox plain text mode', () => {
  it('prioritizes manual plain text mode over canned response format', () => {
    const ctx = {
      isPlainTextMode: true,
      nextMessageFormat: null,
    };

    expect(ReplyBox.methods.getCurrentMessageFormat.call(ctx)).toBe(
      'plain_text'
    );

    ctx.nextMessageFormat = 'plain_text';
    expect(ReplyBox.methods.getCurrentMessageFormat.call(ctx)).toBe(
      'plain_text'
    );
  });

  it('serializes outgoing content as literal text in plain text mode', () => {
    const ctx = {
      isPlainTextMode: true,
      nextMessageFormat: null,
      $refs: {
        messageEditor: {
          getPlainTextContent: () => 'Первая строка\n\n- пункт один',
        },
      },
      getCurrentMessageFormat: ReplyBox.methods.getCurrentMessageFormat,
    };

    expect(
      ReplyBox.methods.getOutgoingMessageContent.call(
        ctx,
        'ignored markdown value'
      )
    ).toBe('Первая строка\n\n- пункт один');
  });

  it('resets plain text mode after clearMessage', () => {
    const ctx = {
      message: 'text',
      isPlainTextMode: true,
      nextMessageFormat: 'plain_text',
      clearCopilotAcceptedMessage: vi.fn(),
      sendWithSignature: false,
      isPrivate: false,
      attachedFiles: ['file'],
      isRecordingAudio: true,
      resetReplyToMessage: vi.fn(),
      resetAudioRecorderInput: vi.fn(),
    };

    ReplyBox.methods.clearMessage.call(ctx);

    expect(ctx.message).toBe('');
    expect(ctx.isPlainTextMode).toBe(false);
    expect(ctx.nextMessageFormat).toBe(null);
  });
});
