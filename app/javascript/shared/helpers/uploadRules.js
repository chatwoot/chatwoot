// Constants
export const INBOX_TYPES = {
  WEB: 'Channel::WebWidget',
  FB: 'Channel::FacebookPage',
  TWITTER: 'Channel::TwitterProfile',
  TWILIO: 'Channel::TwilioSms',
  WHATSAPP: 'Channel::Whatsapp',
  API: 'Channel::Api',
  EMAIL: 'Channel::Email',
  TELEGRAM: 'Channel::Telegram',
  LINE: 'Channel::Line',
  SMS: 'Channel::Sms',
  INSTAGRAM: 'Channel::Instagram',
  VOICE: 'Channel::Voice',
};

// Size in mega bytes
export const MAXIMUM_FILE_UPLOAD_SIZE = 40;

// Twilio
export const MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL = 5;
export const MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_WHATSAPP_CHANNEL = 5;

// Instagram
export const MAXIMUM_INSTAGRAM_AUDIO_UPLOAD_SIZE = 25;
export const MAXIMUM_INSTAGRAM_VIDEO_UPLOAD_SIZE = 25;
export const MAXIMUM_INSTAGRAM_IMAGE_UPLOAD_SIZE = 16;

// WhatsApp cloud API
export const MAXIMUM_WHATSAPP_DOCUMENT_UPLOAD_SIZE = 100;
export const MAXIMUM_WHATSAPP_AUDIO_UPLOAD_SIZE = 16;
export const MAXIMUM_WHATSAPP_VIDEO_UPLOAD_SIZE = 16;
export const MAXIMUM_WHATSAPP_IMAGE_UPLOAD_SIZE = 5;

export const ALLOWED_FILE_TYPES =
  'image/*,' +
  'audio/*,' +
  'video/*,' +
  '.3gpp,' +
  'text/csv, text/plain, application/json, application/pdf, text/rtf,' +
  'application/xml, text/xml,' +
  'application/zip, application/x-7z-compressed application/vnd.rar application/x-tar,' +
  'application/msword, application/vnd.ms-excel, application/vnd.ms-powerpoint, application/vnd.oasis.opendocument.text,' +
  'application/vnd.openxmlformats-officedocument.presentationml.presentation, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,' +
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document,';

export const ALLOWED_FILE_TYPES_FOR_TWILIO_WHATSAPP =
  'image/png, image/jpeg,' +
  'audio/mpeg, audio/opus, audio/ogg, audio/amr,' +
  'video/mp4,' +
  'application/pdf,';

// https://developers.line.biz/en/reference/messaging-api/#image-message, https://developers.line.biz/en/reference/messaging-api/#video-message
export const ALLOWED_FILE_TYPES_FOR_LINE = 'image/png, image/jpeg,video/mp4';

// https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api#requirements
export const ALLOWED_FILE_TYPES_FOR_INSTAGRAM =
  'audio/aac, audio/m4a, audio/wav, audio/mp4,' +
  'image/png, image/jpeg, image/gif,' +
  'video/mp4, video/ogg, video/avi, video/mov, video/webm';

// https://developers.facebook.com/docs/whatsapp/cloud-api/reference/media#supported-media-types
export const ALLOWED_FILE_TYPES_FOR_WHATSAPP_CLOUD =
  'audio/aac, audio/amr, audio/mp3, audio/m4a, audio/ogg,' +
  'image/jpeg, image/png,' +
  'text/plain,' +
  'video/3gp, video/mp4,' +
  'application/pdf, application/vnd.ms-excel, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document, application/vnd.ms-powerpoint, application/vnd.openxmlformats-officedocument.presentationml.presentation,';

// Declarative config
const RULES = {
  default: {
    accept: ALLOWED_FILE_TYPES,
    max: MAXIMUM_FILE_UPLOAD_SIZE,
  },

  [INBOX_TYPES.TWILIO]: {
    sms: {
      accept: ALLOWED_FILE_TYPES,
      max: MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL,
    },
    whatsapp: {
      accept: ALLOWED_FILE_TYPES_FOR_TWILIO_WHATSAPP,
      max: MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_WHATSAPP_CHANNEL,
    },
  },

  [INBOX_TYPES.LINE]: {
    '*': {
      accept: ALLOWED_FILE_TYPES_FOR_LINE,
    },
  },

  [INBOX_TYPES.INSTAGRAM]: {
    '*': {
      accept: ALLOWED_FILE_TYPES_FOR_INSTAGRAM,
      maxByCategory: {
        image: MAXIMUM_INSTAGRAM_IMAGE_UPLOAD_SIZE,
        video: MAXIMUM_INSTAGRAM_VIDEO_UPLOAD_SIZE,
        audio: MAXIMUM_INSTAGRAM_AUDIO_UPLOAD_SIZE,
      },
    },
  },

  [INBOX_TYPES.WHATSAPP]: {
    '*': {
      accept: ALLOWED_FILE_TYPES_FOR_WHATSAPP_CLOUD,
      maxByCategory: {
        image: MAXIMUM_WHATSAPP_IMAGE_UPLOAD_SIZE,
        video: MAXIMUM_WHATSAPP_VIDEO_UPLOAD_SIZE,
        audio: MAXIMUM_WHATSAPP_AUDIO_UPLOAD_SIZE,
        document: MAXIMUM_WHATSAPP_DOCUMENT_UPLOAD_SIZE,
      },
    },
  },
};

// mime → "image" | "video" | "audio" | "document"
const DOC_HEADS = new Set(['application', 'text']);

const categoryFromMime = mime => {
  const head = mime?.split('/')?.[0];
  return DOC_HEADS.has(head) ? 'document' : head;
};

const getNode = (channelType, medium) =>
  RULES[channelType]?.[medium] ?? RULES[channelType]?.['*'] ?? RULES.default;

export const getAllowedFileTypesByChannel = ({ channelType, medium } = {}) => {
  return getNode(channelType, medium).accept ?? RULES.default.accept;
};

export const getMaxUploadSizeByChannel = ({
  channelType,
  medium,
  mime,
} = {}) => {
  const node = getNode(channelType, medium);
  const cat = categoryFromMime(mime);
  return node.maxByCategory?.[cat] ?? node.max ?? RULES.default.max;
};
