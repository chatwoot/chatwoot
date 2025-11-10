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

      <!-- Active Processing Status - Show even if no products -->
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
        class="m-6"
        @cancel="handleCancelProcessing"
        @close="handleCloseProcessingStatus"
      />

      <div v-if="!hasNoProducts || activeProcessing" class="p-6 space-y-6">

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

        <!-- Pagination -->
        <div v-if="!searchQuery && meta.total_pages > 1" class="flex items-center justify-between mt-6 px-4 py-3 bg-n-solid-1 rounded-lg">
          <div class="text-sm text-n-slate-11">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.SHOWING') }}
            <span class="font-medium text-n-slate-12">{{ (meta.current_page - 1) * meta.per_page + 1 }}</span>
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.TO') }}
            <span class="font-medium text-n-slate-12">{{ Math.min(meta.current_page * meta.per_page, meta.total_count) }}</span>
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.OF') }}
            <span class="font-medium text-n-slate-12">{{ meta.total_count }}</span>
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.RESULTS') }}
          </div>

          <div class="flex items-center gap-2">
            <button
              :disabled="meta.current_page === 1"
              :class="[
                'px-3 py-1 rounded-md text-sm font-medium transition-colors',
                meta.current_page === 1
                  ? 'text-n-slate-9 cursor-not-allowed'
                  : 'text-n-slate-12 hover:bg-n-slate-3'
              ]"
              @click="handlePageChange(1)"
            >
              <i class="i-lucide-chevrons-left w-4 h-4" />
            </button>

            <button
              :disabled="meta.current_page === 1"
              :class="[
                'px-3 py-1 rounded-md text-sm font-medium transition-colors',
                meta.current_page === 1
                  ? 'text-n-slate-9 cursor-not-allowed'
                  : 'text-n-slate-12 hover:bg-n-slate-3'
              ]"
              @click="handlePageChange(meta.current_page - 1)"
            >
              <i class="i-lucide-chevron-left w-4 h-4" />
            </button>

            <div class="flex items-center gap-1">
              <template v-for="page in visiblePages" :key="page">
                <button
                  v-if="typeof page === 'number'"
                  :class="[
                    'px-3 py-1 rounded-md text-sm font-medium transition-colors',
                    page === meta.current_page
                      ? 'bg-n-blue-9 text-white'
                      : 'text-n-slate-12 hover:bg-n-slate-3'
                  ]"
                  @click="handlePageChange(page)"
                >
                  {{ page }}
                </button>
                <span v-else class="px-2 text-n-slate-11">...</span>
              </template>
            </div>

            <button
              :disabled="meta.current_page === meta.total_pages"
              :class="[
                'px-3 py-1 rounded-md text-sm font-medium transition-colors',
                meta.current_page === meta.total_pages
                  ? 'text-n-slate-9 cursor-not-allowed'
                  : 'text-n-slate-12 hover:bg-n-slate-3'
              ]"
              @click="handlePageChange(meta.current_page + 1)"
            >
              <i class="i-lucide-chevron-right w-4 h-4" />
            </button>

            <button
              :disabled="meta.current_page === meta.total_pages"
              :class="[
                'px-3 py-1 rounded-md text-sm font-medium transition-colors',
                meta.current_page === meta.total_pages
                  ? 'text-n-slate-9 cursor-not-allowed'
                  : 'text-n-slate-12 hover:bg-n-slate-3'
              ]"
              @click="handlePageChange(meta.total_pages)"
            >
              <i class="i-lucide-chevrons-right w-4 h-4" />
            </button>
          </div>
        </div>
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
      @deleted="handleProductsDeleted"
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
const meta = computed(() => store.getters['productCatalogs/getMeta']);
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

const visiblePages = computed(() => {
  const current = meta.value.current_page;
  const total = meta.value.total_pages;
  const pages = [];

  if (total <= 7) {
    // Show all pages if 7 or fewer
    for (let i = 1; i <= total; i++) {
      pages.push(i);
    }
  } else {
    // Always show first page
    pages.push(1);

    if (current <= 3) {
      // Near start: show 1 2 3 4 5 ... total
      for (let i = 2; i <= 5; i++) {
        pages.push(i);
      }
      pages.push('ellipsis1');
      pages.push(total);
    } else if (current >= total - 2) {
      // Near end: show 1 ... (total-4) (total-3) (total-2) (total-1) total
      pages.push('ellipsis1');
      for (let i = total - 4; i <= total; i++) {
        pages.push(i);
      }
    } else {
      // Middle: show 1 ... (current-1) current (current+1) ... total
      pages.push('ellipsis1');
      pages.push(current - 1);
      pages.push(current);
      pages.push(current + 1);
      pages.push('ellipsis2');
      pages.push(total);
    }
  }

  return pages;
});

