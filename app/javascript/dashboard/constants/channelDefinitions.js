// Single source of truth for channel definitions on the frontend.
//
// Every channel type is described once here; the per-channel registries in
// helper/inbox.js, composables/useInbox.js, campaignChannels.js, and the inbox
// store getters all derive from this array. Adding a new channel is a single
// entry here (plus the backend Channel::Base subclass).
export const INBOX_FEATURES = {
  REPLY_TO: 'replyTo',
  REPLY_TO_OUTGOING: 'replyToOutgoing',
};

export const VOICE_CALL_PROVIDERS = {
  TWILIO: 'twilio',
  WHATSAPP: 'whatsapp',
};

export const TWILIO_CHANNEL_MEDIUM = {
  WHATSAPP: 'whatsapp',
  SMS: 'sms',
};

// The Channel:: class-name string used by the backend (also the INBOX_TYPES
// value) for each channel. Kept here so helpers can key off it without a
// separate constant.
export const CHANNEL_TYPE = {
  WEB_WIDGET: 'Channel::WebWidget',
  FACEBOOK_PAGE: 'Channel::FacebookPage',
  TWITTER_PROFILE: 'Channel::TwitterProfile',
  TWILIO_SMS: 'Channel::TwilioSms',
  WHATSAPP: 'Channel::Whatsapp',
  API: 'Channel::Api',
  EMAIL: 'Channel::Email',
  TELEGRAM: 'Channel::Telegram',
  LINE: 'Channel::Line',
  SMS: 'Channel::Sms',
  INSTAGRAM: 'Channel::Instagram',
  TIKTOK: 'Channel::Tiktok',
};

export const CHANNEL_DEFINITIONS = [
  {
    type: CHANNEL_TYPE.WEB_WIDGET,
    paramType: 'website',
    name: 'Website',
    iconFill: 'i-ri-global-fill',
    iconLine: 'i-woot-website',
    className: 'globe-desktop',
    features: [INBOX_FEATURES.REPLY_TO, INBOX_FEATURES.REPLY_TO_OUTGOING],
    campaign: { campaignable: true, oneOff: false },
  },
  {
    type: CHANNEL_TYPE.FACEBOOK_PAGE,
    paramType: 'facebook',
    name: 'Facebook',
    iconFill: 'i-ri-messenger-fill',
    iconLine: 'i-woot-messenger',
    className: 'brand-facebook',
    features: [INBOX_FEATURES.REPLY_TO],
    campaign: { campaignable: false, oneOff: false },
  },
  {
    type: CHANNEL_TYPE.TWITTER_PROFILE,
    paramType: 'twitter',
    name: 'Twitter',
    iconFill: 'i-ri-twitter-x-fill',
    iconLine: 'i-woot-x',
    className: 'brand-twitter',
    features: [INBOX_FEATURES.REPLY_TO, INBOX_FEATURES.REPLY_TO_OUTGOING],
    campaign: { campaignable: false, oneOff: false },
  },
  {
    type: CHANNEL_TYPE.TWILIO_SMS,
    paramType: 'twilio',
    name: 'Twilio',
    iconFill: null,
    iconLine: null,
    className: null,
    features: [],
    campaign: { campaignable: true, oneOff: true },
  },
  {
    type: CHANNEL_TYPE.WHATSAPP,
    paramType: 'whatsapp',
    name: 'Whatsapp',
    iconFill: 'i-ri-whatsapp-fill',
    iconLine: 'i-woot-whatsapp',
    className: 'brand-whatsapp',
    features: [INBOX_FEATURES.REPLY_TO, INBOX_FEATURES.REPLY_TO_OUTGOING],
    campaign: { campaignable: true, oneOff: true },
  },
  {
    type: CHANNEL_TYPE.API,
    paramType: 'api',
    name: 'API',
    iconFill: 'i-ri-cloudy-fill',
    iconLine: 'i-woot-api',
    className: 'cloud',
    features: [INBOX_FEATURES.REPLY_TO, INBOX_FEATURES.REPLY_TO_OUTGOING],
    campaign: { campaignable: false, oneOff: false },
  },
  {
    type: CHANNEL_TYPE.EMAIL,
    paramType: 'email',
    name: 'Email',
    iconFill: 'i-ri-mail-fill',
    iconLine: 'i-woot-mail',
    className: 'mail',
    features: [],
    campaign: { campaignable: true, oneOff: true },
  },
  {
    type: CHANNEL_TYPE.TELEGRAM,
    paramType: 'telegram',
    name: 'Telegram',
    iconFill: 'i-ri-telegram-fill',
    iconLine: 'i-woot-telegram',
    className: 'brand-telegram',
    features: [INBOX_FEATURES.REPLY_TO, INBOX_FEATURES.REPLY_TO_OUTGOING],
    campaign: { campaignable: false, oneOff: false },
  },
  {
    type: CHANNEL_TYPE.LINE,
    paramType: 'line',
    name: 'LINE',
    iconFill: 'i-ri-line-fill',
    iconLine: 'i-woot-line',
    className: 'brand-line',
    features: [],
    campaign: { campaignable: false, oneOff: false },
  },
  {
    type: CHANNEL_TYPE.SMS,
    paramType: 'sms',
    name: 'SMS',
    iconFill: null,
    iconLine: null,
    className: null,
    features: [],
    campaign: { campaignable: true, oneOff: true },
  },
  {
    type: CHANNEL_TYPE.INSTAGRAM,
    paramType: 'instagram',
    name: 'Instagram',
    iconFill: 'i-ri-instagram-fill',
    iconLine: 'i-woot-instagram',
    className: 'brand-instagram',
    features: [],
    campaign: { campaignable: false, oneOff: false },
  },
  {
    type: CHANNEL_TYPE.TIKTOK,
    paramType: 'tiktok',
    name: 'Tiktok',
    iconFill: 'i-ri-tiktok-fill',
    iconLine: 'i-woot-tiktok',
    className: 'brand-tiktok',
    features: [INBOX_FEATURES.REPLY_TO, INBOX_FEATURES.REPLY_TO_OUTGOING],
    campaign: { campaignable: false, oneOff: false },
  },
];

// Non-channel slug map used by onboarding channel cards / OAuth providers.
// Kept here so it can grow alongside CHANNEL_DEFINITIONS.
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

// Voice-call provider badges.
export const VOICE_CALL_ICONS = {
  [VOICE_CALL_PROVIDERS.WHATSAPP]: 'i-woot-whatsapp-voice',
  [VOICE_CALL_PROVIDERS.TWILIO]: 'i-woot-voice-call',
};

const definitionByType = new Map(
  CHANNEL_DEFINITIONS.map(definition => [definition.type, definition])
);

export const getChannelDefinition = type => definitionByType.get(type);
