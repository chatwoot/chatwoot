<script setup>
import { useI18n } from 'vue-i18n';

const emit = defineEmits(['add-category']);

const { t } = useI18n();
</script>

<template>
  <div class="flex flex-col items-center justify-center w-full h-full text-center p-8">
    <div class="mb-6">
      <span class="i-lucide-help-circle size-16 text-n-slate-8" />
    </div>
    <h3 class="text-lg font-semibold text-n-slate-12 mb-2">
      {{ t('KNOWLEDGE_BASE.FAQ.EMPTY_STATE.TITLE') }}
    </h3>
    <p class="text-sm text-n-slate-10 mb-6 max-w-md">
      {{ t('KNOWLEDGE_BASE.FAQ.EMPTY_STATE.SUBTITLE') }}
    </p>
    <woot-button
      color-scheme="primary"
      icon="add"
      @click="emit('add-category')"
    >
      {{ t('KNOWLEDGE_BASE.FAQ.NEW_CATEGORY') }}
    </woot-button>
  </div>
</template>
