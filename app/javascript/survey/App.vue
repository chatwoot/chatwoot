<script setup>
import { computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import Response from './views/Response.vue';

const { locale } = useI18n();
const direction = computed(() =>
  getLanguageDirection(locale.value) ? 'rtl' : 'ltr'
);

watch(
  direction,
  value => {
    document.documentElement.dir = value;
  },
  { immediate: true }
);
</script>

<template>
  <div id="app" :dir="direction" class="woot-survey-wrap min-h-screen">
    <Response />
  </div>
</template>

<style lang="scss">
@import './assets/scss/woot.scss';
</style>
