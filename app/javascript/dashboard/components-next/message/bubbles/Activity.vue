<script setup>
import { computed } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import BaseBubble from './Base.vue';
import { useTimeFormat } from 'dashboard/composables/useTimeFormat';
import { useMessageContext } from '../provider.js';

const { content, createdAt } = useMessageContext();

const { fullTimestampFormat } = useTimeFormat();

const readableTime = computed(() =>
  messageTimestamp(createdAt.value, fullTimestampFormat.value)
);
</script>

<template>
  <BaseBubble
    v-tooltip.top="readableTime"
    class="px-3 py-1 !rounded-xl flex min-w-0 items-center gap-2"
    data-bubble-name="activity"
  >
    <span v-dompurify-html="content" :title="content" />
  </BaseBubble>
</template>
