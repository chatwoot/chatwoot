import {
  TEMPLATE_TYPES,
  TWILIO_TYPE_PREFIX,
  TWILIO_TYPES,
  WA_BUTTON_TYPES,
  WA_COMPONENT_TYPES,
  WA_HEADER_FORMATS,
} from './TemplateConstants';

/**
 * TemplateTypeDetector - Unified service to identify template types across platforms
 */
export class TemplateTypeDetector {
  static detectWhatsAppType(template) {
    const components = template.components || [];
    const header = components.find(c => c.type === WA_COMPONENT_TYPES.HEADER);
    const buttons = components.find(c => c.type === WA_COMPONENT_TYPES.BUTTONS);

    if (header?.format === WA_HEADER_FORMATS.IMAGE)
      return TEMPLATE_TYPES.WHATSAPP_MEDIA_IMAGE;
    if (header?.format === WA_HEADER_FORMATS.VIDEO)
      return TEMPLATE_TYPES.WHATSAPP_MEDIA_VIDEO;
    if (header?.format === WA_HEADER_FORMATS.DOCUMENT)
      return TEMPLATE_TYPES.WHATSAPP_MEDIA_DOCUMENT;

    if (buttons) {
      const hasCopyCode = buttons.buttons?.some(
        b => b.type === WA_BUTTON_TYPES.COPY_CODE
      );
      if (hasCopyCode) return TEMPLATE_TYPES.WHATSAPP_COPY_CODE;
      return TEMPLATE_TYPES.WHATSAPP_INTERACTIVE;
    }

    if (header?.format === WA_HEADER_FORMATS.TEXT)
      return TEMPLATE_TYPES.WHATSAPP_TEXT_HEADER;
    return TEMPLATE_TYPES.WHATSAPP_TEXT;
  }

  static detectTwilioType(template) {
    const typeFromTemplate =
      template.template_type?.replace(TWILIO_TYPE_PREFIX, '') ||
      Object.keys(template.types || {})
        .map(key => key.replace(TWILIO_TYPE_PREFIX, ''))
        .find(typeKey => typeKey);

    const templateType = (typeFromTemplate || '')
      .replace(/-/g, '_')
      .replace(/__/g, '_');

    switch (templateType) {
      case TWILIO_TYPES.MEDIA:
        return TEMPLATE_TYPES.TWILIO_MEDIA;
      case TWILIO_TYPES.QUICK_REPLY:
        return TEMPLATE_TYPES.TWILIO_QUICK_REPLY;
      case TWILIO_TYPES.CALL_TO_ACTION:
        return TEMPLATE_TYPES.TWILIO_CALL_TO_ACTION;
      case TWILIO_TYPES.CATALOG:
        return TEMPLATE_TYPES.TWILIO_CARD;
      default:
        return TEMPLATE_TYPES.TWILIO_TEXT;
    }
  }
}
