<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';
import { buildFlowResponseEntries } from '../helpers/whatsappFlowResponse.js';

const { content, contentAttributes } = useMessageContext();
const { t } = useI18n();

const responseEntries = computed(() => {
  const response =
    contentAttributes.value?.whatsappFlowResponse?.responseJson ?? {};

  return buildFlowResponseEntries(response);
});
</script>

<template>
  <BaseBubble
    class="px-4 py-3 min-w-64 max-w-lg"
    data-bubble-name="whatsapp-flow-response"
  >
    <div class="font-medium">
      {{ content || t('CONVERSATION.WHATSAPP_FLOW_RESPONSE') }}
    </div>
    <dl v-if="responseEntries.length" class="mt-3 space-y-3">
      <div v-for="entry in responseEntries" :key="entry.key">
        <dt class="text-xs text-n-slate-11">
          {{ entry.label }}
        </dt>
        <dd class="mt-0.5 whitespace-pre-wrap break-words">
          {{ entry.value }}
        </dd>
      </div>
    </dl>
  </BaseBubble>
</template>
