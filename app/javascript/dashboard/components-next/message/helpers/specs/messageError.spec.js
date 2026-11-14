import { getMessageError } from '../messageError';

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
