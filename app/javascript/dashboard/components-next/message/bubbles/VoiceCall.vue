<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import { useMessageContext } from '../provider.js';
import { useFunctionGetter } from 'dashboard/composables/store';
import { useVoiceCallStatus } from 'dashboard/composables/useVoiceCallStatus';

const { contentAttributes, conversationId } = useMessageContext();

const conversation = useFunctionGetter('getConversationById', conversationId);

const data = computed(() => contentAttributes.value?.data || {});

const status = computed(() => {
  const msgStatus = data.value?.status;
  if (msgStatus) return msgStatus;
  const convStatus = conversation.value?.additional_attributes?.call_status;
  return convStatus || 'ringing';
});

const direction = computed(
  () =>
    data.value?.call_direction ||
    conversation.value?.additional_attributes?.call_direction ||
    'inbound'
);
const { labelKey, subtextKey, bubbleIconName, bubbleIconBg } =
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
          <span class="text-xl" :class="[bubbleIconName]" />
        </div>

        <div class="flex flex-grow flex-col overflow-hidden">
          <span class="truncate text-base font-medium">{{ $t(labelKey) }}</span>
          <span class="text-xs text-slate-500">{{ $t(subtextKey) }}</span>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
