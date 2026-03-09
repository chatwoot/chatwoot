<script setup>
import { defineProps } from 'vue';

defineProps({
  config: {
    type: Object,
    default: () => ({}),
  },
});
</script>

<template>
  <div class="h-[calc(2rem*10)] px-4 overflow-y-auto">
    <div>
      <div>
        <div
          class="items-end flex justify-end ml-auto mb-1 mt-0 max-w-[85%] text-right"
        >
          <div
            class="rounded-[1.25rem] rounded-br-[0.25rem] text-white dark:text-white text-sm px-4 py-3"
            :style="{ background: config.color }"
          >
            <p class="m-0">
              {{ $t('INBOX_MGMT.WIDGET_BUILDER.BODY.USER_MESSAGE') }}
            </p>
          </div>
        </div>
      </div>

      <div
        class="bg-white shadow rounded-[1.25rem] rounded-bl-[0.25rem] px-4 py-3 inline-block text-sm text-slate-900 dark:text-white dark:bg-slate-700"
      >
        <div>
          <p class="m-0">
            {{ $t('INBOX_MGMT.WIDGET_BUILDER.BODY.AGENT_MESSAGE') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
