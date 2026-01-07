import {
  INBOX_TYPES,
  getInboxClassByType,
  getInboxIconByType,
  getInboxWarningIconClass,
  getChannelTypeDisplayName,
} from '../inbox';

describe('#Inbox Helpers', () => {
  describe('getInboxClassByType', () => {
    it('should return correct class for web widget', () => {
      expect(getInboxClassByType('Channel::WebWidget')).toEqual(
        'globe-desktop'
      );
    });
    it('should return correct class for fb page', () => {
      expect(getInboxClassByType('Channel::FacebookPage')).toEqual(
        'brand-facebook'
      );
    });
    it('should return correct class for  twitter profile', () => {
      expect(getInboxClassByType('Channel::TwitterProfile')).toEqual(
        'brand-twitter'
      );
    });
    it('should return correct class for twilio sms', () => {
      expect(getInboxClassByType('Channel::TwilioSms', '')).toEqual(
        'brand-sms'
      );
    });
    it('should return correct class for whatsapp', () => {
      expect(getInboxClassByType('Channel::TwilioSms', 'whatsapp')).toEqual(
        'brand-whatsapp'
      );
    });
    it('should return correct class for Api', () => {
      expect(getInboxClassByType('Channel::Api')).toEqual('cloud');
    });
    it('should return correct class for Email', () => {
      expect(getInboxClassByType('Channel::Email')).toEqual('mail');
    });
    it('should return correct class for TikTok', () => {
      expect(getInboxClassByType(INBOX_TYPES.TIKTOK)).toEqual('brand-tiktok');
    });
  });

  describe('getInboxIconByType', () => {
    describe('fill variant (default)', () => {
      it('returns correct icon for web widget', () => {
        expect(getInboxIconByType(INBOX_TYPES.WEB)).toBe('i-ri-global-fill');
      });

      it('returns correct icon for Facebook', () => {
        expect(getInboxIconByType(INBOX_TYPES.FB)).toBe('i-ri-messenger-fill');
      });

      it('returns correct icon for Twitter', () => {
        expect(getInboxIconByType(INBOX_TYPES.TWITTER)).toBe(
          'i-ri-twitter-x-fill'
        );
      });

      it('returns correct icon for WhatsApp', () => {
        expect(getInboxIconByType(INBOX_TYPES.WHATSAPP)).toBe(
          'i-ri-whatsapp-fill'
        );
      });

      it('returns correct icon for API', () => {
        expect(getInboxIconByType(INBOX_TYPES.API)).toBe('i-ri-cloudy-fill');
      });

      it('returns correct icon for Email', () => {
        expect(getInboxIconByType(INBOX_TYPES.EMAIL)).toBe('i-ri-mail-fill');
      });

      it('returns correct icon for Telegram', () => {
        expect(getInboxIconByType(INBOX_TYPES.TELEGRAM)).toBe(
          'i-ri-telegram-fill'
        );
      });

      it('returns correct icon for Line', () => {
        expect(getInboxIconByType(INBOX_TYPES.LINE)).toBe('i-ri-line-fill');
      });

      it('returns correct icon for TikTok', () => {
        expect(getInboxIconByType(INBOX_TYPES.TIKTOK)).toBe('i-ri-tiktok-fill');
      });

      it('returns default icon for unknown type', () => {
        expect(getInboxIconByType('UNKNOWN_TYPE')).toBe('i-ri-chat-1-fill');
      });

      it('returns default icon for undefined type', () => {
        expect(getInboxIconByType(undefined)).toBe('i-ri-chat-1-fill');
      });
    });

    describe('line variant', () => {
      it('returns correct line icon for web widget', () => {
        expect(getInboxIconByType(INBOX_TYPES.WEB, null, 'line')).toBe(
          'i-woot-website'
        );
      });

      it('returns correct line icon for Facebook', () => {
        expect(getInboxIconByType(INBOX_TYPES.FB, null, 'line')).toBe(
          'i-woot-messenger'
        );
      });

      it('returns correct line icon for TikTok', () => {
        expect(getInboxIconByType(INBOX_TYPES.TIKTOK, null, 'line')).toBe(
          'i-woot-tiktok'
        );
      });

      it('returns correct line icon for unknown type', () => {
        expect(getInboxIconByType('UNKNOWN_TYPE', null, 'line')).toBe(
          'i-ri-chat-1-line'
        );
      });
    });

    describe('Twilio cases', () => {
      describe('fill variant', () => {
        it('returns WhatsApp icon for Twilio WhatsApp number', () => {
          expect(getInboxIconByType(INBOX_TYPES.TWILIO, 'whatsapp')).toBe(
            'i-ri-whatsapp-fill'
          );
        });

        it('returns SMS icon for regular Twilio number', () => {
          expect(getInboxIconByType(INBOX_TYPES.TWILIO, 'sms')).toBe(
            'i-ri-chat-1-fill'
          );
        });

        it('returns SMS icon when phone number is undefined', () => {
          expect(getInboxIconByType(INBOX_TYPES.TWILIO, undefined)).toBe(
            'i-ri-chat-1-fill'
          );
        });
      });

      describe('line variant', () => {
        it('returns WhatsApp line icon for Twilio WhatsApp number', () => {
          expect(
            getInboxIconByType(INBOX_TYPES.TWILIO, 'whatsapp', 'line')
          ).toBe('i-woot-whatsapp');
        });

        it('returns SMS line icon for regular Twilio number', () => {
          expect(getInboxIconByType(INBOX_TYPES.TWILIO, 'sms', 'line')).toBe(
            'i-ri-chat-1-line'
          );
        });
      });
    });
  });

  describe('getInboxWarningIconClass', () => {
    it('should return correct class for warning', () => {
      expect(getInboxWarningIconClass('Channel::FacebookPage', true)).toEqual(
        'warning'
      );
    });
  });

  describe('getChannelTypeDisplayName', () => {
    it('returns "Website" for web widget', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.WEB)).toBe('Website');
    });

    it('returns "Messenger" for Facebook', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.FB)).toBe('Messenger');
    });

    it('returns "Twitter" for Twitter', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.TWITTER)).toBe('Twitter');
    });

    it('returns "WhatsApp" for WhatsApp', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.WHATSAPP)).toBe('WhatsApp');
    });

    it('returns "API" for API', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.API)).toBe('API');
    });

    it('returns "Email" for Email', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.EMAIL)).toBe('Email');
    });

    it('returns "Telegram" for Telegram', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.TELEGRAM)).toBe('Telegram');
    });

    it('returns "Line" for Line', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.LINE)).toBe('Line');
    });

    it('returns "SMS" for SMS', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.SMS)).toBe('SMS');
    });

    it('returns "Instagram" for Instagram', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.INSTAGRAM)).toBe(
        'Instagram'
      );
    });

    it('returns "TikTok" for TikTok', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.TIKTOK)).toBe('TikTok');
    });

    it('returns "Voice" for Voice', () => {
      expect(getChannelTypeDisplayName(INBOX_TYPES.VOICE)).toBe('Voice');
    });

    it('returns "Chat" for unknown type', () => {
      expect(getChannelTypeDisplayName('UNKNOWN_TYPE')).toBe('Chat');
    });

    describe('Twilio cases', () => {
      it('returns "Twilio WhatsApp" for Twilio with whatsapp medium', () => {
        expect(getChannelTypeDisplayName(INBOX_TYPES.TWILIO, 'whatsapp')).toBe(
          'Twilio WhatsApp'
        );
      });

      it('returns "Twilio SMS" for Twilio with sms medium', () => {
        expect(getChannelTypeDisplayName(INBOX_TYPES.TWILIO, 'sms')).toBe(
          'Twilio SMS'
        );
      });

      it('returns "Twilio SMS" for Twilio with undefined medium', () => {
        expect(getChannelTypeDisplayName(INBOX_TYPES.TWILIO, undefined)).toBe(
          'Twilio SMS'
        );
      });

      it('returns "Twilio SMS" for Twilio with empty medium', () => {
        expect(getChannelTypeDisplayName(INBOX_TYPES.TWILIO, '')).toBe(
          'Twilio SMS'
        );
      });
    });
  });
});
