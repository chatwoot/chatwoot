<script setup>
import { computed } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { useLocale } from 'shared/composables/useLocale';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';

const { content, createdAt } = useMessageContext();
const { resolvedLocale } = useLocale();

const readableTime = computed(() =>
  messageTimestamp(createdAt.value, 'LLL d, h:mm a', resolvedLocale.value)
);
</script>

<template>
  <BaseBubble
    v-tooltip.top="readableTime"
    class="px-3 py-1 !rounded-xl flex min-w-0 items-center gap-2"
    data-bubble-name="activity"
  >
    <span :title="content">{{ content }}</span>
  </BaseBubble>
</template>
