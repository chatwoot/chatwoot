import { canRetryMessage, getMessageError } from '../messageError';

const FALLBACK = 'Network fallback';

describe('getMessageError', () => {
  it('returns the external error set by the server', () => {
    expect(
      getMessageError(
        {
          status: 'failed',
          contentAttributes: { externalError: 'Recipient blocked' },
        },
        FALLBACK
      )
    ).toBe('Recipient blocked');
  });

  it('returns the request error for a reply that failed to send', () => {
    expect(
      getMessageError(
        { status: 'failed', meta: { error: 'Attachment too large' } },
        FALLBACK
      )
    ).toBe('Attachment too large');
  });

  it('falls back when the request failed without an error text', () => {
    expect(
      getMessageError(
        { status: 'failed', meta: { error: undefined } },
        FALLBACK
      )
    ).toBe(FALLBACK);
  });

  it('returns nothing for a failed message from the server without an error', () => {
    expect(getMessageError({ status: 'failed' }, FALLBACK)).toBe('');
  });

  it('returns nothing while a retried reply is in progress', () => {
    expect(
      getMessageError(
        { status: 'progress', meta: { error: undefined } },
        FALLBACK
      )
    ).toBe('');
  });

  it('returns nothing for a sent message', () => {
    expect(getMessageError({ status: 'sent', contentAttributes: {} })).toBe('');
  });
});

describe('canRetryMessage', () => {
  const now = () => Math.floor(Date.now() / 1000);

  it('allows retrying an attachment-only reply that failed in the browser', () => {
    // ReplyBox sends captionless attachments as `files`, so the pending
    // message has neither content nor attachment records.
    expect(
      canRetryMessage({
        createdAt: now(),
        content: null,
        attachments: null,
        meta: { error: undefined },
      })
    ).toBe(true);
  });

  it('allows retrying a server-reported failure that has content', () => {
    expect(
      canRetryMessage({ createdAt: now(), content: 'Hi', attachments: [] })
    ).toBe(true);
  });

  it('does not offer retry for a server message with nothing to resend', () => {
    expect(
      canRetryMessage({ createdAt: now(), content: null, attachments: [] })
    ).toBe(false);
  });

  it('does not offer retry once a day has passed', () => {
    expect(
      canRetryMessage({
        createdAt: now() - 2 * 24 * 60 * 60,
        content: 'Hi',
        meta: { error: undefined },
      })
    ).toBe(false);
  });
});
