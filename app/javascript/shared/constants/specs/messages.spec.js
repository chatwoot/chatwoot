import { describe, it, expect } from 'vitest';
import {
  MESSAGE_STATUS,
  MESSAGE_TYPE,
  CONVERSATION_STATUS,
  CONVERSATION_PRIORITY,
  CONVERSATION_PRIORITY_ORDER,
  MAXIMUM_FILE_UPLOAD_SIZE,
  MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL,
  ALLOWED_FILE_TYPES,
  ALLOWED_FILE_TYPES_FOR_TWILIO_WHATSAPP,
  ALLOWED_FILE_TYPES_FOR_LINE,
  ALLOWED_FILE_TYPES_FOR_INSTAGRAM,
  CSAT_RATINGS,
} from '../messages';

describe('messages constants', () => {
  describe('MESSAGE_STATUS', () => {
    it('exports correct message status constants', () => {
      expect(MESSAGE_STATUS).toEqual({
        FAILED: 'failed',
        SENT: 'sent',
        DELIVERED: 'delivered',
        READ: 'read',
        PROGRESS: 'progress',
      });
    });
  });

  describe('MESSAGE_TYPE', () => {
    it('exports correct message type constants', () => {
      expect(MESSAGE_TYPE).toEqual({
        INCOMING: 0,
        OUTGOING: 1,
        ACTIVITY: 2,
        TEMPLATE: 3,
      });
    });
  });

  describe('CONVERSATION_STATUS', () => {
    it('exports correct conversation status constants', () => {
      expect(CONVERSATION_STATUS).toEqual({
        OPEN: 'open',
        RESOLVED: 'resolved',
        PENDING: 'pending',
        SNOOZED: 'snoozed',
      });
    });
  });

  describe('CONVERSATION_PRIORITY', () => {
    it('exports correct conversation priority constants', () => {
      expect(CONVERSATION_PRIORITY).toEqual({
        URGENT: 'urgent',
        HIGH: 'high',
        LOW: 'low',
        MEDIUM: 'medium',
      });
    });
  });

  describe('CONVERSATION_PRIORITY_ORDER', () => {
    it('exports correct priority order mapping', () => {
      expect(CONVERSATION_PRIORITY_ORDER).toEqual({
        urgent: 4,
        high: 3,
        medium: 2,
        low: 1,
      });
    });
  });

  describe('file upload constants', () => {
    it('defines correct maximum file upload sizes', () => {
      expect(MAXIMUM_FILE_UPLOAD_SIZE).toBe(40);
      expect(MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL).toBe(5);
    });

    it('defines allowed file types for general uploads', () => {
      expect(ALLOWED_FILE_TYPES).toContain('image/*');
      expect(ALLOWED_FILE_TYPES).toContain('audio/*');
      expect(ALLOWED_FILE_TYPES).toContain('video/*');
      expect(ALLOWED_FILE_TYPES).toContain('application/pdf');
    });

    it('defines allowed file types for Twilio WhatsApp', () => {
      expect(ALLOWED_FILE_TYPES_FOR_TWILIO_WHATSAPP).toEqual(
        'image/png, image/jpeg,' +
          'audio/mpeg, audio/opus, audio/ogg, audio/amr,' +
          'video/mp4,' +
          'application/pdf,'
      );
    });

    it('defines allowed file types for LINE', () => {
      expect(ALLOWED_FILE_TYPES_FOR_LINE).toBe(
        'image/png, image/jpeg,video/mp4'
      );
    });
  });

  describe('ALLOWED_FILE_TYPES_FOR_INSTAGRAM', () => {
    it('includes original supported file types', () => {
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain('image/png');
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain('image/jpeg');
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain('video/mp4');
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain('video/mov');
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain('video/webm');
    });

    it('includes newly added audio file types', () => {
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain('audio/aac');
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain('audio/mp4');
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain('audio/wav');
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain('audio/mpeg');
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain('audio/ogg');
    });

    it('contains all expected file types in correct format', () => {
      const expectedTypes = [
        'image/png',
        'image/jpeg',
        'video/mp4',
        'video/mov',
        'video/webm',
        'audio/aac',
        'audio/mp4',
        'audio/wav',
        'audio/mpeg',
        'audio/ogg',
      ];

      expectedTypes.forEach(type => {
        expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain(type);
      });
    });

    it('has the complete expected value', () => {
      expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toBe(
        'image/png, image/jpeg, video/mp4, video/mov, video/webm, audio/aac, audio/mp4, audio/wav, audio/mpeg, audio/ogg'
      );
    });

    it('contains exactly 10 file type entries', () => {
      const types = ALLOWED_FILE_TYPES_FOR_INSTAGRAM.split(', ');
      expect(types).toHaveLength(10);
    });

    it('separates file types with comma and space', () => {
      // Verify the format is consistent (comma + space separation)
      const hasCorrectFormat = /^[^,]+(?:, [^,]+)*$/.test(
        ALLOWED_FILE_TYPES_FOR_INSTAGRAM
      );
      expect(hasCorrectFormat).toBe(true);
    });

    it('supports Instagram-compatible audio formats for conversion service', () => {
      // Verify formats that are supported natively by Instagram
      const instagramNativeFormats = ['audio/aac', 'audio/mp4', 'audio/wav'];
      instagramNativeFormats.forEach(format => {
        expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain(format);
      });

      // Verify formats that need conversion
      const conversionRequiredFormats = ['audio/mpeg', 'audio/ogg'];
      conversionRequiredFormats.forEach(format => {
        expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain(format);
      });
    });
  });

  describe('CSAT_RATINGS', () => {
    it('exports CSAT ratings array', () => {
      expect(Array.isArray(CSAT_RATINGS)).toBe(true);
      expect(CSAT_RATINGS.length).toBeGreaterThan(0);
    });

    it('has correctly structured rating objects', () => {
      CSAT_RATINGS.forEach(rating => {
        expect(rating).toHaveProperty('key');
        expect(rating).toHaveProperty('translationKey');
        expect(rating).toHaveProperty('emoji');
        expect(rating).toHaveProperty('value');
        expect(rating).toHaveProperty('color');
        expect(typeof rating.key).toBe('string');
        expect(typeof rating.translationKey).toBe('string');
        expect(typeof rating.emoji).toBe('string');
        expect(typeof rating.value).toBe('number');
        expect(typeof rating.color).toBe('string');
      });
    });
  });

  describe('audio file type validation', () => {
    it('ensures audio formats are compatible with Instagram API requirements', () => {
      const audioFormats = [
        'audio/aac', // Native Instagram format
        'audio/mp4', // Native Instagram format (M4A)
        'audio/wav', // Native Instagram format
        'audio/mpeg', // Needs conversion to MP4
        'audio/ogg', // Needs conversion to MP4
      ];

      audioFormats.forEach(format => {
        expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain(format);
      });
    });

    it('includes audio formats that the conversion service can handle', () => {
      // Formats that can be converted by Instagram::AudioConversionService
      const convertibleFormats = ['audio/mpeg', 'audio/ogg'];
      // Formats that are natively supported
      const nativeFormats = ['audio/aac', 'audio/mp4', 'audio/wav'];

      [...convertibleFormats, ...nativeFormats].forEach(format => {
        expect(ALLOWED_FILE_TYPES_FOR_INSTAGRAM).toContain(format);
      });
    });
  });
});
