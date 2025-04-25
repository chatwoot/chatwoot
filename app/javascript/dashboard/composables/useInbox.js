import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const INBOX_FEATURES = {
  REPLY_TO: 'replyTo',
  REPLY_TO_OUTGOING: 'replyToOutgoing',
};

// This is a single source of truth for inbox features
// This is used to check if a feature is available for a particular inbox or not
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

/**
 * Composable for handling macro-related functionality
 * @returns {Object} An object containing the getMacroDropdownValues function
 */
export const useInbox = () => {
  const currentChat = useMapGetter('getSelectedChat');
  const inboxGetter = useMapGetter('inboxes/getInboxById');

  const inbox = computed(() => {
    const inboxId = currentChat.value.inbox_id;

    return useCamelCase(inboxGetter.value(inboxId), { deep: true });
  });

  const channelType = computed(() => {
    return inbox.value.channelType;
  });

  const isAPIInbox = computed(() => {
    return channelType.value === INBOX_TYPES.API;
  });

  const isAFacebookInbox = computed(() => {
    return channelType.value === INBOX_TYPES.FB;
  });

  const isAWebWidgetInbox = computed(() => {
    return channelType.value === INBOX_TYPES.WEB;
  });

  const isATwilioChannel = computed(() => {
    return channelType.value === INBOX_TYPES.TWILIO;
  });

  const isALineChannel = computed(() => {
    return channelType.value === INBOX_TYPES.LINE;
  });

  const isAnEmailChannel = computed(() => {
    return channelType.value === INBOX_TYPES.EMAIL;
  });

  const isATelegramChannel = computed(() => {
    return channelType.value === INBOX_TYPES.TELEGRAM;
  });

  const whatsAppAPIProvider = computed(() => {
    return inbox.value.provider || '';
  });

  const isAMicrosoftInbox = computed(() => {
    return isAnEmailChannel.value && inbox.value.provider === 'microsoft';
  });

  const isAGoogleInbox = computed(() => {
    return isAnEmailChannel.value && inbox.value.provider === 'google';
  });

  const isATwilioSMSChannel = computed(() => {
    const { medium: medium = '' } = inbox.value;
    return isATwilioChannel.value && medium === 'sms';
  });

  const isASmsInbox = computed(() => {
    return channelType.value === INBOX_TYPES.SMS || isATwilioSMSChannel.value;
  });

  const isATwilioWhatsAppChannel = computed(() => {
    const { medium: medium = '' } = inbox.value;
    return isATwilioChannel.value && medium === 'whatsapp';
  });

  const isAWhatsAppCloudChannel = computed(() => {
    return (
      channelType.value === INBOX_TYPES.WHATSAPP &&
      whatsAppAPIProvider.value === 'whatsapp_cloud'
    );
  });

  const is360DialogWhatsAppChannel = computed(() => {
    return (
      channelType.value === INBOX_TYPES.WHATSAPP &&
      whatsAppAPIProvider.value === 'default'
    );
  });

  const isAWhatsAppBaileysChannel = computed(() => {
    return (
      channelType.value === INBOX_TYPES.WHATSAPP &&
      whatsAppAPIProvider.value === 'baileys'
    );
  });

  const isAWhatsAppChannel = computed(() => {
    return (
      channelType.value === INBOX_TYPES.WHATSAPP ||
      isATwilioWhatsAppChannel.value
    );
  });

  const isAnInstagramChannel = computed(() => {
    return channelType.value === INBOX_TYPES.INSTAGRAM;
  });

  return {
    inbox,
    isAFacebookInbox,
    isALineChannel,
    isAPIInbox,
    isASmsInbox,
    isATelegramChannel,
    isATwilioChannel,
    isAWebWidgetInbox,
    isAWhatsAppChannel,
    isAMicrosoftInbox,
    isAGoogleInbox,
    isATwilioWhatsAppChannel,
    isAWhatsAppCloudChannel,
    is360DialogWhatsAppChannel,
    isAWhatsAppBaileysChannel,
    isAnEmailChannel,
    isAnInstagramChannel,
  };
};
