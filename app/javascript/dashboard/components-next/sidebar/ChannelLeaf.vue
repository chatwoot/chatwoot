<script setup>
import { computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';

const props = defineProps({
  label: {
    type: String,
    required: true,
  },
  // eslint-disable-next-line vue/no-unused-properties
  active: {
    type: Boolean,
    default: false,
  },
  inbox: {
    type: Object,
    required: true,
  },
});

const reauthorizationRequired = computed(() => {
  return props.inbox.reauthorization_required;
});

const channelColor = computed(() => {
  const type = props.inbox.channel_type;
  const medium = props.inbox.medium;

  if (
    type === 'Channel::Whatsapp' ||
    (type === 'Channel::TwilioSms' && medium === 'whatsapp')
  ) {
    return 'color: #16a34a;'; // Green
  }
  if (type === 'Channel::FacebookPage') {
    return 'color: #2563eb;'; // Blue
  }
  if (type === 'Channel::Instagram') {
    return 'color: #9333ea;'; // Purple
  }
  if (type === 'Channel::Telegram') {
    return 'color: #0ea5e9;'; // Light Blue
  }
  if (type === 'Channel::Api') {
    return 'color: #ea580c;'; // Orange
  }
  if (type === 'Channel::Email') {
    return 'color: #db2777;'; // Pink
  }
  return '';
});
</script>

<template>
  <span class="size-5 grid place-content-center rounded-full bg-n-alpha-2">
    <ChannelIcon :inbox="inbox" class="size-3" :style="channelColor" />
  </span>
  <div class="flex-1 truncate min-w-0">{{ label }}</div>
  <div
    v-if="reauthorizationRequired"
    v-tooltip.top-end="$t('SIDEBAR.REAUTHORIZE')"
    class="grid place-content-center size-5 bg-n-ruby-5/60 rounded-full"
  >
    <Icon icon="i-woot-alert" class="size-3 text-n-ruby-9" />
  </div>
</template>
