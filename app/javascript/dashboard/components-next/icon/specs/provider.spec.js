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
