<script setup>
import { computed } from 'vue';
import ChannelSelector from '../ChannelSelector.vue';

const props = defineProps({
  channel: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['channelItemClick']);

// Channel gating (account feature flags + OAuth app IDs) has been removed so
// that every channel is always selectable from the inbox-creation grid.
const isActive = computed(() => true);

const isComingSoon = computed(() => false);

const isBeta = computed(() => {
  return ['tiktok', 'voice', 'whatsapp_call'].includes(props.channel.key);
});

const hasVoiceBadge = computed(() => {
  return ['voice', 'whatsapp_call'].includes(props.channel.key);
});

const onItemClick = () => {
  emit('channelItemClick', props.channel.key);
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
    :disabled="!isActive"
    @click="onItemClick"
  />
</template>
