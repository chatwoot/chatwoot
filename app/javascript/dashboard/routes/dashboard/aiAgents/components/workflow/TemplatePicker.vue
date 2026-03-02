<script setup>
import { useI18n } from 'vue-i18n';
import { TEMPLATE_LIST, WORKFLOW_TEMPLATES } from './workflowTemplates';

const emit = defineEmits(['selectTemplate']);
const { t } = useI18n();

function onSelect(key) {
  const template = WORKFLOW_TEMPLATES[key];
  if (template) {
    emit('selectTemplate', template);
  }
}
</script>

<template>
  <div class="flex size-full items-center justify-center bg-n-background p-8">
    <div class="max-w-lg text-center">
      <span
        class="i-lucide-git-branch-plus mb-4 inline-block text-4xl text-n-slate-8"
      />
      <h2 class="mb-2 text-lg font-semibold text-n-slate-12">
        {{ t('AI_AGENTS.WORKFLOW.TEMPLATES.TITLE') }}
      </h2>
      <p class="mb-6 text-sm text-n-slate-10">
        {{ t('AI_AGENTS.WORKFLOW.TEMPLATES.DESCRIPTION') }}
      </p>

      <div class="grid gap-3">
        <button
          v-for="tpl in TEMPLATE_LIST"
          :key="tpl.key"
          class="flex items-start gap-3 rounded-xl border border-n-weak bg-white p-4 text-left transition-colors hover:border-n-brand hover:bg-n-alpha-1 dark:bg-n-solid-3"
          @click="onSelect(tpl.key)"
        >
          <span
            :class="tpl.icon"
            class="mt-0.5 shrink-0 text-lg text-n-brand"
          />
          <div>
            <div class="text-sm font-semibold text-n-slate-12">
              {{ tpl.name }}
            </div>
            <div class="text-xs text-n-slate-10">
              {{ tpl.description }}
            </div>
          </div>
        </button>
      </div>

      <p class="mt-4 text-xs text-n-slate-8">
        {{ t('AI_AGENTS.WORKFLOW.TEMPLATES.OR_DRAG') }}
      </p>
    </div>
  </div>
</template>
