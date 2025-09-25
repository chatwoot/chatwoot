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
  <div class="flex items-center text-n-slate-11 text-xs min-w-0">
    <ChannelIcon
      :inbox="inbox"
      class="size-3 ltr:mr-1 rtl:ml-1 flex-shrink-0"
    />
    <span class="truncate">
      {{ inbox.name }}
    </span>
  </div>
</template>
