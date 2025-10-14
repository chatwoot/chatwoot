<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import Icon from 'next/icon/Icon.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';

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

const getUnreadCountForInbox = useMapGetter('getUnreadCountForInbox');

const reauthorizationRequired = computed(() => {
  return props.inbox.reauthorization_required;
});

const unreadCount = computed(() => {
  return getUnreadCountForInbox.value(props.inbox.id);
});
</script>

<template>
  <span
    class="size-5 grid place-content-center rounded-full bg-n-alpha-2"
    :class="{ 'bg-n-solid-blue': active }"
  >
    <ChannelIcon :inbox="inbox" class="size-3" />
  </span>
  <div class="flex-1 truncate min-w-0">{{ label }}</div>
  <div class="flex items-center gap-1">
    <span
      v-if="unreadCount > 0"
      class="ml-auto text-xs font-semibold px-1.5 py-0.5 rounded bg-red-500 text-white"
    >
      {{ unreadCount > 99 ? '99+' : unreadCount }}
    </span>
    <div
      v-if="reauthorizationRequired"
      v-tooltip.top-end="$t('SIDEBAR.REAUTHORIZE')"
      class="grid place-content-center size-5 bg-n-ruby-5/60 rounded-full"
    >
      <Icon icon="i-woot-alert" class="size-3 text-n-ruby-9" />
    </div>
  </div>
</template>
