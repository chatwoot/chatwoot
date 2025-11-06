<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import { useMessageContext } from '../provider.js';
import { useVoiceCallStatus } from 'dashboard/composables/useVoiceCallStatus';

const { contentAttributes, messageType } = useMessageContext();

const data = computed(() => contentAttributes.value?.data);

const status = computed(() => data.value?.status);
const direction = computed(() => {
  if (data.value?.call_direction) {
    return data.value.call_direction;
  }

  if (messageType.value === 'outgoing') return 'outbound';
  if (messageType.value === 'incoming') return 'inbound';

  return undefined;
});

const { labelKey, subtextKey, bubbleIconBg, bubbleIconName, bubbleIconText } =
  useVoiceCallStatus(status, direction);

const containerRingClass = computed(() => {
  return status.value === 'ringing' ? 'ring-1 ring-emerald-300' : '';
});
</script>

<template>
  <BaseBubble class="p-0 border-none" hide-meta>
    <div
      class="flex overflow-hidden flex-col w-full max-w-xs bg-white rounded-lg border border-slate-100 text-slate-900 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
      :class="containerRingClass"
    >
      <div class="flex gap-3 items-center p-3 w-full">
        <div
          class="flex justify-center items-center rounded-full size-10 shrink-0"
          :class="bubbleIconBg"
        >
          <span class="text-xl" :class="[bubbleIconText, bubbleIconName]" />
        </div>

        <div class="flex overflow-hidden flex-col flex-grow">
          <span class="text-base font-medium truncate">{{ $t(labelKey) }}</span>
          <span class="text-xs text-slate-500">{{ $t(subtextKey) }}</span>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
