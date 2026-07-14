import TwilioVoiceClient from '../twilioVoiceClient';

describe('TwilioVoiceClient#sendDigits', () => {
  afterEach(() => {
    TwilioVoiceClient.activeConnection = null;
  });

  it('returns false when there is no active connection', () => {
    expect(TwilioVoiceClient.sendDigits('9')).toBe(false);
  });

  it('returns false without sending when the connection is not open', () => {
    const sendDigits = vi.fn();
    TwilioVoiceClient.activeConnection = {
      status: vi.fn(() => 'reconnecting'),
      sendDigits,
    };

    expect(TwilioVoiceClient.sendDigits('9')).toBe(false);
    expect(sendDigits).not.toHaveBeenCalled();
  });

  it('sends one digit through an open connection', () => {
    const sendDigits = vi.fn();
    TwilioVoiceClient.activeConnection = {
      status: vi.fn(() => 'open'),
      sendDigits,
    };

    expect(TwilioVoiceClient.sendDigits('#')).toBe(true);
    expect(sendDigits).toHaveBeenCalledOnce();
    expect(sendDigits).toHaveBeenCalledWith('#');
  });
});
