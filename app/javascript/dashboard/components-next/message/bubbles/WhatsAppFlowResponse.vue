<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes } = useMessageContext();

const flowResponse = computed(
  () => contentAttributes.value?.flowResponse || {}
);

const hasFlowData = computed(
  () => Object.keys(flowResponse.value.responseData || {}).length > 0
);

const responseEntries = computed(() =>
  Object.entries(flowResponse.value.responseData || {})
);
</script>

<template>
  <BaseBubble
    class="p-0 overflow-hidden"
    data-bubble-name="whatsapp-flow-response"
  >
    <div class="flex flex-col max-w-80">
      <!-- Flow response header -->
      <div class="flex items-center gap-2 px-4 pt-3 pb-2">
        <span class="i-lucide-git-branch size-4 text-n-teal-11" />
        <span class="text-xs font-medium text-n-teal-11">
          {{ $t('CONVERSATION.FLOW_RESPONSE') }}
        </span>
      </div>

      <!-- Message body -->
      <div v-if="content" class="px-4 pb-2 text-sm text-n-slate-12">
        {{ flowResponse.body || content }}
      </div>

      <!-- Response data -->
      <div
        v-if="hasFlowData"
        class="mx-4 mb-3 rounded-lg border border-n-weak bg-n-alpha-1 overflow-hidden"
      >
        <div
          v-for="[key, value] in responseEntries"
          :key="key"
          class="flex items-start gap-3 px-3 py-2 border-b border-n-weak last:border-b-0"
        >
          <span
            class="text-xs font-medium text-n-slate-9 min-w-[80px] capitalize"
          >
            {{ key.replace(/_/g, ' ') }}
          </span>
          <span class="text-xs text-n-slate-12 flex-1">
            {{ value }}
          </span>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
