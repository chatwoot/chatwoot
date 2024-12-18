<script setup>
import { computed } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import BaseBubble from './Base.vue';
import { useMessageContext } from 'next/message/provider.js';

const { content, createdAt } = useMessageContext();

const readableTime = computed(() =>
  messageTimestamp(createdAt.value, 'LLL d, h:mm a')
);
</script>

<template>
  <BaseBubble
    class="px-2 py-0.5 !rounded-full flex items-center gap-2"
    data-bubble-name="activity"
  >
    <span v-dompurify-html="content" />
    <div v-if="readableTime" class="w-px h-3 rounded-full bg-n-slate-7" />
    <span class="text-n-slate-10">
      {{ readableTime }}
    </span>
  </BaseBubble>
</template>
