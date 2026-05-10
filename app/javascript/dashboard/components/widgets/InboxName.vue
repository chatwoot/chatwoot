<script setup>
import { computed, toRef } from 'vue';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import { useChannelColor } from 'dashboard/components-next/icon/provider';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => {},
  },
});

const channelColor = useChannelColor(toRef(props, 'inbox'));

const badgeStyle = computed(() => ({
  backgroundColor: `${channelColor.value}0D`,
  color: channelColor.value,
}));
</script>

<template>
  <div class="flex items-center min-w-0">
    <div
      class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-md text-[11px] font-medium leading-none min-w-0 max-w-full"
      :style="badgeStyle"
    >
      <ChannelIcon
        :inbox="inbox"
        class="size-3 flex-shrink-0"
        :style="{ color: channelColor }"
      />
      <span class="truncate">
        {{ inbox.name }}
      </span>
    </div>
  </div>
</template>
