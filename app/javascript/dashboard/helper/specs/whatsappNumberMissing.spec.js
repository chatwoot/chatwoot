import {
  canCheckWhatsappNumber,
  isWhatsappMissingRecheckDue,
  whatsappMissingCheckedAt,
  WHATSAPP_MISSING_RECHECK_AFTER_MS,
} from '../whatsappNumberMissing';

const CHECKED_AT = 1792170600;

describe('whatsappMissingCheckedAt', () => {
  it('answers the check date the server holds', () => {
    expect(
      whatsappMissingCheckedAt({ whatsapp_missing_checked_at: CHECKED_AT })
    ).toBe(CHECKED_AT);
  });

  // The thread is not evidence here: an echo is born delivered and an import carries old
  // receipts. The server clears the flag and pushes the change.
  it('ignores what the thread shows', () => {
    const conversation = {
      whatsapp_missing_checked_at: CHECKED_AT,
      messages: [
        { message_type: 1, status: 'delivered', created_at: CHECKED_AT + 60 },
      ],
    };

    expect(whatsappMissingCheckedAt(conversation)).toBe(CHECKED_AT);
  });

  it('answers null when the conversation is not flagged', () => {
    expect(
      whatsappMissingCheckedAt({ whatsapp_missing_checked_at: null })
    ).toBeNull();
  });
});

describe('isWhatsappMissingRecheckDue', () => {
  const checkedAtMs = CHECKED_AT * 1000;

  it('is due once the window has passed', () => {
    expect(
      isWhatsappMissingRecheckDue(
        CHECKED_AT,
        checkedAtMs + WHATSAPP_MISSING_RECHECK_AFTER_MS
      )
    ).toBe(true);
  });

  it('is not due inside the window', () => {
    expect(
      isWhatsappMissingRecheckDue(
        CHECKED_AT,
        checkedAtMs + WHATSAPP_MISSING_RECHECK_AFTER_MS - 1
      )
    ).toBe(false);
  });

  it('is never due without a flag', () => {
    expect(isWhatsappMissingRecheckDue(null, Date.now())).toBe(false);
  });
});

describe('canCheckWhatsappNumber', () => {
  const inbox = {
    channelType: 'Channel::Whatsapp',
    provider: 'baileys',
    capabilities: ['check_number'],
    providerConnection: { connection: 'open' },
  };

  it('asks an open session that can check numbers', () => {
    expect(canCheckWhatsappNumber(inbox)).toBe(true);
  });

  it('does not ask a session that is not open', () => {
    expect(
      canCheckWhatsappNumber({
        ...inbox,
        providerConnection: { connection: 'close' },
      })
    ).toBe(false);
  });

  it('does not ask a provider without the capability', () => {
    expect(canCheckWhatsappNumber({ ...inbox, capabilities: [] })).toBe(false);
  });

  it('does not ask a Cloud inbox', () => {
    expect(
      canCheckWhatsappNumber({ ...inbox, provider: 'whatsapp_cloud' })
    ).toBe(false);
  });
});
