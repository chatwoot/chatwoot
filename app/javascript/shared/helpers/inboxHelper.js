import { INBOX_TYPES, INBOX_FEATURE_MAP } from '../constants/inbox';

const channelsMap = {
  [INBOX_TYPES.EMAIL]: inbox => inbox.channel_type === INBOX_TYPES.EMAIL,
  [INBOX_TYPES.API]: inbox => inbox.channel_type === INBOX_TYPES.API,
  [INBOX_TYPES.TWITTER]: inbox => inbox.channel_type === INBOX_TYPES.TWITTER,
  [INBOX_TYPES.FB]: inbox => inbox.channel_type === INBOX_TYPES.FB,
  [INBOX_TYPES.WEB]: inbox => inbox.channel_type === INBOX_TYPES.WEB,
  [INBOX_TYPES.TWILIO]: inbox => inbox.channel_type === INBOX_TYPES.TWILIO,
  [INBOX_TYPES.LINE]: inbox => inbox.channel_type === INBOX_TYPES.LINE,
  [INBOX_TYPES.TELEGRAM]: inbox => inbox.channel_type === INBOX_TYPES.TELEGRAM,
  [INBOX_TYPES.SMS]: inbox => inbox.channel_type === INBOX_TYPES.SMS,
  [INBOX_TYPES.WHATSAPP]: inbox => inbox.channel_type === INBOX_TYPES.WHATSAPP,
};

export const getChannelType = inbox => inbox.channel_type;

export const getWhatsAppAPIProvider = inbox => inbox.provider || '';

export const isChannelType = (inbox, type) =>
  channelsMap[type]?.(inbox) || false;

export const isAnEmailChannel = inbox =>
  isChannelType(inbox, INBOX_TYPES.EMAIL);

export const isAMicrosoftInbox = inbox =>
  isAnEmailChannel(inbox) && inbox.provider === 'microsoft';

export const isAGoogleInbox = inbox =>
  isAnEmailChannel(inbox) && inbox.provider === 'google';
export const isAPIInbox = inbox => isChannelType(inbox, INBOX_TYPES.API);

export const isATwitterInbox = inbox =>
  isChannelType(inbox, INBOX_TYPES.TWITTER);

export const isAFacebookInbox = inbox => isChannelType(inbox, INBOX_TYPES.FB);

export const isAWebWidgetInbox = inbox => isChannelType(inbox, INBOX_TYPES.WEB);

export const isATwilioChannel = inbox =>
  isChannelType(inbox, INBOX_TYPES.TWILIO);

export const isALineChannel = inbox => isChannelType(inbox, INBOX_TYPES.LINE);

export const isATelegramChannel = inbox =>
  isChannelType(inbox, INBOX_TYPES.TELEGRAM);

export const isATwilioSMSChannel = inbox =>
  isATwilioChannel(inbox) && inbox.medium === 'sms';

export const isASmsInbox = inbox =>
  isChannelType(inbox, INBOX_TYPES.SMS) || isATwilioSMSChannel(inbox);

export const isATwilioWhatsAppChannel = inbox =>
  isATwilioChannel(inbox) && inbox.medium === 'whatsapp';

export const isAWhatsAppCloudChannel = inbox =>
  isChannelType(inbox, INBOX_TYPES.WHATSAPP) &&
  getWhatsAppAPIProvider(inbox) === 'whatsapp_cloud';

export const is360DialogWhatsAppChannel = inbox =>
  inbox.channel_type === INBOX_TYPES.WHATSAPP && inbox.provider === '360dialog';

export const isAWhatsAppChannel = inbox =>
  isChannelType(inbox, INBOX_TYPES.WHATSAPP) || isATwilioWhatsAppChannel(inbox);

export const getChatAdditionalAttributes = chat =>
  chat?.additional_attributes || {};
export const isTwitterInboxTweet = chat =>
  getChatAdditionalAttributes(chat).type === 'tweet';

export const getBadge = {
  twilio: inbox => (isATwilioSMSChannel(inbox) ? 'sms' : 'whatsapp'),
  twitter: chat => (isTwitterInboxTweet(chat) ? 'twitter-tweet' : 'twitter-dm'),
  facebook: chat => getChatAdditionalAttributes(chat).type || 'facebook',
};

export const getInboxBadge = inbox => {
  if (isATwitterInbox(inbox)) return 'twitter';
  if (isAFacebookInbox(inbox)) return 'facebook';
  if (isATwilioChannel(inbox))
    return isATwilioSMSChannel(inbox) ? 'sms' : 'whatsapp';
  if (isAWhatsAppChannel(inbox)) return 'whatsapp';
  return getChannelType(inbox);
};

export const inboxHasFeature = (inbox, feature) =>
  INBOX_FEATURE_MAP[feature]?.includes(getChannelType(inbox)) ?? false;
