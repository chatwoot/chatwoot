import {
  INBOX_TYPES,
  getInboxClassByType,
  getInboxIconByType,
  getInboxWarningIconClass,
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
          'i-ri-global-line'
        );
      });

      it('returns correct line icon for Facebook', () => {
        expect(getInboxIconByType(INBOX_TYPES.FB, null, 'line')).toBe(
          'i-ri-messenger-line'
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
          expect(
            getInboxIconByType(INBOX_TYPES.TWILIO, 'whatsapp:+1234567890')
          ).toBe('i-ri-whatsapp-fill');
        });

        it('returns SMS icon for regular Twilio number', () => {
          expect(getInboxIconByType(INBOX_TYPES.TWILIO, '+1234567890')).toBe(
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
            getInboxIconByType(
              INBOX_TYPES.TWILIO,
              'whatsapp:+1234567890',
              'line'
            )
          ).toBe('i-ri-whatsapp-line');
        });

        it('returns SMS line icon for regular Twilio number', () => {
          expect(
            getInboxIconByType(INBOX_TYPES.TWILIO, '+1234567890', 'line')
          ).toBe('i-ri-chat-1-line');
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
});
