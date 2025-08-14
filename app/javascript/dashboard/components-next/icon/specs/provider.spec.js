import { useChannelIcon } from '../provider';

describe('useChannelIcon', () => {
  it('returns correct icon for API channel', () => {
    const inbox = { channel_type: 'Channel::Api' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-cloudy-fill');
  });

  it('returns correct icon for Facebook channel', () => {
    const inbox = { channel_type: 'Channel::FacebookPage' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-messenger-fill');
  });

  it('returns correct icon for WhatsApp channel', () => {
    const inbox = { channel_type: 'Channel::Whatsapp' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-whatsapp-fill');
  });

  it('returns correct icon for Voice channel', () => {
    const inbox = { channel_type: 'Channel::Voice' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-phone-fill');
  });

  it('returns correct icon for Line channel', () => {
    const inbox = { channel_type: 'Channel::Line' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-line-fill');
  });

  it('returns correct icon for SMS channel', () => {
    const inbox = { channel_type: 'Channel::Sms' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-chat-1-fill');
  });

  it('returns correct icon for Telegram channel', () => {
    const inbox = { channel_type: 'Channel::Telegram' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-telegram-fill');
  });

  it('returns correct icon for Twitter channel', () => {
    const inbox = { channel_type: 'Channel::TwitterProfile' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-twitter-x-fill');
  });

  it('returns correct icon for WebWidget channel', () => {
    const inbox = { channel_type: 'Channel::WebWidget' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-global-fill');
  });

  it('returns correct icon for Instagram channel', () => {
    const inbox = { channel_type: 'Channel::Instagram' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-instagram-fill');
  });

  describe('TwilioSms channel', () => {
    it('returns chat icon for regular Twilio SMS channel', () => {
      const inbox = { channel_type: 'Channel::TwilioSms' };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-ri-chat-1-fill');
    });

    it('returns WhatsApp icon for Twilio SMS with WhatsApp medium', () => {
      const inbox = {
        channel_type: 'Channel::TwilioSms',
        medium: 'whatsapp',
      };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-ri-whatsapp-fill');
    });

    it('returns chat icon for Twilio SMS with non-WhatsApp medium', () => {
      const inbox = {
        channel_type: 'Channel::TwilioSms',
        medium: 'sms',
      };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-ri-chat-1-fill');
    });

    it('returns chat icon for Twilio SMS with undefined medium', () => {
      const inbox = {
        channel_type: 'Channel::TwilioSms',
        medium: undefined,
      };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-ri-chat-1-fill');
    });
  });

  describe('Email channel', () => {
    it('returns mail icon for generic email channel', () => {
      const inbox = { channel_type: 'Channel::Email' };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-ri-mail-fill');
    });

    it('returns Microsoft icon for Microsoft email provider', () => {
      const inbox = {
        channel_type: 'Channel::Email',
        provider: 'microsoft',
      };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-ri-microsoft-fill');
    });

    it('returns Google icon for Google email provider', () => {
      const inbox = {
        channel_type: 'Channel::Email',
        provider: 'google',
      };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-ri-google-fill');
    });
  });

  it('returns default icon for unknown channel type', () => {
    const inbox = { channel_type: 'Channel::Unknown' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-global-fill');
  });

  it('returns default icon when channel type is undefined', () => {
    const inbox = {};
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-global-fill');
  });
});
