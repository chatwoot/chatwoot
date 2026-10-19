<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useTrialStatus } from 'dashboard/composables/useTrialStatus';
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
const router = useRouter();
const { accountId, isOnChatwootCloud } = useAccount();
const { isTrialWithoutCard } = useTrialStatus();

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

const isComingSoon = computed(() => {
  const { key } = props.channel;
  // Show "Coming Soon" only if the channel is marked as coming soon
  // and the corresponding feature flag is not enabled yet.
  return ['voice'].includes(key) && !isActive.value;
});

const isBeta = computed(() => {
  return ['tiktok', 'voice', 'whatsapp_call'].includes(props.channel.key);
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

// Email inboxes unlock once a card is added during the trial, so the card links to billing instead of staying disabled.
const needsCardForTrial = computed(
  () =>
    props.channel.key === 'email' &&
    isTrialWithoutCard.value &&
    !props.enabledFeatures.channel_email
);

const onItemClick = () => {
  if (needsCardForTrial.value) {
    router.push({
      name: 'billing_settings_index',
      params: { accountId: accountId.value },
    });
    return;
  }

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
    :title="channel.title"
    :description="channel.description"
    :icon="channel.icon"
    :is-coming-soon="isComingSoon"
    :is-beta="isBeta"
    :has-voice-badge="hasVoiceBadge"
    :needs-card="needsCardForTrial"
    :disabled="!isActive && !canRequestTiktokAccess && !needsCardForTrial"
    @click="onItemClick"
  />
</template>
