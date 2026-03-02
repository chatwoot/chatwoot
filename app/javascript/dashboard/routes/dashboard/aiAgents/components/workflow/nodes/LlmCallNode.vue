<script setup>
import { useI18n } from 'vue-i18n';
import BaseNode from './BaseNode.vue';

defineProps({
  id: { type: String, required: true },
  data: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
});

const { t } = useI18n();
</script>

<template>
  <BaseNode :id="id" type="llm_call" :data="data" :selected="selected">
    <template #body>
      <div class="space-y-1">
        <div class="flex items-center gap-1.5 text-xs text-n-slate-11">
          <span class="i-lucide-cpu text-violet-500" />
          {{
            data.model || t('AI_AGENTS.WORKFLOW.NODES.LLM_CALL.AGENT_DEFAULT')
          }}
        </div>
        <div class="flex gap-2 text-[10px] text-n-slate-8">
          <span>{{
            t('AI_AGENTS.WORKFLOW.NODES.LLM_CALL.TEMPERATURE', {
              value: data.temperature ?? 0.7,
            })
          }}</span>
          <span
            v-if="data.tools_enabled"
            class="text-blue-600 dark:text-blue-400"
          >
            {{ t('AI_AGENTS.WORKFLOW.NODES.LLM_CALL.TOOLS_ON') }}
          </span>
        </div>
      </div>
    </template>
  </BaseNode>
</template>
