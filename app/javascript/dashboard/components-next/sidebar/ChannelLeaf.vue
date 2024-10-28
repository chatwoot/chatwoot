<script setup>
import { computed } from 'vue';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  label: {
    type: String,
    required: true,
  },
  active: {
    type: Boolean,
    default: false,
  },
  inbox: {
    type: Object,
    required: true,
  },
});

const channelTypeIconMap = {
  'Channel::Api': 'i-ri-cloudy-fill',
  'Channel::Email': 'i-ri-mail-fill',
  'Channel::FacebookPage': 'i-ri-messenger-fill',
  'Channel::Line': 'i-ri-line-fill',
  'Channel::Sms': 'i-ri-chat-1-fill',
  'Channel::Telegram': 'i-ri-telegram-fill',
  'Channel::TwilioSms': 'i-ri-chat-1-fill',
  'Channel::TwitterProfile': 'i-ri-twitter-x-fill',
  'Channel::WebWidget': 'i-ri-global-fill',
  'Channel::Whatsapp': 'i-ri-whatsapp-fill',
};

const providerIconMap = {
  microsoft: 'i-ri-microsoft-fill',
  google: 'i-ri-google-fill',
};

const channelIcon = computed(() => {
  const type = props.inbox.channel_type;
  let icon = channelTypeIconMap[type];

  if (type === 'Channel::Email' && props.inbox.provider) {
    if (Object.keys(providerIconMap).includes(props.inbox.provider)) {
      icon = providerIconMap[props.inbox.provider];
    }
  }

  return icon ?? 'i-ri-global-fill';
});

const reauthorizationRequired = computed(() => {
  return props.inbox.reauthorization_required;
});
</script>

<template>
  <span
    class="size-4 grid place-content-center rounded-full bg-n-alpha-2"
    :class="{ 'bg-n-solid-blue': active }"
  >
    <Icon :icon="channelIcon" class="size-3" />
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
