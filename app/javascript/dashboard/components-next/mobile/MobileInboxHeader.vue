<script setup>
import { useI18n } from 'vue-i18n';

const emit = defineEmits(['markAllRead']);
const { t } = useI18n();
</script>

<template>
  <header
    class="flex items-center justify-between px-4 py-3 flex-shrink-0 bg-white dark:bg-n-background border-b border-n-weak"
  >
    <h1 class="text-lg font-semibold text-n-slate-12">
      {{ t('MOBILE.INBOX.TITLE') }}
    </h1>
    <button
      class="text-sm font-medium text-n-brand active:opacity-70"
      @click="emit('markAllRead')"
    >
      {{ t('MOBILE.INBOX.MARK_ALL_READ') }}
    </button>
  </header>
</template>
