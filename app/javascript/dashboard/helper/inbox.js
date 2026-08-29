import { picoSearch } from '@chatwoot/pico-search';

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
  TIKTOK: 'Channel::Tiktok',
};

// Short channel-type slugs used to identify a channel without leaning on its
// Channel:: class name — e.g. onboarding channel cards and OAuth provider maps.
export const CHANNEL_TYPES = {
  WEBSITE: 'website',
  WHATSAPP: 'whatsapp',
  FACEBOOK: 'facebook',
  INSTAGRAM: 'instagram',
  TIKTOK: 'tiktok',
  TELEGRAM: 'telegram',
  LINE: 'line',
  GMAIL: 'gmail',
  OUTLOOK: 'outlook',
  SMS: 'sms',
  API: 'api',
  VOICE: 'voice',
  EMAIL: 'email',
};

// Add providers here as they gain voice capability (e.g., WhatsApp Cloud, Twilio WhatsApp)
export const VOICE_CALL_PROVIDERS = {
  TWILIO: 'twilio',
  WHATSAPP: 'whatsapp',
};

export const getVoiceCallProvider = inbox => {
  if (!inbox) return null;

  // Callers pass either snake_case (raw API) or camelCase (after camelcaseKeys) shapes.
  const channelType = inbox.channel_type || inbox.channelType;
  const voiceEnabled = inbox.voice_enabled || inbox.voiceEnabled;

  if (!voiceEnabled) return null;

  if (channelType === INBOX_TYPES.TWILIO) return VOICE_CALL_PROVIDERS.TWILIO;
  if (channelType === INBOX_TYPES.WHATSAPP)
    return VOICE_CALL_PROVIDERS.WHATSAPP;

  return null;
};

export const isVoiceCallEnabled = inbox => getVoiceCallProvider(inbox) !== null;

// Combined channel + voice-wave badge glyph per voice-call provider.
export const VOICE_CALL_ICONS = {
  [VOICE_CALL_PROVIDERS.WHATSAPP]: 'i-woot-whatsapp-voice',
  [VOICE_CALL_PROVIDERS.TWILIO]: 'i-woot-voice-call',
};

export const getVoiceCallIcon = provider =>
  VOICE_CALL_ICONS[provider] ?? VOICE_CALL_ICONS[VOICE_CALL_PROVIDERS.TWILIO];

export const TWILIO_CHANNEL_MEDIUM = {
  WHATSAPP: 'whatsapp',
  SMS: 'sms',
};

export const getInboxVoiceIcon = (channelType, medium) => {
  const isWhatsapp =
    channelType === INBOX_TYPES.WHATSAPP ||
    (channelType === INBOX_TYPES.TWILIO &&
      medium === TWILIO_CHANNEL_MEDIUM.WHATSAPP);
  return getVoiceCallIcon(
    isWhatsapp ? VOICE_CALL_PROVIDERS.WHATSAPP : VOICE_CALL_PROVIDERS.TWILIO
  );
};

const INBOX_ICON_MAP_FILL = {
  [INBOX_TYPES.WEB]: 'i-ri-global-fill',
  [INBOX_TYPES.FB]: 'i-ri-messenger-fill',
  [INBOX_TYPES.TWITTER]: 'i-ri-twitter-x-fill',
  [INBOX_TYPES.WHATSAPP]: 'i-ri-whatsapp-fill',
  [INBOX_TYPES.API]: 'i-ri-cloudy-fill',
  [INBOX_TYPES.EMAIL]: 'i-ri-mail-fill',
  [INBOX_TYPES.TELEGRAM]: 'i-ri-telegram-fill',
  [INBOX_TYPES.LINE]: 'i-ri-line-fill',
  [INBOX_TYPES.INSTAGRAM]: 'i-ri-instagram-fill',
  [INBOX_TYPES.TIKTOK]: 'i-ri-tiktok-fill',
};

const DEFAULT_ICON_FILL = 'i-ri-chat-1-fill';

const INBOX_ICON_MAP_LINE = {
  [INBOX_TYPES.WEB]: 'i-woot-website',
  [INBOX_TYPES.FB]: 'i-woot-messenger',
  [INBOX_TYPES.TWITTER]: 'i-woot-x',
  [INBOX_TYPES.WHATSAPP]: 'i-woot-whatsapp',
  [INBOX_TYPES.API]: 'i-woot-api',
  [INBOX_TYPES.EMAIL]: 'i-woot-mail',
  [INBOX_TYPES.TELEGRAM]: 'i-woot-telegram',
  [INBOX_TYPES.LINE]: 'i-woot-line',
  [INBOX_TYPES.INSTAGRAM]: 'i-woot-instagram',
  [INBOX_TYPES.TIKTOK]: 'i-woot-tiktok',
};

