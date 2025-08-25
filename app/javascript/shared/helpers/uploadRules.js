// ---------- Channels ----------
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

// ---------- Docs ----------
/**
 * LINE: https://developers.line.biz/en/reference/messaging-api/#image-message, https://developers.line.biz/en/reference/messaging-api/#video-message
 * INSTAGRAM: https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api#requirements
 * WHATSAPP CLOUD: https://developers.facebook.com/docs/whatsapp/cloud-api/reference/media#supported-media-types
 * TWILIO WHATSAPP: https://www.twilio.com/docs/whatsapp/guidance-whatsapp-media-messages
 * TWILIO SMS: https://www.twilio.com/docs/messaging/guides/accepted-mime-types
 */

// ---------- Central config ----------
/**
 * Upload rules configuration.
 *
 * Each node can define:
 * - mimeGroups: { prefix: [exts] }
 *   Example: { image: ["png","jpeg"] } → ["image/png","image/jpeg"]
 *   Special: ["*"] → allow all (e.g. "image/*").
 * - extensions: Raw file extensions (e.g. [".3gpp"]).
 * - max: Default maximum size in MB for this channel.
 * - maxByCategory: Override per category (image, video, audio, document).
 *
 * Resolution order:
 *  1. channel + medium (e.g. TWILIO.whatsapp)
 *  2. channel + "*" fallback
 *  3. global default
 */
