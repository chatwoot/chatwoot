// @vitest-environment node

import { describe, it, expect } from 'vitest';

import { TemplateTypeDetector } from './TemplateTypeDetector';

describe('TemplateTypeDetector', () => {
  it('detects Twilio call-to-action from hyphenated template_type', () => {
    const template = {
      template_type: 'call-to-action',
      types: {
        'twilio/call-to-action': {},
      },
    };

    expect(TemplateTypeDetector.detectTwilioType(template)).toBe(
      'twilio-call-to-action'
    );
  });

  it('detects Twilio call-to-action when only types key is present', () => {
    const template = {
      types: {
        'twilio/call_to_action': {},
      },
    };

    expect(TemplateTypeDetector.detectTwilioType(template)).toBe(
      'twilio-call-to-action'
    );
  });

  it('detects Twilio quick reply', () => {
    const template = {
      template_type: 'quick_reply',
      types: {
        'twilio/quick-reply': {},
      },
    };

    expect(TemplateTypeDetector.detectTwilioType(template)).toBe(
      'twilio-quick-reply'
    );
  });

  it('detects WhatsApp text-with-header and media', () => {
    const base = {
      components: [
        { type: 'HEADER', format: 'TEXT', text: 'Header' },
        { type: 'BODY', text: 'Body' },
      ],
    };

    expect(TemplateTypeDetector.detectWhatsAppType(base)).toBe(
      'whatsapp-text-header'
    );

    const withImage = {
      ...base,
      components: [{ type: 'HEADER', format: 'IMAGE' }, base.components[1]],
    };
    expect(TemplateTypeDetector.detectWhatsAppType(withImage)).toBe(
      'whatsapp-media-image'
    );
  });

  it('detects WhatsApp copy code vs call-to-action buttons', () => {
    const copyCode = {
      components: [
        { type: 'BODY', text: 'Hi' },
        {
          type: 'BUTTONS',
          buttons: [{ type: 'COPY_CODE', text: 'Copy offer code' }],
        },
      ],
    };

    const callToAction = {
      components: [
        { type: 'BODY', text: 'Hi' },
        {
          type: 'BUTTONS',
          buttons: [{ type: 'URL', text: 'Visit website' }],
        },
      ],
    };

    expect(TemplateTypeDetector.detectWhatsAppType(copyCode)).toBe(
      'whatsapp-copy-code'
    );
    expect(TemplateTypeDetector.detectWhatsAppType(callToAction)).toBe(
      'whatsapp-interactive'
    );
  });

  it('detects Twilio media', () => {
    const template = {
      template_type: 'media',
      types: { 'twilio/media': {} },
    };

    expect(TemplateTypeDetector.detectTwilioType(template)).toBe(
      'twilio-media'
    );
  });
});
