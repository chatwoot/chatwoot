<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseNode from './BaseNode.vue';

const props = defineProps({
  id: { type: String, required: true },
  data: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
});

const { t } = useI18n();

const promptPreview = computed(() => {
  const tpl = props.data.prompt_template || '';
  return tpl.length > 60 ? `${tpl.slice(0, 60)}...` : tpl;
});
</script>

<template>
  <BaseNode :id="id" type="system_prompt" :data="data" :selected="selected">
    <template #body>
      <p class="line-clamp-2 text-xs text-n-slate-10">
        {{
          promptPreview || t('AI_AGENTS.WORKFLOW.NODES.SYSTEM_PROMPT.NO_PROMPT')
        }}
      </p>
      <div
        v-if="data.append_context"
        class="mt-1 inline-flex items-center gap-1 rounded bg-violet-100 px-1.5 py-0.5 text-[10px] text-violet-700 dark:bg-violet-900/30 dark:text-violet-300"
      >
        <span class="i-lucide-plus text-[10px]" />
        {{ t('AI_AGENTS.WORKFLOW.NODES.SYSTEM_PROMPT.CONTEXT') }}
      </div>
    </template>
  </BaseNode>
</template>
