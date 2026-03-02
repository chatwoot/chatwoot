<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseNode from './BaseNode.vue';

defineProps({
  id: { type: String, required: true },
  data: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
});

const { t } = useI18n();

const triggerLabels = computed(() => ({
  message_received: t('AI_AGENTS.WORKFLOW.NODES.TRIGGER.MESSAGE_RECEIVED'),
  phone_call: t('AI_AGENTS.WORKFLOW.NODES.TRIGGER.PHONE_CALL'),
  webhook: t('AI_AGENTS.WORKFLOW.NODES.TRIGGER.WEBHOOK'),
}));
</script>

<template>
  <BaseNode :id="id" type="trigger" :data="data" :selected="selected">
    <template #body>
      <div class="flex items-center gap-1.5 text-xs text-n-slate-11">
        <span class="i-lucide-radio text-emerald-500" />
        {{ triggerLabels[data.trigger_type] || triggerLabels.message_received }}
      </div>
    </template>
  </BaseNode>
</template>
