<script setup>
import { useI18n } from 'vue-i18n';
import SectionLayout from './SectionLayout.vue';

const { t } = useI18n();
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.NOTE')"
    with-border
  >
    {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.NOTE') }}
  </SectionLayout>
</template>
