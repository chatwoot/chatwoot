<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes } = useMessageContext();

const interactive = computed(
  () => contentAttributes.value?.whatsappInteractive ?? {}
);
const body = computed(() => interactive.value.body?.text || content.value);
const buttons = computed(() => interactive.value.action?.buttons ?? []);
</script>

<template>
  <BaseBubble
    class="px-4 py-3 min-w-64 max-w-lg"
    data-bubble-name="whatsapp-interactive"
  >
    <p class="mb-3 whitespace-pre-wrap break-words">
      {{ body }}
    </p>
    <div class="flex flex-col gap-2 border-t border-n-weak pt-2">
      <button
        v-for="button in buttons"
        :key="button.deliveryId"
        type="button"
        disabled
        class="w-full rounded-lg px-3 py-2 text-sm font-medium text-n-blue-11 bg-n-alpha-2 disabled:cursor-default disabled:opacity-100"
      >
        {{ button.title }}
      </button>
    </div>
  </BaseBubble>
</template>
