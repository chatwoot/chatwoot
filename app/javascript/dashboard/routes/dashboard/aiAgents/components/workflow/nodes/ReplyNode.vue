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
  <BaseNode :id="id" type="reply" :data="data" :selected="selected">
    <template #body>
      <div class="flex items-center gap-1.5 text-xs text-n-slate-11">
        <span class="i-lucide-message-circle text-blue-500" />
        {{
          data.message_type === 'template'
            ? t('AI_AGENTS.WORKFLOW.NODES.REPLY.TEMPLATE')
            : t('AI_AGENTS.WORKFLOW.NODES.REPLY.TEXT')
        }}
        {{ t('AI_AGENTS.WORKFLOW.NODES.REPLY.REPLY_SUFFIX') }}
      </div>
      <p
        v-if="data.content_template"
        class="mt-1 line-clamp-1 text-[10px] text-n-slate-8"
      >
        {{ data.content_template }}
      </p>
      <div
        v-if="data.content_attributes?.ai_generated"
        class="mt-1 inline-flex items-center rounded bg-blue-100 px-1.5 py-0.5 text-[10px] text-blue-700 dark:bg-blue-900/30 dark:text-blue-300"
      >
        {{ t('AI_AGENTS.WORKFLOW.NODES.REPLY.AI_GENERATED') }}
      </div>
    </template>
  </BaseNode>
</template>
