<script setup>
import { useI18n } from 'vue-i18n';
import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';

const props = defineProps({
  channelType: {
    type: String,
    required: true,
  },
  medium: {
    type: String,
    default: '',
  },
  provider: {
    type: String,
    default: '',
  },
});
const getters = useStoreGetters();
const { t } = useI18n();
const globalConfig = computed(() => getters['globalConfig/get'].value);

const i18nMap = {
  'Channel::FacebookPage': 'MESSENGER',
  'Channel::WebWidget': 'WEB_WIDGET',
  'Channel::TwitterProfile': 'TWITTER_PROFILE',
  'Channel::TwilioSms': 'TWILIO_SMS',
  'Channel::Whatsapp': 'WHATSAPP',
  'Channel::Sms': 'SMS',
  'Channel::Email': 'EMAIL',
  'Channel::Telegram': 'TELEGRAM',
  'Channel::Line': 'LINE',
  'Channel::Api': 'API',
  'Channel::Instagram': 'INSTAGRAM',
  'Channel::Tiktok': 'TIKTOK',
  'Channel::Voice': 'VOICE',
};

const twilioChannelName = () => {
  if (props.medium === 'whatsapp') {
    return t(`INBOX_MGMT.CHANNELS.WHATSAPP`);
  }
  return t(`INBOX_MGMT.CHANNELS.TWILIO_SMS`);
};

const whatsappChannelName = () => {
  if (props.provider === 'baileys') {
    return t(`INBOX_MGMT.CHANNELS.WHATSAPP_BAILEYS`);
  }
  if (props.provider === 'zapi') {
    return t(`INBOX_MGMT.CHANNELS.WHATSAPP_ZAPI`);
  }
  return t(`INBOX_MGMT.CHANNELS.WHATSAPP`);
};

const readableChannelName = computed(() => {
  if (props.channelType === 'Channel::Api') {
    return globalConfig.value.apiChannelName || t('INBOX_MGMT.CHANNELS.API');
  }
  if (props.channelType === 'Channel::TwilioSms') {
    return twilioChannelName();
  }
  if (props.channelType === 'Channel::Whatsapp') {
    return whatsappChannelName();
  }
  return t(`INBOX_MGMT.CHANNELS.${i18nMap[props.channelType]}`);
});
</script>

<template>
  <span>
    {{ readableChannelName }}
  </span>
</template>
