<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <header
    class="flex items-center px-4 py-3 pt-[env(safe-area-inset-top)] flex-shrink-0 bg-white dark:bg-n-background border-b border-n-weak"
  >
    <h1 class="text-lg font-semibold text-n-slate-12">
      {{ t('MOBILE.SETTINGS.TITLE') }}
    </h1>
  </header>
</template>
