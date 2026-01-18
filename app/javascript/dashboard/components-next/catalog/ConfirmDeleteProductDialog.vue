<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  product: {
    type: Object,
    default: null,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'confirm']);

const { t } = useI18n();

const dialogRef = ref(null);

const handleClose = () => {
  emit('close');
};

const handleConfirm = () => {
  emit('confirm');
};

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      dialogRef.value?.open();
    } else {
      dialogRef.value?.close();
    }
  }
);
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('CATALOG.DIALOG.DELETE.TITLE')"
    :description="t('CATALOG.DIALOG.DELETE.DESCRIPTION')"
    :confirm-button-label="t('CATALOG.DIALOG.DELETE.CONFIRM')"
    :is-loading="isLoading"
    @close="handleClose"
    @confirm="handleConfirm"
  >
    <div v-if="product" class="p-3 rounded-lg bg-n-alpha-2">
      <p class="font-medium text-n-slate-12">{{ product.title_en }}</p>
      <p v-if="product.title_ar" class="text-sm text-n-slate-11" dir="rtl">
        {{ product.title_ar }}
      </p>
    </div>
  </Dialog>
</template>
