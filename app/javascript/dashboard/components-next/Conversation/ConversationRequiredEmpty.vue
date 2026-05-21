<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <div class="flex justify-between items-center px-4 py-4 w-full">
    <div
      class="flex justify-center items-center py-6 w-full custom-dashed-border"
    >
      <span class="text-sm text-n-slate-11">
        {{ t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.NO_ATTRIBUTES') }}
      </span>
    </div>
  </div>
</template>
