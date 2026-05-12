<script setup>
import { computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
import { useMapGetter } from 'dashboard/composables/store';

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

const getUnattendedCount = useMapGetter('inboxes/getUnattendedCount');

const unattendedCount = computed(() =>
  getUnattendedCount.value(props.inbox.id)
);

const countLabel = computed(() =>
  unattendedCount.value > 99 ? '99+' : unattendedCount.value
);

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
  <span
    v-if="unattendedCount"
    dir="ltr"
    class="inline-flex h-5 min-w-5 flex-shrink-0 items-center justify-center rounded-md bg-n-ruby-9/20 px-1.5 text-[11px] font-semibold leading-none text-n-ruby-11 ring-1 ring-n-ruby-8/50 tabular-nums"
  >
    {{ countLabel }}
  </span>
  <div
    v-if="reauthorizationRequired"
    v-tooltip.top-end="$t('SIDEBAR.REAUTHORIZE')"
    class="grid place-content-center size-5 bg-n-ruby-5/60 rounded-full"
  >
    <Icon icon="i-woot-alert" class="size-3 text-n-ruby-9" />
  </div>
</template>
