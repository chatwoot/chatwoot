<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';

const props = defineProps({
  channel: { type: Object, required: true },
  connectedInbox: { type: Object, default: null },
});

defineEmits(['connect']);

const { t } = useI18n();

const connected = computed(() => Boolean(props.connectedInbox));
// Prefer the real connected account's name over the detected handle — the user
// may have connected a different account than the one we detected.
const connectedName = computed(
  () =>
    props.connectedInbox?.name ||
    props.channel.handle ||
    t(props.channel.labelKey)
);
</script>

<template>
  <div class="flex items-center gap-2 p-3 border-b border-n-weak">
    <div class="size-4 rounded overflow-hidden flex-shrink-0">
      <ChannelIcon
        :inbox="channel.inbox"
        use-brand-icon
        class="size-4"
        :class="{ grayscale: !connected }"
      />
    </div>
    <span class="flex-1 min-w-0 truncate text-body-main text-n-slate-12">
      {{ t(channel.labelKey) }}
    </span>
    <div
      v-if="connected"
      class="flex items-center gap-2 flex-shrink-0 text-body-main text-n-slate-11"
    >
      <span class="whitespace-nowrap">{{ connectedName }}</span>
      <span class="w-px h-3 bg-n-weak" />
      <span class="whitespace-nowrap">
        {{ t('ONBOARDING_INBOX_SETUP.CHANNELS.CONNECTED') }}
      </span>
    </div>
    <button
      v-else
      type="button"
      class="flex items-center flex-shrink-0 h-7 px-2 rounded-lg outline outline-1 outline-n-container bg-n-button-color text-button text-n-blue-11"
      @click="$emit('connect', channel)"
    >
      <span class="truncate">
        {{ t('ONBOARDING_INBOX_SETUP.CHANNELS.CONNECT') }}
      </span>
    </button>
  </div>
</template>