onMounted(async () => {
  await store.dispatch('productCatalogs/get', { page: 1, per_page: 50 });
  await checkActiveProcessing();
});

onUnmounted(() => {
  stopPolling();
});

const checkActiveProcessing = async () => {
  // Check if there's an active bulk processing request
  // Only show requests that are:
  // - Not dismissed (dismissed_at is null)
  // - Created within last 24 hours
  const bulkRequests = await store.dispatch('bulkProcessingRequests/get');

  const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

  // First check for active (in-progress) requests
  let active = bulkRequests.find(req => {
    const createdAt = new Date(req.created_at);
    return req.entity_type === 'ProductCatalog' &&
      ['PENDING', 'PROCESSING'].includes(req.status?.toUpperCase()) &&
      !req.dismissed_at &&
      createdAt > twentyFourHoursAgo;
  });

  // If no active request, check for the most recent completed/failed one (to show until user dismisses)
  if (!active) {
    active = bulkRequests.find(req => {
      const createdAt = new Date(req.created_at);
      return req.entity_type === 'ProductCatalog' &&
        ['COMPLETED', 'FAILED', 'PARTIALLY_COMPLETED', 'CANCELLED'].includes(req.status?.toUpperCase()) &&
        !req.dismissed_at &&
        createdAt > twentyFourHoursAgo;
    });
  }

  if (active) {
    activeProcessing.value = active;

    // Only start polling if status is PENDING or PROCESSING
    const statusUpper = active.status?.toUpperCase();
    if (['PENDING', 'PROCESSING'].includes(statusUpper)) {
      startPolling();
    }
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
        await store.dispatch('productCatalogs/get', { page: meta.value.current_page, per_page: 50 });
      }

      // Stop polling if completed or failed
      if (['COMPLETED', 'FAILED', 'PARTIALLY_COMPLETED'].includes(statusUpper)) {
        // Always refresh product list at the end FIRST, regardless of status
        await store.dispatch('productCatalogs/get', { page: meta.value.current_page, per_page: 50 });

        // Stop polling after refresh
        stopPolling();

        // Show completion message
        if (statusUpper === 'COMPLETED') {
          useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.SUCCESS_MESSAGE'));
          // Auto-dismiss successful uploads
          const requestId = activeProcessing.value.id;
          activeProcessing.value = null;

          // Mark as dismissed in background
          store.dispatch('bulkProcessingRequests/dismiss', requestId).catch(error => {
            console.error('Error dismissing bulk request:', error);
          });
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
    const statusUpper = currentRequest?.status?.toUpperCase();
    if (!currentRequest || !['PENDING', 'PROCESSING'].includes(statusUpper)) {
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

const handleCloseProcessingStatus = () => {
  // Only allow closing if status is final (not PENDING or PROCESSING)
  if (activeProcessing.value) {
    const statusUpper = activeProcessing.value.status?.toUpperCase();
    if (['COMPLETED', 'FAILED', 'PARTIALLY_COMPLETED', 'CANCELLED'].includes(statusUpper)) {
      const requestId = activeProcessing.value.id;

      // Close dialog immediately for better UX
      activeProcessing.value = null;

      // Make dismiss request in background (fire and forget)
      store.dispatch('bulkProcessingRequests/dismiss', requestId).catch(error => {
        console.error('Error dismissing bulk request:', error);
      });
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

const handleProductsDeleted = () => {
  // Clear selected product IDs after successful deletion
  selectedProductIds.value = [];
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
  await store.dispatch('productCatalogs/get', { page: meta.value.current_page, per_page: 50 });
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

const handlePageChange = async (page) => {
  if (page < 1 || page > meta.value.total_pages || page === meta.value.current_page) {
    return;
  }

  await store.dispatch('productCatalogs/get', { page, per_page: 50 });

  // Scroll to top of product list
  window.scrollTo({ top: 0, behavior: 'smooth' });
};
</script>
