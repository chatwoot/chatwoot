<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="dialogTitle"
    :description="dialogDescription"
    :confirm-button-label="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.CONFIRM')"
    @confirm="handleDialogConfirm"
    @close="emit('close')"
  />
</template>

<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  selectedProduct: {
    type: Object,
    default: null,
  },
  selectedProductIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['close']);
const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);

const isMultipleDelete = computed(() => props.selectedProductIds && props.selectedProductIds.length > 0);

const dialogTitle = computed(() => {
  if (isMultipleDelete.value) {
    return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.TITLE_MULTIPLE', { count: props.selectedProductIds.length });
  }
  return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.TITLE');
});

const dialogDescription = computed(() => {
  if (isMultipleDelete.value) {
    return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.DESCRIPTION_MULTIPLE', { count: props.selectedProductIds.length });
  }
  return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.DESCRIPTION');
});

const deleteProduct = async id => {
  if (!id) return;
  try {
    await store.dispatch('productCatalogs/delete', id);
  } catch (error) {
    throw error;
  }
};

const deleteMultipleProducts = async ids => {
  if (!ids || ids.length === 0) return;
  try {
    await store.dispatch('productCatalogs/bulkDelete', ids);
  } catch (error) {
    throw error;
  }
};

const handleDialogConfirm = async () => {
  try {
    if (isMultipleDelete.value) {
      if (!props.selectedProductIds || props.selectedProductIds.length === 0) {
        useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.ERROR'));
        dialogRef.value?.close();
        emit('close');
        return;
      }
      await deleteMultipleProducts(props.selectedProductIds);
      useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.SUCCESS_MULTIPLE', { count: props.selectedProductIds.length }));
    } else {
      if (!props.selectedProduct?.id) {
        useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.ERROR'));
        dialogRef.value?.close();
        emit('close');
        return;
      }
      await deleteProduct(props.selectedProduct.id);
      useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.SUCCESS'));
    }
    dialogRef.value?.close();
    emit('close');
  } catch (error) {
    console.error('Error deleting product(s):', error);
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.ERROR'));
    dialogRef.value?.close();
    emit('close');
  }
};

defineExpose({ dialogRef });
</script>
