<script setup>
import { useI18n } from 'vue-i18n';

const emit = defineEmits(['openFilter']);
const { t } = useI18n();
</script>

<template>
  <header
    class="flex items-center justify-between px-4 py-3 pt-[env(safe-area-inset-top)] flex-shrink-0 bg-white dark:bg-n-background border-b border-n-weak"
  >
    <h1 class="text-lg font-semibold text-n-slate-12">
      {{ t('MOBILE.CONVERSATIONS.TITLE') }}
    </h1>
    <button
      class="flex items-center justify-center size-9 rounded-lg text-n-slate-11 active:bg-n-alpha-2"
      @click="emit('openFilter')"
    >
      <span class="i-lucide-sliders-horizontal size-5" />
    </button>
  </header>
</template>
