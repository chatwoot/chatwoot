<script setup>
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';

defineProps({
  inbox: {
    type: Object,
    default: () => {},
  },
});
</script>

<template>
  <div
    :title="inbox.name"
    class="flex items-center gap-0.5 text-n-slate-11 min-w-0"
  >
    <ChannelIcon :inbox="inbox" class="size-4 flex-shrink-0" />
    <span class="truncate text-label-small">
      {{ inbox.name }}
    </span>
  </div>
</template>
