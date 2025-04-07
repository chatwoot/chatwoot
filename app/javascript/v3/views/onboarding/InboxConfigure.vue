<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import OnboardingBaseModal from './BaseModal.vue';
import Facebook from './channels/Facebook.vue';
import Website from './channels/Website.vue';
import Twitter from './channels/Twitter.vue';
import Api from './channels/Api.vue';
import Email from './channels/Email.vue';
import Sms from './channels/Sms.vue';
import Whatsapp from './channels/Whatsapp.vue';
import Line from './channels/Line.vue';
import Telegram from './channels/Telegram.vue';

const props = defineProps({
  channel: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();

const channelViewList = {
  facebook: Facebook,
  website: Website,
  twitter: Twitter,
  api: Api,
  email: Email,
  sms: Sms,
  whatsapp: Whatsapp,
  line: Line,
  telegram: Telegram,
};

const ChannelComponent = computed(() => channelViewList[props.channel] || null);

const modalTitle = computed(() =>
  props.channel === 'sms' ||
  props.channel === 'whatsapp' ||
  props.channel === 'facebook'
    ? t(`INBOX_MGMT.ADD.${props.channel.toUpperCase()}.TITLE`)
    : t(`INBOX_MGMT.ADD.${props.channel.toUpperCase()}_CHANNEL.TITLE`)
);
const modalSubtitle = computed(() =>
  props.channel === 'sms' ||
  props.channel === 'whatsapp' ||
  props.channel === 'facebook'
    ? t(`INBOX_MGMT.ADD.${props.channel.toUpperCase()}.DESC`)
    : t(`INBOX_MGMT.ADD.${props.channel.toUpperCase()}_CHANNEL.DESC`)
);
</script>

<template>
  <onboarding-base-modal :title="modalTitle" :subtitle="modalSubtitle">
    <component :is="ChannelComponent" v-if="ChannelComponent" />
  </onboarding-base-modal>
</template>
