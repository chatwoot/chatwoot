<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';

const { attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});
</script>

<template>
  <BaseBubble class="overflow-hidden p-3" data-bubble-name="embed">
    <div>
      <iframe :src="attachment.dataUrl" />
    </div>
  </BaseBubble>
</template>
