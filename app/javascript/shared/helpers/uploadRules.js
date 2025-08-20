import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  MAXIMUM_FILE_UPLOAD_SIZE,
  MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL,
  MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_WHATSAPP_CHANNEL,
  MAXIMUM_INSTAGRAM_AUDIO_UPLOAD_SIZE,
  MAXIMUM_INSTAGRAM_VIDEO_UPLOAD_SIZE,
  MAXIMUM_INSTAGRAM_IMAGE_UPLOAD_SIZE,
  MAXIMUM_WHATSAPP_DOCUMENT_UPLOAD_SIZE,
  MAXIMUM_WHATSAPP_AUDIO_UPLOAD_SIZE,
  MAXIMUM_WHATSAPP_VIDEO_UPLOAD_SIZE,
  MAXIMUM_WHATSAPP_IMAGE_UPLOAD_SIZE,
  ALLOWED_FILE_TYPES,
  ALLOWED_FILE_TYPES_FOR_TWILIO_WHATSAPP,
  ALLOWED_FILE_TYPES_FOR_LINE,
  ALLOWED_FILE_TYPES_FOR_INSTAGRAM,
  ALLOWED_FILE_TYPES_FOR_WHATSAPP_CLOUD,
} from 'shared/constants/messages';

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

export const getUploadRulesByChannel = params => ({
  accept: getAllowedFileTypesByChannel(params),
  maxSizeMB: getMaxUploadSizeByChannel(params),
});
