import {
  CHANNEL_TYPE,
  CHANNEL_TYPES as channelTypes,
  CHANNEL_DEFINITIONS,
  getChannelDefinition,
  VOICE_CALL_PROVIDERS as voiceCallProviders,
  VOICE_CALL_ICONS as voiceCallIcons,
  TWILIO_CHANNEL_MEDIUM as twilioChannelMedium,
} from 'dashboard/constants/channelDefinitions';

// Named keys for each channel's backend class-name string. Derived from the
// single channelDefinitions source of truth.
export const INBOX_TYPES = {
  WEB: CHANNEL_TYPE.WEB_WIDGET,
  FB: CHANNEL_TYPE.FACEBOOK_PAGE,
  TWITTER: CHANNEL_TYPE.TWITTER_PROFILE,
  TWILIO: CHANNEL_TYPE.TWILIO_SMS,
  WHATSAPP: CHANNEL_TYPE.WHATSAPP,
  API: CHANNEL_TYPE.API,
  EMAIL: CHANNEL_TYPE.EMAIL,
  TELEGRAM: CHANNEL_TYPE.TELEGRAM,
  LINE: CHANNEL_TYPE.LINE,
  SMS: CHANNEL_TYPE.SMS,
  INSTAGRAM: CHANNEL_TYPE.INSTAGRAM,
  TIKTOK: CHANNEL_TYPE.TIKTOK,
};

// Short channel-type slugs used to identify a channel without leaning on its
// Channel:: class name — e.g. onboarding channel cards and OAuth provider maps.
export const CHANNEL_TYPES = channelTypes;

export const VOICE_CALL_PROVIDERS = voiceCallProviders;

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

export const VOICE_CALL_ICONS = voiceCallIcons;

export const getVoiceCallIcon = provider =>
  VOICE_CALL_ICONS[provider] ?? VOICE_CALL_ICONS[VOICE_CALL_PROVIDERS.TWILIO];

export const TWILIO_CHANNEL_MEDIUM = twilioChannelMedium;

export const getInboxVoiceIcon = (channelType, medium) => {
  const isWhatsapp =
    channelType === INBOX_TYPES.WHATSAPP ||
    (channelType === INBOX_TYPES.TWILIO &&
      medium === TWILIO_CHANNEL_MEDIUM.WHATSAPP);
  return getVoiceCallIcon(
    isWhatsapp ? VOICE_CALL_PROVIDERS.WHATSAPP : VOICE_CALL_PROVIDERS.TWILIO
  );
};

const INBOX_ICON_MAP_FILL = Object.fromEntries(
  CHANNEL_DEFINITIONS.filter(definition => definition.iconFill).map(
    definition => [definition.type, definition.iconFill]
  )
);

const DEFAULT_ICON_FILL = 'i-ri-chat-1-fill';

const INBOX_ICON_MAP_LINE = Object.fromEntries(
  CHANNEL_DEFINITIONS.filter(definition => definition.iconLine).map(
    definition => [definition.type, definition.iconLine]
  )
);

const DEFAULT_ICON_LINE = 'i-ri-chat-1-line';

export const getInboxSource = (type, phoneNumber, inbox) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return inbox.website_url || '';

    case INBOX_TYPES.TWILIO:
    case INBOX_TYPES.WHATSAPP:
      return phoneNumber || '';

    case INBOX_TYPES.EMAIL:
      return inbox.email || '';

    default:
      return '';
  }
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
  if (type === INBOX_TYPES.TWILIO) {
    return phoneNumber?.startsWith('whatsapp') ? 'brand-whatsapp' : 'brand-sms';
  }

  return getChannelDefinition(type)?.className || 'chat';
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
