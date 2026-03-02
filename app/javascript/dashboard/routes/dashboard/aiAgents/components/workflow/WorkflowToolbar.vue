<script setup>
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  isDirty: { type: Boolean, default: false },
  isSaving: { type: Boolean, default: false },
});

const emit = defineEmits([
  'save',
  'auto-layout',
  'fit-view',
  'delete-selected',
]);
const { t } = useI18n();
</script>

<template>
  <div
    class="flex items-center gap-2 border-b border-n-weak bg-n-background px-4 py-2"
  >
    <h3 class="mr-auto text-sm font-semibold text-n-slate-12">
      {{ t('AI_AGENTS.WORKFLOW.TOOLBAR.TITLE') }}
    </h3>

    <Button
      size="small"
      variant="ghost"
      icon="i-lucide-layout-grid"
      @click="emit('auto-layout')"
    >
      {{ t('AI_AGENTS.WORKFLOW.TOOLBAR.AUTO_LAYOUT') }}
    </Button>

    <Button
      size="small"
      variant="ghost"
      icon="i-lucide-maximize"
      @click="emit('fit-view')"
    >
      {{ t('AI_AGENTS.WORKFLOW.TOOLBAR.FIT_VIEW') }}
    </Button>

    <Button
      size="small"
      variant="ghost"
      color-scheme="alert"
      icon="i-lucide-trash-2"
      @click="emit('delete-selected')"
    >
      {{ t('AI_AGENTS.WORKFLOW.TOOLBAR.DELETE') }}
    </Button>

    <div class="mx-2 h-5 w-px bg-n-weak" />

    <Button
      size="small"
      :variant="isDirty ? 'solid' : 'ghost'"
      color-scheme="primary"
      icon="i-lucide-save"
      :is-loading="isSaving"
      :disabled="!isDirty || isSaving"
      @click="emit('save')"
    >
      {{ t('AI_AGENTS.WORKFLOW.TOOLBAR.SAVE') }}
      <span v-if="isDirty" class="ml-1 size-1.5 rounded-full bg-amber-400" />
    </Button>
  </div>
</template>
