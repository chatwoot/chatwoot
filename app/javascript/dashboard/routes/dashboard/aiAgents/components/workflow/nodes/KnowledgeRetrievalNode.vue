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
  <BaseNode
    :id="id"
    type="knowledge_retrieval"
    :data="data"
    :selected="selected"
  >
    <template #body>
      <div class="space-y-1">
        <div class="flex items-center gap-1.5 text-xs text-n-slate-11">
          <span class="i-lucide-search text-violet-500" />
          {{
            t('AI_AGENTS.WORKFLOW.NODES.KNOWLEDGE_RETRIEVAL.TOP_RESULTS', {
              count: data.top_k || 5,
            })
          }}
        </div>
        <div
          v-if="data.knowledge_base_ids?.length"
          class="text-[10px] text-n-slate-8"
        >
          {{
            t('AI_AGENTS.WORKFLOW.NODES.KNOWLEDGE_RETRIEVAL.KNOWLEDGE_BASES', {
              count: data.knowledge_base_ids.length,
            })
          }}
        </div>
        <div v-else class="text-[10px] text-amber-600 dark:text-amber-400">
          {{
            t('AI_AGENTS.WORKFLOW.NODES.KNOWLEDGE_RETRIEVAL.NO_KNOWLEDGE_BASES')
          }}
        </div>
      </div>
    </template>
  </BaseNode>
</template>
