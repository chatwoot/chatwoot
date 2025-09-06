<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import { useMessageContext } from '../provider.js';
import { useVoiceCallStatus } from 'dashboard/composables/useVoiceCallStatus';

const { contentAttributes } = useMessageContext();

const data = computed(() => contentAttributes.value?.data);

const status = computed(() => data.value?.status);
const direction = computed(() => data.value?.call_direction);

const { labelKey, subtextKey, bubbleIconBg, bubbleIconName } =
  useVoiceCallStatus(status, direction);

const containerRingClass = computed(() => {
  return status.value === 'ringing' ? 'ring-1 ring-emerald-300' : '';
});
</script>

<template>
  <BaseBubble class="p-0 border-none" hide-meta>
    <div
      class="flex w-full max-w-xs flex-col overflow-hidden rounded-lg border border-slate-100 bg-white text-slate-900 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
      :class="containerRingClass"
    >
      <div class="flex w-full items-center gap-3 p-3">
        <div
          class="size-10 shrink-0 flex items-center justify-center rounded-full text-white"
          :class="bubbleIconBg"
        >
          <span class="text-xl" :class="bubbleIconName" />
        </div>

        <div class="flex flex-grow flex-col overflow-hidden">
          <span class="truncate text-base font-medium">{{ $t(labelKey) }}</span>
          <span class="text-xs text-slate-500">{{ $t(subtextKey) }}</span>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
