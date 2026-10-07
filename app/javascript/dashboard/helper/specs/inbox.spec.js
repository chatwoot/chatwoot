import {
  INBOX_TYPES,
  VOICE_CALL_PROVIDERS,
  getInboxClassByType,
  getInboxIconByType,
  getInboxIdentifier,
  getInboxVoiceIcon,
  getInboxWarningIconClass,
  getVoiceCallIcon,
  searchInboxes,
} from '../inbox';

describe('#Inbox Helpers', () => {
  describe('getInboxIdentifier', () => {
    it.each([
      [
        INBOX_TYPES.WEB,
        { website_url: 'https://example.com' },
        'https://example.com',
      ],
      [
        INBOX_TYPES.EMAIL,
        { email: 'support@example.com' },
        'support@example.com',
      ],
      [INBOX_TYPES.WHATSAPP, { phone_number: '+15555550100' }, '+15555550100'],
      [INBOX_TYPES.SMS, { phone_number: '+15555550101' }, '+15555550101'],
      [INBOX_TYPES.TELEGRAM, { bot_name: 'support_bot' }, '@support_bot'],
      [INBOX_TYPES.LINE, { line_channel_id: 'line-123' }, 'line-123'],
      [INBOX_TYPES.API, { inbox_identifier: 'api-123' }, 'api-123'],
    ])('returns the identifier for %s', (channelType, attributes, expected) => {
      expect(
        getInboxIdentifier({ channel_type: channelType, ...attributes })
      ).toBe(expected);
    });

    it('normalizes the Twilio WhatsApp prefix', () => {
      expect(
        getInboxIdentifier({
          channel_type: INBOX_TYPES.TWILIO,
          phone_number: 'whatsapp:+15555550102',
        })
      ).toBe('+15555550102');
    });

    it('falls back to the Twilio messaging service SID', () => {
      expect(
        getInboxIdentifier({
          channel_type: INBOX_TYPES.TWILIO,
          messaging_service_sid: 'MG123',
        })
      ).toBe('MG123');
    });

    it('preserves an existing Telegram handle prefix', () => {
      expect(
        getInboxIdentifier({
          channel_type: INBOX_TYPES.TELEGRAM,
          bot_name: '@support_bot',
        })
      ).toBe('@support_bot');
    });

    it('returns an empty identifier for missing, unknown, and opaque social identifiers', () => {
      expect(getInboxIdentifier()).toBe('');
      expect(getInboxIdentifier({ channel_type: 'Channel::Unknown' })).toBe('');
      expect(getInboxIdentifier({ channel_type: INBOX_TYPES.EMAIL })).toBe('');
      expect(
        getInboxIdentifier({
          channel_type: INBOX_TYPES.FB,
          page_id: 'page-123',
        })
      ).toBe('');
      expect(
        getInboxIdentifier({
          channel_type: INBOX_TYPES.INSTAGRAM,
          instagram_id: 'instagram-123',
        })
      ).toBe('');
      expect(
        getInboxIdentifier({
          channel_type: INBOX_TYPES.TIKTOK,
          business_id: 'business-123',
        })
      ).toBe('');
      expect(
        getInboxIdentifier({
          channel_type: INBOX_TYPES.TWITTER,
          profile_id: 'profile-123',
        })
      ).toBe('');
    });
  });

  describe('searchInboxes', () => {
    const inboxes = [
      {
        id: 1,
        name: 'Billing',
        channel_type: INBOX_TYPES.WEB,
        channel_identifier: 'billing@example.com',
      },
      {
        id: 2,
        name: 'Support',
        channel_type: INBOX_TYPES.EMAIL,
        channel_identifier: 'team@example.com',
      },
    ];

    it('preserves fuzzy name and channel type matches', () => {
      expect(searchInboxes(inboxes, 'ling')).toEqual([inboxes[0]]);
      expect(searchInboxes(inboxes, 'Web')).toEqual([inboxes[0]]);
    });

    it('adds identifier matches without duplicating primary matches', () => {
      expect(searchInboxes(inboxes, 'team@example.com')).toEqual([inboxes[1]]);
      expect(searchInboxes(inboxes, 'Billing')).toEqual([inboxes[0]]);
    });
  });

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

  describe('getVoiceCallIcon', () => {
    it('returns the WhatsApp voice glyph for the whatsapp provider', () => {
      expect(getVoiceCallIcon(VOICE_CALL_PROVIDERS.WHATSAPP)).toBe(
        'i-woot-whatsapp-voice'
      );
    });

    it('returns the generic voice-call glyph for the twilio provider', () => {
      expect(getVoiceCallIcon(VOICE_CALL_PROVIDERS.TWILIO)).toBe(
        'i-woot-voice-call'
      );
    });

    it('falls back to the generic voice-call glyph for an unknown provider', () => {
      expect(getVoiceCallIcon('unknown')).toBe('i-woot-voice-call');
      expect(getVoiceCallIcon(undefined)).toBe('i-woot-voice-call');
    });
  });

  describe('getInboxVoiceIcon', () => {
    it('returns the WhatsApp voice glyph for a WhatsApp inbox', () => {
      expect(getInboxVoiceIcon(INBOX_TYPES.WHATSAPP)).toBe(
        'i-woot-whatsapp-voice'
      );
    });

    it('returns the WhatsApp voice glyph for a Twilio WhatsApp inbox', () => {
      expect(getInboxVoiceIcon(INBOX_TYPES.TWILIO, 'whatsapp')).toBe(
        'i-woot-whatsapp-voice'
      );
    });

    it('returns the generic voice-call glyph for a Twilio voice inbox', () => {
      expect(getInboxVoiceIcon(INBOX_TYPES.TWILIO, 'sms')).toBe(
        'i-woot-voice-call'
      );
    });
  });

  describe('getInboxIconByType with voice enabled', () => {
    it('returns the WhatsApp voice glyph for a voice-enabled WhatsApp inbox', () => {
      expect(
        getInboxIconByType(INBOX_TYPES.WHATSAPP, undefined, 'line', true)
      ).toBe('i-woot-whatsapp-voice');
    });

    it('returns the generic voice-call glyph for a voice-enabled Twilio inbox', () => {
      expect(getInboxIconByType(INBOX_TYPES.TWILIO, 'sms', 'line', true)).toBe(
        'i-woot-voice-call'
      );
    });

    it('returns the normal channel icon when voice is not enabled', () => {
      expect(
        getInboxIconByType(INBOX_TYPES.WHATSAPP, undefined, 'line', false)
      ).toBe('i-woot-whatsapp');
    });
  });
});
