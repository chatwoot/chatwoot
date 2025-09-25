<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';

const { contentAttributes } = useMessageContext();

const summaryText = computed(
  () => contentAttributes.value?.summary_text || 'Quick Reply'
);
const items = computed(() => contentAttributes.value?.items || []);

const handleReplyClick = item => {
  // In a real implementation, this would send the reply back to the server
  console.log('Quick reply selected:', item);
};
</script>

<template>
  <BaseBubble>
    <div class="apple-quick-reply max-w-sm">
      <!-- Summary Text -->
      <div class="mb-3 p-3 bg-n-alpha-2 rounded-lg">
        <p class="text-sm text-n-slate-12">
          {{ summaryText }}
        </p>
      </div>

      <!-- Quick Reply Buttons -->
      <div class="flex flex-wrap gap-2">
        <button
          v-for="item in items"
          :key="item.identifier"
          class="px-4 py-2 bg-n-solid-blue text-n-slate-12 rounded-full text-sm font-medium hover:bg-n-solid-blue/80 transition-colors border border-n-blue-8 hover:border-n-blue-9"
          @click="handleReplyClick(item)"
        >
          {{ item.title }}
        </button>
      </div>

      <!-- Footer Note -->
      <div class="mt-3 text-xs text-n-slate-11 text-center">
        Tap a button to reply quickly
      </div>
    </div>
  </BaseBubble>
</template>

<style scoped>
.apple-quick-reply {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

button:active {
  transform: scale(0.98);
}
</style>
