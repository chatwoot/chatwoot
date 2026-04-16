import { useChannelIcon } from '../provider';

describe('useChannelIcon', () => {
  it('returns correct icon for API channel', () => {
    const inbox = { channel_type: 'Channel::Api' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-api');
  });

  it('returns correct icon for Facebook channel', () => {
    const inbox = { channel_type: 'Channel::FacebookPage' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-messenger');
  });

  it('returns correct icon for WhatsApp channel', () => {
    const inbox = { channel_type: 'Channel::Whatsapp' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-whatsapp');
  });

  it('returns correct icon for Voice channel', () => {
    const inbox = { channel_type: 'Channel::Voice' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-voice');
  });

  it('returns correct icon for Line channel', () => {
    const inbox = { channel_type: 'Channel::Line' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-line');
  });

  it('returns correct icon for SMS channel', () => {
    const inbox = { channel_type: 'Channel::Sms' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-sms');
  });

  it('returns correct icon for Telegram channel', () => {
    const inbox = { channel_type: 'Channel::Telegram' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-telegram');
  });

  it('returns correct icon for Twitter channel', () => {
    const inbox = { channel_type: 'Channel::TwitterProfile' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-x');
  });

  it('returns correct icon for WebWidget channel', () => {
    const inbox = { channel_type: 'Channel::WebWidget' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-website');
  });

  it('returns correct icon for Instagram channel', () => {
    const inbox = { channel_type: 'Channel::Instagram' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-instagram');
  });

  it('returns correct icon for TikTok channel', () => {
    const inbox = { channel_type: 'Channel::Tiktok' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-tiktok');
  });

  describe('TwilioSms channel', () => {
    it('returns chat icon for regular Twilio SMS channel', () => {
      const inbox = { channel_type: 'Channel::TwilioSms' };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-woot-sms');
    });

    it('returns WhatsApp icon for Twilio SMS with WhatsApp medium', () => {
      const inbox = {
        channel_type: 'Channel::TwilioSms',
        medium: 'whatsapp',
      };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-woot-whatsapp');
    });

    it('returns chat icon for Twilio SMS with non-WhatsApp medium', () => {
      const inbox = {
        channel_type: 'Channel::TwilioSms',
        medium: 'sms',
      };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-woot-sms');
    });

    it('returns chat icon for Twilio SMS with undefined medium', () => {
      const inbox = {
        channel_type: 'Channel::TwilioSms',
        medium: undefined,
      };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-woot-sms');
    });
  });

  describe('Email channel', () => {
    it('returns mail icon for generic email channel', () => {
      const inbox = { channel_type: 'Channel::Email' };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-woot-mail');
    });

    it('returns Microsoft icon for Microsoft email provider', () => {
      const inbox = {
        channel_type: 'Channel::Email',
        provider: 'microsoft',
      };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-woot-outlook');
    });

    it('returns Google icon for Google email provider', () => {
      const inbox = {
        channel_type: 'Channel::Email',
        provider: 'google',
      };
      const { value: icon } = useChannelIcon(inbox);
      expect(icon).toBe('i-woot-gmail');
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
