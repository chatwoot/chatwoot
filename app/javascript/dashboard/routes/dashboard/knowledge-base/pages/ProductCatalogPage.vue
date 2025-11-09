<template>
  <div class="flex-1 overflow-auto bg-n-background">
    <KnowledgeBaseLayout
      :header-title="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.HEADER_TITLE')"
      :button-label="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.NEW_PRODUCT')"
      :button-disabled="isProcessing"
      @click="toggleUploadDialog()"
    >
      <template #header-actions>
        <button
          class="flex-shrink-0 px-4 py-2 bg-n-blue-9 text-white rounded-lg hover:bg-n-blue-10 transition-colors text-sm font-medium flex items-center gap-2"
          @click="handleDownloadTemplate"
        >
          <i class="i-lucide-download w-4 h-4" />
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DOWNLOAD_TEMPLATE') }}
        </button>
      </template>

      <template #action>
        <UploadDialog
          v-if="showUploadDialog"
          :is-processing="isProcessing"
          @close="toggleUploadDialog(false)"
          @upload-success="handleUploadSuccess"
        />
      </template>

      <div
        v-if="isFetching"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>

      <div v-else-if="!hasNoProducts || activeProcessing" class="p-6 space-y-6">
        <!-- Active Processing Status -->
        <ProcessingStatus
          v-if="activeProcessing"
          :status="activeProcessing.status"
          :file-name="activeProcessing.file_name"
          :progress="activeProcessing.progress"
          :total-records="activeProcessing.total_records"
          :processed-records="activeProcessing.processed_records"
          :failed-records="activeProcessing.failed_records"
          :error-message="activeProcessing.error_message"
          :error-details="activeProcessing.error_details"
          :bulk-request-id="activeProcessing.id"
          @cancel="handleCancelProcessing"
          @close="activeProcessing = null"
        />

        <!-- Search Bar and Bulk Actions -->
        <div v-if="!hasNoProducts || (activeProcessing && products.length > 0)" class="flex items-center gap-2">
          <Input
            :model-value="searchQuery"
            type="search"
            :placeholder="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.SEARCH_PLACEHOLDER')"
            :custom-input-class="[
              'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
            ]"
            class="w-full"
            @input="searchQuery = $event.target.value"
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
              />
            </template>
          </Input>
          <button
            v-if="selectedProductIds.length > 0"
            class="flex-shrink-0 px-4 py-2 bg-n-green-9 text-white rounded-lg hover:bg-n-green-10 transition-colors text-sm font-medium flex items-center gap-2"
            @click="handleExport"
          >
            <i class="i-lucide-download w-4 h-4" />
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EXPORT_SELECTED', { count: selectedProductIds.length }) }}
          </button>
          <button
            v-if="selectedProductIds.length > 0"
            class="flex-shrink-0 px-4 py-2 bg-n-red-9 text-white rounded-lg hover:bg-n-red-10 transition-colors text-sm font-medium flex items-center gap-2"
            @click="handleBulkDelete"
          >
            <i class="i-lucide-trash-2 w-4 h-4" />
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DELETE_SELECTED', { count: selectedProductIds.length }) }}
          </button>
          <button
            class="flex-shrink-0 p-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-slate-3 rounded-lg transition-colors"
            @click="refreshProducts"
            :title="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.REFRESH')"
          >
            <i class="i-lucide-refresh-cw w-4 h-4" />
          </button>
          <div v-if="searchQuery" class="text-sm text-n-slate-11 whitespace-nowrap">
            {{ filteredProducts.length }} {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.RESULTS') }}
          </div>
        </div>

        <!-- Product Table -->
        <ProductTable
          v-if="!hasNoProducts || (activeProcessing && products.length > 0)"
          :products="filteredProducts"
          :selected-product-id="selectedProductForMedia?.id"
          :selected-product-ids="selectedProductIds"
          @update:selected-product-ids="handleSelectedProductIdsUpdate"
          @select="handleProductSelect"
          @delete="handleDelete"
        />
      </div>

      <ProductCatalogEmptyState
        v-else
        :title="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EMPTY_STATE.TITLE')"
        :subtitle="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EMPTY_STATE.SUBTITLE')"
        class="pt-14"
      />
    </KnowledgeBaseLayout>

    <ConfirmDeleteDialog
      ref="deleteDialogRef"
      :selected-product="selectedProduct"
      :selected-product-ids="selectedProductIds"
      @close="handleDeleteDialogClose"
    />

    <MediaDrawer
      v-if="selectedProductForMedia"
      :product="selectedProductForMedia"
      @close="selectedProductForMedia = null"
    />
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useToggle } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import KnowledgeBaseLayout from 'dashboard/components-next/KnowledgeBase/KnowledgeBaseLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

