/**
 * TemplateTypeDetector - Unified service to identify template types across platforms
 */
export class TemplateTypeDetector {
  /**
   * Detect WhatsApp template type based on components
   * @param {Object} template - WhatsApp template object
   * @returns {string} - Template type identifier
   */
  static detectWhatsAppType(template) {
    const components = template.components || [];
    const hasHeader = components.find(c => c.type === 'HEADER');
    const hasButtons = components.find(c => c.type === 'BUTTONS');

    // Media templates (priority: header media)
    if (hasHeader?.format === 'IMAGE') return 'whatsapp-media-image';
    if (hasHeader?.format === 'VIDEO') return 'whatsapp-media-video';
    if (hasHeader?.format === 'DOCUMENT') return 'whatsapp-media-document';

    // Interactive templates (priority: special buttons)
    if (hasButtons) {
      const copyCodeButton = hasButtons.buttons?.find(
        b => b.type === 'COPY_CODE'
      );
      if (copyCodeButton) return 'whatsapp-copy-code';
      return 'whatsapp-interactive';
    }

    // Text templates
    if (hasHeader?.format === 'TEXT') return 'whatsapp-text-header';
    return 'whatsapp-text';
  }

  /**
   * Detect Twilio template type
   * @param {Object} template - Twilio template object
   * @returns {string} - Template type identifier
   */
  static detectTwilioType(template) {
    const typeFromTemplate =
      template.template_type?.replace('twilio/', '') ||
      Object.keys(template.types || {})
        .map(key => key.replace('twilio/', ''))
        .find(typeKey => typeKey);

    const templateType = (typeFromTemplate || '')
      .replace(/-/g, '_')
      .replace(/__/g, '_');

    switch (templateType) {
      case 'media':
        return 'twilio-media';
      case 'quick_reply':
        return 'twilio-quick-reply';
      case 'call_to_action':
        return 'twilio-call-to-action';
      default:
        return 'twilio-text';
    }
  }

  /**
   * Get all supported template types
   * @returns {Array} - Array of supported template types
   */
  static getSupportedTypes() {
    return [
      // WhatsApp types
      'whatsapp-text',
      'whatsapp-text-header',
      'whatsapp-media-image',
      'whatsapp-media-video',
      'whatsapp-media-document',
      'whatsapp-interactive',
      'whatsapp-copy-code',

      // Twilio types
      'twilio-text',
      'twilio-media',
      'twilio-quick-reply',
      'twilio-call-to-action',
    ];
  }
}
