<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';
import { useMessageContext } from '../provider.js';

const { attachments } = useMessageContext();

const title = computed(() => {
  const attachment = attachments.value[0];
  return attachment?.fallbackTitle ?? attachment?.fallback_title ?? '';
});
</script>

<template>
  <BaseBubble class="overflow-hidden p-3" data-bubble-name="fallback">
    <div class="flex items-center gap-2 text-n-slate-11">
      <Icon icon="i-lucide-alert-circle" class="size-4 shrink-0 text-n-amber-11" />
      <p class="mb-0 text-sm">
        {{ title }}
      </p>
    </div>
  </BaseBubble>
</template>
