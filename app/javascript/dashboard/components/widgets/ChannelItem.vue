<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import ChannelSelector from '../ChannelSelector.vue';

const props = defineProps({
  channel: {
    type: Object,
    required: true,
  },
  enabledFeatures: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['channelItemClick']);
const { t } = useI18n();
const { isOnChatwootCloud } = useAccount();

const hasFbConfigured = computed(() => {
  return window.chatwootConfig?.fbAppId;
});

const hasInstagramConfigured = computed(() => {
  return window.chatwootConfig?.instagramAppId;
});

const hasTiktokConfigured = computed(() => {
  return window.chatwootConfig?.tiktokAppId;
});

const isActive = computed(() => {
  const { key } = props.channel;
  if (Object.keys(props.enabledFeatures).length === 0) {
    return false;
  }
  if (key === 'website') {
    return props.enabledFeatures.channel_website;
  }
  if (key === 'facebook') {
    return props.enabledFeatures.channel_facebook && hasFbConfigured.value;
  }
  if (key === 'email') {
    return props.enabledFeatures.channel_email;
  }

  if (key === 'instagram') {
    return (
      props.enabledFeatures.channel_instagram && hasInstagramConfigured.value
    );
  }

  if (key === 'tiktok') {
    return props.enabledFeatures.channel_tiktok && hasTiktokConfigured.value;
  }

  if (key === 'voice' || key === 'whatsapp_call') {
    return props.enabledFeatures.channel_voice;
  }

  return [
    'website',
    'twilio',
    'api',
    'whatsapp',
    'sms',
    'telegram',
    'line',
    'instagram',
    'tiktok',
    'voice',
  ].includes(key);
});

const isBeta = computed(() => {
  return ['tiktok', 'voice', 'whatsapp_call'].includes(props.channel.key);
});

const unavailableReason = computed(() => {
  if (
    props.channel.key === 'voice' &&
    Object.keys(props.enabledFeatures).length > 0 &&
    !isActive.value
  ) {
    return t('INBOX_MGMT.ADD.AUTH.CHANNEL.VOICE.NOT_ENABLED');
  }
  return null;
});

const canRequestTiktokAccess = computed(() => {
  return (
    props.channel.key === 'tiktok' &&
    isOnChatwootCloud.value &&
    hasTiktokConfigured.value &&
    Object.keys(props.enabledFeatures).length > 0 &&
    !props.enabledFeatures.channel_tiktok
  );
});

const hasVoiceBadge = computed(() => {
  return (
    ['voice', 'whatsapp_call'].includes(props.channel.key) &&
    !!props.enabledFeatures.channel_voice
  );
});

const onItemClick = () => {
  if (canRequestTiktokAccess.value) {
    window.$chatwoot?.toggle();
    return;
  }

  if (isActive.value) {
    emit('channelItemClick', props.channel.key);
  }
};
</script>

<template>
  <ChannelSelector
    v-tooltip.top="unavailableReason"
    :title="channel.title"
    :description="channel.description"
    :icon="channel.icon"
    :is-beta="isBeta"
    :has-voice-badge="hasVoiceBadge"
    :disabled="!isActive && !canRequestTiktokAccess && !unavailableReason"
    :aria-disabled="unavailableReason ? true : undefined"
    @click="onItemClick"
  />
</template>
