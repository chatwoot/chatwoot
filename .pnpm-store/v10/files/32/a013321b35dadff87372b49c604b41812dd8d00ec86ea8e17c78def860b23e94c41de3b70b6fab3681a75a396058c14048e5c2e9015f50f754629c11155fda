// ---------- Types ----------
interface MimeGroups {
  image?: string[];
  audio?: string[];
  video?: string[];
  text?: string[];
  application?: string[];
}

interface ChannelNodeConfig {
  mimeGroups?: MimeGroups;
  extensions?: string[];
  max?: number;
  maxByCategory?: {
    image?: number;
    video?: number;
    audio?: number;
    document?: number;
  };
}

type DefaultNodeConfig = Omit<ChannelNodeConfig, 'max'> & { max: number };

interface ChannelConfig {
  [medium: string]: ChannelNodeConfig | undefined; // includes '*'
}

type CategoryType = 'image' | 'video' | 'audio' | 'document' | undefined;

interface GetChannelParams {
  channelType?: ChannelKey; // align with ChannelKey
  medium?: string;
}

interface GetMaxUploadParams extends GetChannelParams {
  mime?: string;
}

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
} as const;

// derive key type AFTER INBOX_TYPES is declared
type ChannelKey = typeof INBOX_TYPES[keyof typeof INBOX_TYPES];

// CHANNEL_CONFIGS shape: channels are optional; default node requires max
type ChannelConfigs = Partial<Record<ChannelKey, ChannelConfig>> & {
  default: DefaultNodeConfig;
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
const CHANNEL_CONFIGS: ChannelConfigs = {
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
      maxByCategory: { image: 8, audio: 25, video: 25, document: 25 },
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
 * @name DOC_HEADS
 * @description MIME type categories that should be considered "document"
 */
const DOC_HEADS = new Set<string>(['application', 'text']);

/**
 * @name categoryFromMime
 * @description Gets a high-level category name from a MIME type.
 *
 * @param {string} mime - MIME type string (e.g. "image/png").
 * @returns {"image"|"video"|"audio"|"document"|undefined} Category name.
 */
const categoryFromMime = (mime?: string): CategoryType => {
  const head = mime?.split('/')?.[0] ?? '';
  return DOC_HEADS.has(head) ? 'document' : (head as CategoryType);
};

/**
 * @name getNode
 * @description Finds the matching rule node for a channel and optional medium.
 *
 * @param {ChannelKey} [channelType] - One of INBOX_TYPES.
 * @param {string}      [medium]     - Optional sub-medium (e.g. "sms","whatsapp").
 * @returns {ChannelNodeConfig} Config node with rules.
 */
const getNode = (
  channelType?: ChannelKey,
  medium?: string
): ChannelNodeConfig => {
  if (!channelType) return CHANNEL_CONFIGS.default;

  const channelCfg = CHANNEL_CONFIGS[channelType];
  if (!channelCfg) return CHANNEL_CONFIGS.default;

  return (
    channelCfg[medium ?? '*'] ?? channelCfg['*'] ?? CHANNEL_CONFIGS.default
  );
};

/**
 * @name expandMimeGroups
 * @description Expands MIME groups and extensions into a list of strings.
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
const expandMimeGroups = (
  mimeGroups: MimeGroups = {},
  extensions: string[] = []
): string[] => {
  const mimes = Object.entries(mimeGroups).flatMap(([prefix, exts]) =>
    (exts ?? []).map((ext: string) =>
      ext === '*' ? `${prefix}/*` : `${prefix}/${ext}`
    )
  );
  return [...mimes, ...extensions];
};

// ---------- Public API ----------
/**
 * @name getAllowedFileTypesByChannel
 * @description Builds the full "accept" string for <input type="file">,
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
export const getAllowedFileTypesByChannel = ({
  channelType,
  medium,
}: GetChannelParams = {}): string => {
  const node = getNode(channelType, medium);
  const { mimeGroups, extensions } =
    !node.mimeGroups && !node.extensions ? CHANNEL_CONFIGS.default : node;

  return expandMimeGroups(mimeGroups, extensions).join(', ');
};

/**
 * @name getMaxUploadSizeByChannel
 * @description Gets the maximum allowed file size (in MB) for a channel, medium, and MIME type.
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
}: GetMaxUploadParams = {}): number => {
  const node = getNode(channelType, medium);
  const cat = categoryFromMime(mime);
  const catMax = cat ? node.maxByCategory?.[cat] : undefined;
  return catMax ?? node.max ?? CHANNEL_CONFIGS.default.max;
};
