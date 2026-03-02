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
  <BaseNode :id="id" type="loop" :data="data" :selected="selected">
    <template #body>
      <div class="flex items-center gap-1.5 text-xs text-n-slate-11">
        <span class="i-lucide-repeat text-amber-500" />
        {{
          t('AI_AGENTS.WORKFLOW.NODES.LOOP.MAX_ITERATIONS', {
            count: data.max_iterations || 10,
          })
        }}
      </div>
    </template>
  </BaseNode>
</template>
