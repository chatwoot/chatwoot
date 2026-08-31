<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  company: {
    type: Object,
    default: () => ({}),
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['confirm']);

const { t } = useI18n();

const dialogRef = ref(null);

const description = computed(() =>
  props.company?.name
    ? t('COMPANIES.DETAIL.DELETE.DESCRIPTION_WITH_NAME', {
        companyName: props.company.name,
      })
    : t('COMPANIES.DETAIL.DELETE.DESCRIPTION')
);

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('COMPANIES.DETAIL.DELETE.TITLE')"
    :description="description"
    :confirm-button-label="t('COMPANIES.DETAIL.DELETE.CONFIRM')"
    :is-loading="isLoading"
    @confirm="emit('confirm')"
  />
</template>
