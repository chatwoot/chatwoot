<script setup>
import { computed } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import BaseBubble from './Base.vue';
import MessageSourceIndicator from '../MessageSourceIndicator.vue';
import { useMessageContext } from '../provider.js';

const { content, createdAt, contentAttributes } = useMessageContext();

const readableTime = computed(() =>
  messageTimestamp(createdAt.value, 'LLL d, HH:mm')
);
</script>

<template>
  <BaseBubble
    v-tooltip.top="readableTime"
    class="px-3 py-1 !rounded-xl flex min-w-0 items-center gap-1.5"
    data-bubble-name="activity"
  >
    <MessageSourceIndicator
      :content-attributes="contentAttributes"
      icon-class="size-4 shrink-0 text-n-slate-11"
    />
    <span v-dompurify-html="content" :title="content" />
  </BaseBubble>
</template>
