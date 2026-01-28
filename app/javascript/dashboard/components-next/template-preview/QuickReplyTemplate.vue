<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
});

const actions = computed(() => props.message.actions || []);
</script>

<template>
  <div
    class="rounded-xl divide-y bg-n-alpha-2 divide-n-strong text-n-slate-12 max-w-80"
  >
    <div class="p-3">
      <span
        v-dompurify-html="message.content"
        class="text-sm font-medium prose prose-bubble"
      />
    </div>
    <div
      v-for="(action, index) in actions"
      :key="index"
      class="flex justify-center items-center p-3"
    >
      <Button
        :label="action.title || action.text || 'Button'"
        link
        class="hover:!no-underline"
      >
        <template #icon>
          <svg
            width="15"
            height="15"
            viewBox="0 0 15 15"
            fill="none"
            class="stroke-n-blue-text"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M.667 6.654 5.315.667v3.326c7.968 0 8.878 6.46 8.656 10.007l-.005-.027c-.334-1.79-.474-4.658-8.65-4.658v3.327z"
              stroke-width="1.333"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
        </template>
      </Button>
    </div>
  </div>
</template>
