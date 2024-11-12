<script setup>
import { defineModel } from 'vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const value = defineModel({
  type: [String, Number],
  default: null,
});
</script>

<template>
  <input
    v-model="value"
    class="py-1.5 px-3 text-n-slate-12 bg-n-alpha-1 text-sm rounded-lg"
    :placeholder="t('FILTER.INPUT_PLACEHOLDER')"
  />
</template>