const CHANNEL_CONFIGS = {
  default: {
    mimeGroups: {
      image: ['*'],
      audio: ['*'],
      video: ['*'],
      text: ['csv', 'plain', 'rtf', 'xml'],
      application: [
        'json',
        'pdf',
        'xml',
        'zip',
        'x-7z-compressed',
        'vnd.rar',
        'x-tar',
        'msword',
        'vnd.ms-excel',
        'vnd.ms-powerpoint',
        'vnd.oasis.opendocument.text',
        'vnd.openxmlformats-officedocument.presentationml.presentation',
        'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      ],
    },
    extensions: ['.3gpp'],
    max: 40,
  },

  [INBOX_TYPES.WHATSAPP]: {
    '*': {
      mimeGroups: {
        audio: ['aac', 'amr', 'mp3', 'm4a', 'ogg'],
        image: ['jpeg', 'png'],
        video: ['3gp', 'mp4'],
        text: ['plain'],
        application: [
          'pdf',
          'vnd.ms-excel',
          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'msword',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
          'vnd.ms-powerpoint',
          'vnd.openxmlformats-officedocument.presentationml.presentation',
        ],
      },
      maxByCategory: { image: 5, video: 16, audio: 16, document: 100 },
    },
  },

  [INBOX_TYPES.INSTAGRAM]: {
    '*': {
      mimeGroups: {
        audio: ['aac', 'm4a', 'wav', 'mp4'],
        image: ['png', 'jpeg', 'gif'],
        video: ['mp4', 'ogg', 'avi', 'mov', 'webm'],
      },
      maxByCategory: { image: 16, video: 25, audio: 25 },
    },
  },

  [INBOX_TYPES.FB]: {
    '*': {
      mimeGroups: {
        audio: ['aac', 'm4a', 'wav', 'mp4'],
        image: ['png', 'jpeg', 'gif'],
        video: ['mp4', 'ogg', 'avi', 'mov', 'webm'],
        text: ['plain'],
        application: [
          'pdf',
          'vnd.ms-excel',
          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'msword',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
          'vnd.ms-powerpoint',
          'vnd.openxmlformats-officedocument.presentationml.presentation',
        ],
      },
      maxByCategory: {
        image: 8,
        audio: 25,
        video: 25,
        document: 25,
      },
    },
  },

  [INBOX_TYPES.LINE]: {
    '*': {
      mimeGroups: {
        image: ['png', 'jpeg'],
        video: ['mp4'],
      },
      maxByCategory: { image: 10 },
    },
  },

  [INBOX_TYPES.TWILIO]: {
    sms: { max: 5 },
    whatsapp: {
      mimeGroups: {
        image: ['png', 'jpeg'],
        audio: ['mpeg', 'opus', 'ogg', 'amr'],
        video: ['mp4'],
        application: ['pdf'],
      },
      max: 5,
    },
  },
};

// ---------- Helpers ----------
/**
 * MIME type categories that should be considered "document"
 */
const DOC_HEADS = new Set(['application', 'text']);

/**
 * Gets a high-level category name from a MIME type.
 *
 * @param {string} mime - MIME type string (e.g. "image/png").
 * @returns {"image"|"video"|"audio"|"document"|undefined} Category name.
 */
const categoryFromMime = mime => {
  const head = mime?.split('/')?.[0];
  return DOC_HEADS.has(head) ? 'document' : head;
};

/**
 * Finds the matching rule node for a channel and optional medium.
 *
 * @param {string} channelType - One of INBOX_TYPES.
 * @param {string} [medium] - Optional sub-medium (e.g. "sms","whatsapp").
 * @returns {Object} Config node with rules.
 */
const getNode = (channelType, medium) =>
  CHANNEL_CONFIGS[channelType]?.[medium] ??
  CHANNEL_CONFIGS[channelType]?.['*'] ??
  CHANNEL_CONFIGS.default;

/**
 * Expands MIME groups and extensions into a list of strings.
 *
 * Examples:
 *  { image: ["*"] }         → ["image/*"]
 *  { image: ["png"] }       → ["image/png"]
 *  { application: ["pdf"] } → ["application/pdf"]
 *  extensions: [".3gpp"]    → [".3gpp"]
 *
 * @param {Object} mimeGroups - Grouped MIME suffixes by prefix.
 * @param {string[]} extensions - Extra raw extensions.
 * @returns {string[]} Expanded list of MIME/extension strings.
 */
const expandMimeGroups = (mimeGroups = {}, extensions = []) => {
  const mimes = Object.entries(mimeGroups).flatMap(([prefix, exts]) =>
    exts.map(ext => (ext === '*' ? `${prefix}/*` : `${prefix}/${ext}`))
  );
  return [...mimes, ...extensions];
};

// ---------- Public API ----------
/**
 * Builds the full "accept" string for <input type="file">,
 * based on channel + medium rules.
 *
 * @param {Object} params
 * @param {string} [params.channelType] - Channel type (from INBOX_TYPES).
 * @param {string} [params.medium] - Medium under the channel.
 * @returns {string} Comma-separated list of allowed MIME types/extensions.
 *
 * @example
 * getAllowedFileTypesByChannel({ channelType: INBOX_TYPES.WHATSAPP });
 * → "audio/aac, audio/amr, image/jpeg, image/png, video/3gp, ..."
 */
export const getAllowedFileTypesByChannel = ({ channelType, medium } = {}) => {
  const node = getNode(channelType, medium);
  const { mimeGroups, extensions } =
    !node.mimeGroups && !node.extensions ? CHANNEL_CONFIGS.default : node;

  return expandMimeGroups(mimeGroups, extensions).join(', ');
};

/**
 * Gets the maximum allowed file size (in MB) for a channel, medium, and MIME type.
 *
 * Priority:
 * - Category-specific size (image/video/audio/document).
 * - Channel/medium-level max.
 * - Global default max.
 *
 * @param {Object} params
 * @param {string} [params.channelType] - Channel type (from INBOX_TYPES).
 * @param {string} [params.medium] - Medium under the channel.
 * @param {string} [params.mime] - MIME type string (for category lookup).
 * @returns {number} Maximum file size in MB.
 *
 * @example
 * getMaxUploadSizeByChannel({ channelType: INBOX_TYPES.WHATSAPP, mime: "image/png" });
 * → 5
 */
export const getMaxUploadSizeByChannel = ({
  channelType,
  medium,
  mime,
} = {}) => {
  const node = getNode(channelType, medium);
  const cat = categoryFromMime(mime);
  return node.maxByCategory?.[cat] ?? node.max ?? CHANNEL_CONFIGS.default.max;
};
