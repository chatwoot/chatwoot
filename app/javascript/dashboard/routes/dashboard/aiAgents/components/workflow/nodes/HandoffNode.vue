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
  <BaseNode :id="id" type="handoff" :data="data" :selected="selected">
    <template #body>
      <div class="flex items-center gap-1.5 text-xs text-n-slate-11">
        <span class="i-lucide-user-check text-blue-500" />
        {{ t('AI_AGENTS.WORKFLOW.NODES.HANDOFF.TRANSFER_TO_HUMAN') }}
      </div>
      <p
        v-if="data.reason_template"
        class="mt-1 line-clamp-1 text-[10px] text-n-slate-8"
      >
        {{ data.reason_template }}
      </p>
    </template>
  </BaseNode>
</template>
