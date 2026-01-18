<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
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

const store = useStore();

const reauthorizationRequired = computed(() => {
  return props.inbox.reauthorization_required;
});

const unreadCount = computed(() =>
  store.getters['conversationStats/getUnreadCountForInbox'](props.inbox.id)
);

const displayCount = computed(() =>
  unreadCount.value > 99 ? '99+' : unreadCount.value
);
</script>

<template>
  <span
    class="size-5 grid place-content-center rounded-full bg-n-alpha-2"
    :class="{ 'bg-n-solid-blue': active }"
  >
    <ChannelIcon :inbox="inbox" class="size-3" />
  </span>
  <div class="flex-1 truncate min-w-0">{{ label }}</div>
  <span
    v-if="unreadCount > 0"
    class="rounded-md text-xs leading-5 font-medium text-center outline outline-1 px-1 flex-shrink-0"
    :class="{
      'text-n-blue-text outline-n-slate-6': active,
      'text-n-slate-11 outline-n-strong': !active,
    }"
  >
    {{ displayCount }}
  </span>
  <div
    v-if="reauthorizationRequired"
    v-tooltip.top-end="$t('SIDEBAR.REAUTHORIZE')"
    class="grid place-content-center size-5 bg-n-ruby-5/60 rounded-full"
  >
    <Icon icon="i-woot-alert" class="size-3 text-n-ruby-9" />
  </div>
</template>
