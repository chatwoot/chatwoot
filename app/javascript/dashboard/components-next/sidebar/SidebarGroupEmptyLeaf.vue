<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <li
    class="py-1 pl-3 text-n-slate-10 border rounded-lg border-dashed text-center border-n-alpha-2 text-xs h-8 grid place-content-center select-none pointer-events-none"
  >
    <slot>{{ t('SIDEBAR.NO_ITEMS') }}</slot>
  </li>
</template>
