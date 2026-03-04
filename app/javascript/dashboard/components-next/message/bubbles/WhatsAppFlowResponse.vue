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
  Object.entries(flowResponse.value.responseData || {}).filter(
    ([key]) => key.toLowerCase() !== 'flow_token'
  )
);

function formatKey(key) {
  return key
    .replace(/([A-Z])/g, ' $1')
    .replace(/[_-]/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase())
    .trim();
}

function formatValue(value) {
  if (value === null || value === undefined) return '—';
  if (typeof value === 'boolean') return value ? '✓' : '✗';
  return String(value).replace(/_/g, ' ');
}
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="whatsapp-flow-response">
    <!-- Message body -->
    <p v-if="content" class="text-sm text-n-slate-12 mb-2">
      {{ flowResponse.body || content }}
    </p>

    <!-- Flow response data -->
    <div v-if="hasFlowData" class="mt-1">
      <div
        class="flex items-center gap-1.5 mb-2 text-xs font-medium text-n-teal-11"
      >
        <span class="i-lucide-git-branch size-3.5" />
        <span>{{ $t('CONVERSATION.FLOW_RESPONSE') }}</span>
      </div>

      <dl class="space-y-1">
        <div
          v-for="[key, value] in responseEntries"
          :key="key"
          class="flex gap-2 text-sm"
        >
          <dt class="text-n-slate-9 font-medium min-w-0 shrink-0">
            {{ formatKey(key) }}:
          </dt>
          <dd class="text-n-slate-12 min-w-0 break-words">
            {{ formatValue(value) }}
          </dd>
        </div>
      </dl>
    </div>
  </BaseBubble>
</template>