const DEFAULT_ICON_LINE = 'i-ri-chat-1-line';

// Instagram and TikTok already use the provider account name as the inbox name;
// their IDs are opaque routing keys and should not be shown as identifiers.
const INBOX_IDENTIFIER_RESOLVERS = {
  [INBOX_TYPES.WEB]: inbox => inbox.website_url,
  [INBOX_TYPES.EMAIL]: inbox => inbox.email,
  [INBOX_TYPES.WHATSAPP]: inbox => inbox.phone_number,
  [INBOX_TYPES.SMS]: inbox => inbox.phone_number,
  [INBOX_TYPES.FB]: inbox => inbox.page_id,
  [INBOX_TYPES.TWITTER]: inbox => inbox.profile_id,
  [INBOX_TYPES.LINE]: inbox => inbox.line_channel_id,
  [INBOX_TYPES.API]: inbox => inbox.inbox_identifier,
  [INBOX_TYPES.TWILIO]: inbox =>
    inbox.phone_number?.replace(/^whatsapp:/, '') ||
    inbox.messaging_service_sid ||
    '',
  [INBOX_TYPES.TELEGRAM]: inbox => {
    if (!inbox.bot_name) return '';
    return inbox.bot_name.startsWith('@')
      ? inbox.bot_name
      : `@${inbox.bot_name}`;
  },
};

export const getInboxIdentifier = inbox =>
  INBOX_IDENTIFIER_RESOLVERS[inbox?.channel_type]?.(inbox) || '';

export const searchInboxes = (inboxes, query) => {
  const primaryMatches = picoSearch(inboxes, query, ['name', 'channel_type']);
  const primaryMatchIds = new Set(primaryMatches.map(inbox => inbox.id));
  const identifierMatches = picoSearch(inboxes, query, ['channel_identifier']);

  return [
    ...primaryMatches,
    ...identifierMatches.filter(inbox => !primaryMatchIds.has(inbox.id)),
  ];
};

export const getReadableInboxByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'livechat';

    case INBOX_TYPES.FB:
      return 'facebook';

    case INBOX_TYPES.TWITTER:
      return 'twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber?.startsWith('whatsapp') ? 'whatsapp' : 'sms';

    case INBOX_TYPES.WHATSAPP:
      return 'whatsapp';

    case INBOX_TYPES.API:
      return 'api';

    case INBOX_TYPES.EMAIL:
      return 'email';

    case INBOX_TYPES.TELEGRAM:
      return 'telegram';

    case INBOX_TYPES.LINE:
      return 'line';

    default:
      return 'chat';
  }
};

export const getInboxClassByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'globe-desktop';

    case INBOX_TYPES.FB:
      return 'brand-facebook';

    case INBOX_TYPES.TWITTER:
      return 'brand-twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber?.startsWith('whatsapp')
        ? 'brand-whatsapp'
        : 'brand-sms';

    case INBOX_TYPES.WHATSAPP:
      return 'brand-whatsapp';

    case INBOX_TYPES.API:
      return 'cloud';

    case INBOX_TYPES.EMAIL:
      return 'mail';

    case INBOX_TYPES.TELEGRAM:
      return 'brand-telegram';

    case INBOX_TYPES.LINE:
      return 'brand-line';

    case INBOX_TYPES.INSTAGRAM:
      return 'brand-instagram';

    case INBOX_TYPES.TIKTOK:
      return 'brand-tiktok';

    default:
      return 'chat';
  }
};

export const getInboxIconByType = (
  type,
  medium,
  variant = 'fill',
  voiceEnabled = false
) => {
  if (voiceEnabled) return getInboxVoiceIcon(type, medium);

  const iconMap =
    variant === 'fill' ? INBOX_ICON_MAP_FILL : INBOX_ICON_MAP_LINE;
  const defaultIcon =
    variant === 'fill' ? DEFAULT_ICON_FILL : DEFAULT_ICON_LINE;

  // Special case for Twilio (whatsapp and sms)
  if (type === INBOX_TYPES.TWILIO && medium === 'whatsapp') {
    return iconMap[INBOX_TYPES.WHATSAPP];
  }

  return iconMap[type] ?? defaultIcon;
};

export const getInboxWarningIconClass = (type, reauthorizationRequired) => {
  const allowedInboxTypes = [INBOX_TYPES.FB, INBOX_TYPES.EMAIL];
  if (allowedInboxTypes.includes(type) && reauthorizationRequired) {
    return 'warning';
  }
  return '';
};
