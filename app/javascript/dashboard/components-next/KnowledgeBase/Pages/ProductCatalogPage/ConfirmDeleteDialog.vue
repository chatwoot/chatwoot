<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="dialogTitle"
    :description="dialogDescription"
    :confirm-button-label="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.CONFIRM')"
    :is-loading="isDeleting"
    @confirm="handleDialogConfirm"
    @close="emit('close')"
  />
</template>

<script setup>
import { ref, computed, nextTick } from 'vue';
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

const emit = defineEmits(['close', 'deleted']);
const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);
const isDeleting = ref(false);

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
  // Prevent multiple clicks
  if (isDeleting.value) return;

  isDeleting.value = true;

  try {
    const currentMeta = store.getters['productCatalogs/getMeta'];
    const currentPage = currentMeta.current_page;
    const totalPages = currentMeta.total_pages;
    const productsOnPage = store.getters['productCatalogs/getProductCatalogs'].length;
    const deletedCount = isMultipleDelete.value ? props.selectedProductIds.length : 1;

    if (isMultipleDelete.value) {
      if (!props.selectedProductIds || props.selectedProductIds.length === 0) {
        useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.ERROR'));
        isDeleting.value = false;
        await nextTick();
        dialogRef.value?.close();
        emit('close');
        return;
      }
      await deleteMultipleProducts(props.selectedProductIds);
      useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.SUCCESS_MULTIPLE', { count: props.selectedProductIds.length }));
    } else {
      if (!props.selectedProduct?.id) {
        useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.ERROR'));
        isDeleting.value = false;
        await nextTick();
        dialogRef.value?.close();
        emit('close');
        return;
      }
      await deleteProduct(props.selectedProduct.id);
      useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.SUCCESS'));
    }

    // Refresh products - if deleting all products on current page and not on page 1, go to previous page
    const willPageBeEmpty = deletedCount >= productsOnPage;
    const shouldGoToPrevPage = willPageBeEmpty && currentPage > 1;
    const targetPage = shouldGoToPrevPage ? currentPage - 1 : currentPage;

    await store.dispatch('productCatalogs/get', { page: targetPage, per_page: 50 });

    // Reset loading state and wait for Vue to update before closing
    isDeleting.value = false;
    await nextTick();
    dialogRef.value?.close();
    emit('deleted');
    emit('close');
  } catch (error) {
    console.error('Error deleting product(s):', error);
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE.ERROR'));
    // Reset loading state and wait for Vue to update before closing
    isDeleting.value = false;
    await nextTick();
    dialogRef.value?.close();
    emit('close');
  }
};

defineExpose({ dialogRef });
</script>
