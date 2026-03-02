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
  <BaseNode :id="id" type="set_variable" :data="data" :selected="selected">
    <template #body>
      <div class="space-y-0.5 text-xs text-n-slate-11">
        <div class="font-mono">
          {{
            data.variable_name ||
            t('AI_AGENTS.WORKFLOW.NODES.SET_VARIABLE.UNNAMED')
          }}
        </div>
        <div
          v-if="data.expression"
          class="line-clamp-1 text-[10px] text-n-slate-8"
        >
          = {{ data.expression }}
        </div>
      </div>
    </template>
  </BaseNode>
</template>
