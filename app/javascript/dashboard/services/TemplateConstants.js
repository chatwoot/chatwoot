export const PLATFORMS = {
  WHATSAPP: 'whatsapp',
  TWILIO: 'twilio',
};

export const WA_COMPONENT_TYPES = {
  HEADER: 'HEADER',
  BODY: 'BODY',
  FOOTER: 'FOOTER',
  BUTTONS: 'BUTTONS',
};

export const WA_HEADER_FORMATS = {
  TEXT: 'TEXT',
  IMAGE: 'IMAGE',
  VIDEO: 'VIDEO',
  DOCUMENT: 'DOCUMENT',
};

export const WA_MEDIA_FORMATS = [
  WA_HEADER_FORMATS.IMAGE,
  WA_HEADER_FORMATS.VIDEO,
  WA_HEADER_FORMATS.DOCUMENT,
];

export const WA_BUTTON_TYPES = {
  COPY_CODE: 'COPY_CODE',
};

export const WA_PARAM_FORMATS = {
  POSITIONAL: 'POSITIONAL',
  NAMED: 'NAMED',
};

export const TWILIO_TYPE_PREFIX = 'twilio/';

export const TWILIO_TYPES = {
  TEXT: 'text',
  MEDIA: 'media',
  QUICK_REPLY: 'quick_reply',
  CALL_TO_ACTION: 'call_to_action',
  CATALOG: 'catalog',
};

export const TEMPLATE_TYPES = {
  WHATSAPP_TEXT: 'whatsapp-text',
  WHATSAPP_TEXT_HEADER: 'whatsapp-text-header',
  WHATSAPP_MEDIA_IMAGE: 'whatsapp-media-image',
  WHATSAPP_MEDIA_VIDEO: 'whatsapp-media-video',
  WHATSAPP_MEDIA_DOCUMENT: 'whatsapp-media-document',
  WHATSAPP_INTERACTIVE: 'whatsapp-interactive',
  WHATSAPP_COPY_CODE: 'whatsapp-copy-code',
  TWILIO_TEXT: 'twilio-text',
  TWILIO_MEDIA: 'twilio-media',
  TWILIO_QUICK_REPLY: 'twilio-quick-reply',
  TWILIO_CALL_TO_ACTION: 'twilio-call-to-action',
  TWILIO_CARD: 'twilio-card',
};
