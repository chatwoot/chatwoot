import { EventEmitter } from 'node:events';
import TwilioVoiceClient, { isTwilioCallConnected } from '../twilioVoiceClient';

describe('TwilioVoiceClient#sendDigits', () => {
  afterEach(() => {
    TwilioVoiceClient.destroyDevice();
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

describe('Twilio connection readiness', () => {
  afterEach(() => TwilioVoiceClient.destroyDevice());

  it('tracks acceptance, reconnecting, recovery and disconnect instead of the connect promise', async () => {
    let status = 'connecting';
    const connection = new EventEmitter();
    connection.status = () => status;
    TwilioVoiceClient.device = {
      connect: vi.fn().mockResolvedValue(connection),
      destroy: vi.fn(),
    };
    TwilioVoiceClient.initialized = true;

    await TwilioVoiceClient.joinClientCall({
      to: 'conference',
      callSid: 'CA123',
      conversationId: 1,
    });
    expect(isTwilioCallConnected.value).toBe(false);

    status = 'open';
    connection.emit('accept');
    expect(isTwilioCallConnected.value).toBe(true);

    status = 'reconnecting';
    connection.emit('reconnecting');
    expect(isTwilioCallConnected.value).toBe(false);

    connection.emit('reconnected');
    expect(isTwilioCallConnected.value).toBe(true);
    status = 'open';

    status = 'closed';
    connection.emit('disconnect');
    expect(isTwilioCallConnected.value).toBe(false);
  });

  it('clears readiness on teardown and ignores acceptance from the old connection', () => {
    const connection = new EventEmitter();
    connection.status = () => 'open';
    TwilioVoiceClient.trackConnection(connection);
    expect(isTwilioCallConnected.value).toBe(true);

    TwilioVoiceClient.destroyDevice();
    connection.emit('accept');
    expect(isTwilioCallConnected.value).toBe(false);

    const replacement = new EventEmitter();
    replacement.status = () => 'open';
    TwilioVoiceClient.trackConnection(replacement);
    connection.emit('disconnect');
    expect(isTwilioCallConnected.value).toBe(true);
    expect(TwilioVoiceClient.activeConnection).toBe(replacement);
  });
});
