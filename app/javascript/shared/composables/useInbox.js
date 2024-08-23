import { computed, ref } from 'vue';
import { useStore } from 'dashboard/composables/store';

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
};

export const INBOX_FEATURES = {
  REPLY_TO: 'replyTo',
  REPLY_TO_OUTGOING: 'replyToOutgoing',
};

export const INBOX_FEATURE_MAP = {
  [INBOX_FEATURES.REPLY_TO]: [
    INBOX_TYPES.FB,
    INBOX_TYPES.WEB,
    INBOX_TYPES.TWITTER,
    INBOX_TYPES.WHATSAPP,
    INBOX_TYPES.TELEGRAM,
    INBOX_TYPES.API,
  ],
  [INBOX_FEATURES.REPLY_TO_OUTGOING]: [
    INBOX_TYPES.WEB,
    INBOX_TYPES.TWITTER,
    INBOX_TYPES.WHATSAPP,
    INBOX_TYPES.TELEGRAM,
    INBOX_TYPES.API,
  ],
};

export function useInbox({ inboxObj, inboxId, chat, getCurrentChat }) {
  const store = useStore();
  const inbox = ref(null);
  if (inboxObj) {
    inbox.value = inboxObj;
  }
  if (inboxId) {
    inbox.value = store.getters['inboxes/getInbox'](inboxId);
  }
  if (getCurrentChat) {
    inbox.value = store.getters.getSelectedChat;
  }
  const channelType = computed(() => inbox.value.channel_type);
  const whatsAppAPIProvider = computed(() => inbox.value.provider || '');

  const isAPIInbox = computed(() => channelType.value === INBOX_TYPES.API);
  const isATwitterInbox = computed(
    () => channelType.value === INBOX_TYPES.TWITTER
  );
  const isAFacebookInbox = computed(() => channelType.value === INBOX_TYPES.FB);
  const isAWebWidgetInbox = computed(
    () => channelType.value === INBOX_TYPES.WEB
  );
  const isATwilioChannel = computed(
    () => channelType.value === INBOX_TYPES.TWILIO
  );
  const isALineChannel = computed(() => channelType.value === INBOX_TYPES.LINE);
  const isAnEmailChannel = computed(
    () => channelType.value === INBOX_TYPES.EMAIL
  );
  const isATelegramChannel = computed(
    () => channelType.value === INBOX_TYPES.TELEGRAM
  );

  const isATwilioSMSChannel = computed(() => {
    const medium = inbox.value.medium || '';
    return isATwilioChannel.value && medium === 'sms';
  });

  const isAMicrosoftInbox = computed(
    () => isAnEmailChannel.value && inbox.value.provider === 'microsoft'
  );

  const isAGoogleInbox = computed(
    () => isAnEmailChannel.value && inbox.value.provider === 'google'
  );

  const isASmsInbox = computed(
    () => channelType.value === INBOX_TYPES.SMS || isATwilioSMSChannel.value
  );

  const isATwilioWhatsAppChannel = computed(() => {
    const medium = inbox.value.medium || '';
    return isATwilioChannel.value && medium === 'whatsapp';
  });

  const isAWhatsAppCloudChannel = computed(
    () =>
      channelType.value === INBOX_TYPES.WHATSAPP &&
      whatsAppAPIProvider.value === 'whatsapp_cloud'
  );

  const is360DialogWhatsAppChannel = computed(
    () =>
      channelType.value === INBOX_TYPES.WHATSAPP &&
      whatsAppAPIProvider.value === 'default'
  );

  const chatAdditionalAttributes = computed(() => {
    return chat?.additional_attributes || {};
  });

  const isTwitterInboxTweet = computed(
    () => chatAdditionalAttributes.value.type === 'tweet'
  );

  const twilioBadge = computed(
    () => `${isATwilioSMSChannel.value ? 'sms' : 'whatsapp'}`
  );

  const twitterBadge = computed(
    () => `${isTwitterInboxTweet.value ? 'twitter-tweet' : 'twitter-dm'}`
  );

  const facebookBadge = computed(
    () => chatAdditionalAttributes.value.type || 'facebook'
  );

  const isAWhatsAppChannel = computed(
    () =>
      channelType.value === INBOX_TYPES.WHATSAPP ||
      isATwilioWhatsAppChannel.value
  );

  const inboxBadge = computed(() => {
    if (isATwitterInbox.value) return twitterBadge.value;
    if (isAFacebookInbox.value) return facebookBadge.value;
    if (isATwilioChannel.value) return twilioBadge.value;
    if (isAWhatsAppChannel.value) return 'whatsapp';
    return channelType.value;
  });

  function inboxHasFeature(feature) {
    return INBOX_FEATURE_MAP[feature]?.includes(channelType.value) ?? false;
  }

  return {
    channelType,
    whatsAppAPIProvider,
    isAMicrosoftInbox,
    isAGoogleInbox,
    isAPIInbox,
    inbox,
    isATwitterInbox,
    isAFacebookInbox,
    isAWebWidgetInbox,
    isATwilioChannel,
    isALineChannel,
    isAnEmailChannel,
    isATelegramChannel,
    isATwilioSMSChannel,
    isASmsInbox,
    isATwilioWhatsAppChannel,
    isAWhatsAppCloudChannel,
    is360DialogWhatsAppChannel,
    chatAdditionalAttributes,
    isTwitterInboxTweet,
    twilioBadge,
    twitterBadge,
    facebookBadge,
    inboxBadge,
    isAWhatsAppChannel,
    inboxHasFeature,
  };
}