import UploadDialog from 'dashboard/components-next/KnowledgeBase/Pages/ProductCatalogPage/UploadDialog.vue';
import ProductTable from 'dashboard/components-next/KnowledgeBase/Pages/ProductCatalogPage/ProductTable.vue';
import ConfirmDeleteDialog from 'dashboard/components-next/KnowledgeBase/Pages/ProductCatalogPage/ConfirmDeleteDialog.vue';
import ProcessingStatus from 'dashboard/components-next/KnowledgeBase/Pages/ProductCatalogPage/ProcessingStatus.vue';
import MediaDrawer from 'dashboard/components-next/KnowledgeBase/Pages/ProductCatalogPage/MediaDrawer.vue';
import ProductCatalogEmptyState from 'dashboard/components-next/KnowledgeBase/Pages/ProductCatalogPage/ProductCatalogEmptyState.vue';
import ProductCatalogAPI from 'dashboard/api/productCatalog';

const { t } = useI18n();
const store = useStore();

const [showUploadDialog, toggleUploadDialog] = useToggle();
const selectedProduct = ref(null);
const selectedProductForMedia = ref(null);
const selectedProductIds = ref([]);
const deleteDialogRef = ref(null);
const activeProcessing = ref(null);
const pollingInterval = ref(null);
const searchQuery = ref('');

const uiFlags = useMapGetter('productCatalogs/getUIFlags');
const isFetching = computed(() => uiFlags.value.isFetching);

const products = computed(() => store.getters['productCatalogs/getProductCatalogs']);
const hasNoProducts = computed(() => products.value?.length === 0 && !isFetching.value);

const filteredProducts = computed(() => {
  if (!searchQuery.value) return products.value;

  const query = searchQuery.value.toLowerCase();
  return products.value.filter(product => {
    return (
      product.productName?.toLowerCase().includes(query) ||
      product.product_id?.toLowerCase().includes(query) ||
      product.type?.toLowerCase().includes(query) ||
      product.industry?.toLowerCase().includes(query) ||
      product.description?.toLowerCase().includes(query)
    );
  });
});

const isProcessing = computed(() => {
  return activeProcessing.value && ['PENDING', 'PROCESSING'].includes(activeProcessing.value.status);
});

onMounted(async () => {
  await store.dispatch('productCatalogs/get');
  checkActiveProcessing();
});

onUnmounted(() => {
  stopPolling();
});

const checkActiveProcessing = async () => {
  // Check if there's an active bulk processing request
  const bulkRequests = await store.dispatch('bulkProcessingRequests/get');
  const active = bulkRequests.find(req =>
    req.entity_type === 'ProductCatalog' &&
    ['PENDING', 'PROCESSING'].includes(req.status)
  );

  if (active) {
    activeProcessing.value = active;
    startPolling();
  }
};

