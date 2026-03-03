<script setup>
import { useI18n } from 'vue-i18n';
import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';

const props = defineProps({
  channelType: {
    type: String,
    required: true,
  },
  integrationType: {
    type: String,
    default: '',
  },
  medium: {
    type: String,
    default: '',
  },
});
const getters = useStoreGetters();
const { t } = useI18n();
const globalConfig = computed(() => getters['globalConfig/get'].value);

const twilioChannelName = () => {
  if (props.medium === 'whatsapp') {
    return t('INBOX_MGMT.CHANNELS.WHATSAPP');
  }
  return t('INBOX_MGMT.CHANNELS.TWILIO_SMS');
};

const fallbackChannelName = () => {
  switch (props.channelType) {
    case 'Channel::FacebookPage':
      return t('INBOX_MGMT.CHANNELS.MESSENGER');
    case 'Channel::WebWidget':
      return t('INBOX_MGMT.CHANNELS.WEB_WIDGET');
    case 'Channel::TwitterProfile':
      return t('INBOX_MGMT.CHANNELS.TWITTER_PROFILE');
    case 'Channel::Whatsapp':
      return t('INBOX_MGMT.CHANNELS.WHATSAPP');
    case 'Channel::Sms':
      return t('INBOX_MGMT.CHANNELS.SMS');
    case 'Channel::Email':
      return t('INBOX_MGMT.CHANNELS.EMAIL');
    case 'Channel::Telegram':
      return t('INBOX_MGMT.CHANNELS.TELEGRAM');
    case 'Channel::Line':
      return t('INBOX_MGMT.CHANNELS.LINE');
    case 'Channel::Instagram':
      return t('INBOX_MGMT.CHANNELS.INSTAGRAM');
    case 'Channel::Tiktok':
      return t('INBOX_MGMT.CHANNELS.TIKTOK');
    case 'Channel::Voice':
      return t('INBOX_MGMT.CHANNELS.VOICE');
    default:
      return props.channelType;
  }
};

const readableChannelName = computed(() => {
  if (props.channelType === 'Channel::Api') {
    if (props.integrationType === 'whatsapp_web') {
      return t('INBOX_MGMT.CHANNELS.WHATSAPP_WEB');
    }
    return globalConfig.value.apiChannelName || t('INBOX_MGMT.CHANNELS.API');
  }
  if (props.channelType === 'Channel::TwilioSms') {
    return twilioChannelName();
  }
  return fallbackChannelName();
});
</script>

<template>
  <span>
    {{ readableChannelName }}
  </span>
</template>
