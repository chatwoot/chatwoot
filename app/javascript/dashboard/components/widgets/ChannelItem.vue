<script setup>
import { computed } from 'vue';
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

  if (key === 'voice') {
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

const isComingSoon = computed(() => {
  const { key } = props.channel;
  // Show "Coming Soon" only if the channel is marked as coming soon
  // and the corresponding feature flag is not enabled yet.
  return ['voice'].includes(key) && !isActive.value;
});

const getChannelThumbnail = () => {
  const { key } = props.channel;
  const channelImageMap = {
    website: '/assets/images/dashboard/channels/website.png',
    facebook: '/assets/images/dashboard/channels/facebook.png',
    email: '/assets/images/dashboard/channels/email.png',
    instagram: '/assets/images/dashboard/channels/instagram.png',
    tiktok: '/assets/images/dashboard/channels/tiktok.png',
    whatsapp: '/assets/images/dashboard/channels/whatsapp.png',
    twilio: '/assets/images/dashboard/channels/twilio.png',
    sms: '/assets/images/dashboard/channels/sms.png',
    telegram: '/assets/images/dashboard/channels/telegram.png',
    line: '/assets/images/dashboard/channels/line.png',
    api: '/assets/images/dashboard/channels/api.png',
    voice: '/assets/images/dashboard/channels/voice.png',
  };
  return channelImageMap[key] || '/assets/images/dashboard/channels/default.png';
};

const onItemClick = () => {
  if (isActive.value) {
    emit('channelItemClick', props.channel.key);
  }
};
</script>

<template>
  <ChannelSelector
    :class="{ inactive: !isActive }"
    :title="channel.name"
    :src="getChannelThumbnail()"
    :is-coming-soon="isComingSoon"
    @click="onItemClick"
  />
</template>
