<script setup>
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import { computed } from 'vue';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => {},
  },
  withPhoneNumber: {
    type: Boolean,
    default: false,
  },
  withProviderConnectionStatus: {
    type: Boolean,
    default: false,
  },
});

const providerConnection = computed(() => {
  return props.inbox.provider_connection?.connection;
});
</script>

<template>
  <div :title="inbox.name" class="flex items-center gap-0.5 min-w-0">
    <ChannelIcon :inbox="inbox" class="size-4 flex-shrink-0 text-n-slate-11" />
    <span class="truncate text-label-small text-n-slate-11">
      {{ inbox.name }}
    </span>
    <span v-if="withPhoneNumber" class="ml-2 text-n-slate-12">{{
      inbox.phone_number
    }}</span>
    <span v-if="withProviderConnectionStatus" class="ml-2">
      <fluent-icon
        icon="circle"
        type="filled"
        :class="
          providerConnection === 'open' ? 'text-green-500' : 'text-n-slate-8'
        "
      />
    </span>
  </div>
</template>