const startPolling = () => {
  if (pollingInterval.value) return;

  pollingInterval.value = setInterval(async () => {
    if (!activeProcessing.value) {
      stopPolling();
      return;
    }

    const bulkRequests = await store.dispatch('bulkProcessingRequests/get');
    const updated = bulkRequests.find(req => req.id === activeProcessing.value.id);

    if (updated) {
      activeProcessing.value = updated;

      // Normalize status to uppercase for comparison
      const statusUpper = updated.status?.toUpperCase();

      // Refresh product list during processing to show new products
      if (statusUpper === 'PROCESSING') {
        await store.dispatch('productCatalogs/get');
      }

      // Stop polling if completed or failed
      if (['COMPLETED', 'FAILED', 'PARTIALLY_COMPLETED'].includes(statusUpper)) {
        // Always refresh product list at the end FIRST, regardless of status
        await store.dispatch('productCatalogs/get');

        // Stop polling after refresh
        stopPolling();

        // Show completion message
        if (statusUpper === 'COMPLETED') {
          useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.SUCCESS_MESSAGE'));
          // Clear active processing for successful uploads
          activeProcessing.value = null;
        } else if (statusUpper === 'FAILED') {
          useAlert(updated.error_message || t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.ERROR'));
          // Keep activeProcessing so user can download errors
        } else if (statusUpper === 'PARTIALLY_COMPLETED') {
          // Keep activeProcessing so user can download errors
        }
      }
    }
  }, 2000); // Poll every 2 seconds
};

const stopPolling = () => {
  if (pollingInterval.value) {
    clearInterval(pollingInterval.value);
    pollingInterval.value = null;
  }
};

const handleUploadSuccess = (bulkRequestId) => {
  toggleUploadDialog(false);

  // Set active processing
  activeProcessing.value = {
    id: bulkRequestId,
    status: 'PENDING',
    progress: 0,
    total_records: 0,
    processed_records: 0,
    failed_records: 0,
    file_name: 'Processing...'
  };

  startPolling();
};

const handleCancelProcessing = async () => {
  if (!activeProcessing.value) return;

  try {
    // Get fresh status before attempting cancel
    const bulkRequests = await store.dispatch('bulkProcessingRequests/get');
    const currentRequest = bulkRequests.find(req => req.id === activeProcessing.value.id);

    // Check if still cancelable with fresh status
    if (!currentRequest || !['PENDING', 'PROCESSING'].includes(currentRequest.status)) {
      useAlert('Cannot cancel - upload already completed or failed');
      // Update local state
      if (currentRequest) {
        activeProcessing.value = currentRequest;
      }
      return;
    }

    // Now attempt to cancel
    await store.dispatch('bulkProcessingRequests/cancel', activeProcessing.value.id);

    // Stop polling
    stopPolling();

    // Clear active processing
    activeProcessing.value = null;

    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.CANCELLED'));
  } catch (error) {
    // Handle 422 error (status changed between check and cancel)
    if (error.response?.status === 422) {
      useAlert('Cannot cancel - upload already completed or failed');
      // Refresh to get latest status
      const bulkRequests = await store.dispatch('bulkProcessingRequests/get');
      const currentRequest = bulkRequests.find(req => req.id === activeProcessing.value.id);
      if (currentRequest) {
        activeProcessing.value = currentRequest;
      }
    } else {
      useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.CANCEL_ERROR'));
    }
  }
};

const handleDelete = product => {
  selectedProduct.value = product;
  // Don't clear selectedProductIds here - let the dialog close handler do it
  deleteDialogRef.value?.dialogRef?.open();
};

const handleBulkDelete = () => {
  selectedProduct.value = null;
  // Keep selectedProductIds so dialog can process them
  deleteDialogRef.value?.dialogRef?.open();
};

const handleDeleteDialogClose = () => {
  // Only clear selectedProduct, not selectedProductIds
  // The selectedProductIds should persist for bulk operations like export
  selectedProduct.value = null;
  // Don't clear selectedProductIds here - it's needed for export and other bulk operations
};

const handleProductSelect = product => {
  // Toggle: close drawer if clicking the same product
  if (selectedProductForMedia.value?.id === product.id) {
    selectedProductForMedia.value = null;
  } else {
    selectedProductForMedia.value = product;
  }
};

const handleSelectedProductIdsUpdate = (newIds) => {
  // Clear the array and push new values to maintain reactivity
  selectedProductIds.value.splice(0, selectedProductIds.value.length, ...newIds);
};

const refreshProducts = async () => {
  await store.dispatch('productCatalogs/get');
  useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.REFRESHED'));
};

const handleExport = async () => {
  if (selectedProductIds.value.length === 0) {
    return;
  }

  try {
    const response = await ProductCatalogAPI.export(selectedProductIds.value);

    // Create blob URL and trigger download
    const blob = new Blob([response.data], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `products_export_${new Date().toISOString().split('T')[0]}.xlsx`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);

    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EXPORT_SUCCESS', { count: selectedProductIds.value.length }));
  } catch (error) {
    console.error('Error exporting products:', error);
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EXPORT_ERROR'));
  }
};

const handleDownloadTemplate = async () => {
  try {
    const response = await ProductCatalogAPI.downloadTemplate();

    // Create blob URL and trigger download
    const blob = new Blob([response.data], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'product_catalog_template.xlsx';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);

    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TEMPLATE_DOWNLOADED'));
  } catch (error) {
    console.error('Error downloading template:', error);
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TEMPLATE_DOWNLOAD_ERROR'));
  }
};
</script>
