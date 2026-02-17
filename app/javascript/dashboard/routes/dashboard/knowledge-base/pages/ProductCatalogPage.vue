<template>
  <div class="flex-1 overflow-auto bg-n-background">
    <KnowledgeBaseLayout
      :header-title="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.HEADER_TITLE')"
      :button-label="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.NEW_PRODUCT')"
      :button-disabled="hasActiveDialog"
      :button-loading="isProcessing && isUploadOperation"
      :show-button="!isInitialLoading"
      @click="toggleUploadDialog()"
    >
      <template v-if="!isInitialLoading" #header-actions>
        <button
          class="h-8 px-3 bg-n-slate-3 text-n-slate-12 rounded-lg hover:bg-n-slate-4 transition-colors text-sm font-medium flex items-center gap-2"
          @click="navigateToUploadHistory"
        >
          <i class="i-lucide-history w-4 h-4 flex-shrink-0" />
          <span class="hidden sm:inline">{{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD_HISTORY') }}</span>
        </button>
        <button
          class="h-8 px-3 bg-n-slate-3 text-n-slate-12 rounded-lg hover:bg-n-slate-4 transition-colors text-sm font-medium flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
          :disabled="hasActiveDialog || hasNoProducts"
          @click="handleExportAll"
        >
          <i class="i-lucide-file-down w-4 h-4 flex-shrink-0" />
          <span class="hidden sm:inline">{{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EXPORT_ALL.BUTTON') }}</span>
          <Spinner v-if="isProcessing && isExportOperation" class="!w-4 !h-4 flex-shrink-0" />
        </button>
        <button
          class="h-8 px-3 bg-n-blue-9 text-white rounded-lg hover:bg-n-blue-10 transition-colors text-sm font-medium flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
          :disabled="isDownloadingTemplate"
          @click="handleDownloadTemplate"
        >
          <i class="i-lucide-download w-4 h-4 flex-shrink-0" />
          <span class="hidden sm:inline">{{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DOWNLOAD_TEMPLATE') }}</span>
          <Spinner v-if="isDownloadingTemplate" class="!w-4 !h-4 flex-shrink-0" />
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
        v-if="isInitialLoading"
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
        :operation-type="activeProcessing.operation_type"
        class="mb-6"
        @cancel="handleCancelProcessing"
        @close="handleCloseProcessingStatus"
        @download-complete="handleExportDownloadComplete"
      />

      <!-- Media Specifications Notice -->
      <MediaSpecsNotice class="mb-6" />

      <div v-if="!hasNoProducts || activeProcessing || searchQuery || isSearching" class="space-y-6">

        <!-- Search Bar and Bulk Actions -->
        <div v-if="!hasNoProducts || activeProcessing || searchQuery || isSearching" class="flex items-center gap-2">
          <Input
            :model-value="searchQuery"
            type="search"
            :placeholder="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.SEARCH_PLACEHOLDER')"
            :custom-input-class="[
              'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
            ]"
            :disabled="!!activeProcessing"
            class="w-full"
            @input="searchQuery = $event.target.value"
            @enter="handleSearchEnter"
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

        <!-- Loading State while searching -->
        <div v-if="isSearching" class="flex items-center justify-center py-16">
          <Spinner />
        </div>

        <!-- No Search Results Message -->
        <div v-else-if="hasNoSearchResults" class="flex flex-col items-center justify-center py-16 text-center">
          <i class="i-lucide-search-x w-12 h-12 text-n-slate-9 mb-4" />
          <p class="text-n-slate-11 text-sm">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.NO_SEARCH_RESULTS') }}
          </p>
        </div>

        <!-- Product Table -->
        <ProductTable
          v-else-if="filteredProducts.length > 0"
          :products="filteredProducts"
          :selected-product-id="selectedProductForMedia?.id"
          :selected-product-ids="selectedProductIds"
          @update:selected-product-ids="handleSelectedProductIdsUpdate"
          @select="handleProductSelect"
          @delete="handleDelete"
          @toggle-visibility="handleToggleVisibility"
        />

        <!-- Pagination -->
        <div v-if="!searchQuery && meta.total_pages > 1" class="flex flex-col sm:flex-row items-center justify-between gap-3 mt-6 px-4 py-3 bg-n-solid-1 rounded-lg">
          <div class="hidden sm:block text-sm text-n-slate-11">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.SHOWING') }}
            <span class="font-medium text-n-slate-12">{{ (meta.current_page - 1) * meta.per_page + 1 }}</span>
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.TO') }}
            <span class="font-medium text-n-slate-12">{{ Math.min(meta.current_page * meta.per_page, meta.total_count) }}</span>
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.OF') }}
            <span class="font-medium text-n-slate-12">{{ meta.total_count }}</span>
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.RESULTS') }}
          </div>
          <!-- Mobile: show compact info -->
          <div class="sm:hidden text-xs text-n-slate-11">
            {{ meta.current_page }} / {{ meta.total_pages }}
          </div>

          <div class="flex items-center gap-1 sm:gap-2 flex-wrap justify-center">
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
      :product="selectedProductForMedia"
      @close="selectedProductForMedia = null"
    />
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
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
import MediaSpecsNotice from 'dashboard/components-next/KnowledgeBase/Pages/ProductCatalogPage/MediaSpecsNotice.vue';
import ProductCatalogAPI from 'dashboard/api/productCatalog';

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const [showUploadDialog, toggleUploadDialog] = useToggle();
const selectedProduct = ref(null);
const selectedProductForMedia = ref(null);
const selectedProductIds = ref([]);
const deleteDialogRef = ref(null);
const activeProcessing = ref(null);
const pollingInterval = ref(null);
const searchQuery = ref('');
const searchAbortController = ref(null);
const isInitialLoading = ref(true);
const isDownloadingTemplate = ref(false);
const isSearching = ref(false);

const uiFlags = useMapGetter('productCatalogs/getUIFlags');

const products = computed(() => store.getters['productCatalogs/getProductCatalogs']);
const meta = computed(() => store.getters['productCatalogs/getMeta']);

// Check if there are no products at all (not searching)
const hasNoProducts = computed(() => {
  return products.value?.length === 0 && !isInitialLoading.value && !searchQuery.value && !isSearching.value;
});

// Check if search returned no results
const hasNoSearchResults = computed(() => {
  return products.value?.length === 0 && !isInitialLoading.value && !!searchQuery.value && !isSearching.value;
});

// Use products directly - search is now handled by the backend
const filteredProducts = computed(() => products.value);

const isProcessing = computed(() => {
  return activeProcessing.value && ['PENDING', 'PROCESSING'].includes(activeProcessing.value.status?.toUpperCase());
});

// Block buttons when there's any active dialog (pending dismissal)
const hasActiveDialog = computed(() => {
  return !!activeProcessing.value;
});

// Check if current operation is export
const isExportOperation = computed(() => {
  return activeProcessing.value?.operation_type?.toUpperCase() === 'EXPORT';
});

// Check if current operation is upload
const isUploadOperation = computed(() => {
  return activeProcessing.value?.operation_type?.toUpperCase() === 'UPLOAD';
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
  try {
    await store.dispatch('productCatalogs/get', { page: 1, per_page: 50 });
    await checkActiveProcessing();
  } finally {
    isInitialLoading.value = false;
  }
});

onUnmounted(() => {
  stopPolling();
  // Cancel any pending search requests
  if (searchAbortController.value) {
    searchAbortController.value.abort();
  }
});

// Core search function
const executeSearch = async (query) => {
  // If already searching, ignore this request
  if (isSearching.value) {
    return;
  }

  // Cancel previous search request if it exists
  if (searchAbortController.value) {
    searchAbortController.value.abort();
  }

  // Create new abort controller for this search
  searchAbortController.value = new AbortController();
  isSearching.value = true;

  try {
    // Perform search with query parameter
    await store.dispatch('productCatalogs/get', {
      page: 1,
      per_page: 50,
      q: query || undefined
    });
  } catch (error) {
    // Ignore abort errors (expected when we cancel previous requests)
    if (error.name !== 'AbortError' && error.name !== 'CanceledError') {
      console.error('Search error:', error);
    }
  } finally {
    isSearching.value = false;
  }
};

// Debounce timer reference
const searchDebounceTimer = ref(null);

// Debounced search function - waits 1.5s after user stops typing
const performSearch = (query) => {
  // Clear any existing timer
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value);
  }

  // Set new timer
  searchDebounceTimer.value = setTimeout(() => {
    executeSearch(query);
    searchDebounceTimer.value = null;
  }, 1500);
};

// Immediate search on Enter key
const handleSearchEnter = () => {
  // Cancel the debounced search
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value);
    searchDebounceTimer.value = null;
  }
  // Execute search immediately
  executeSearch(searchQuery.value);
};

// Watch for search query changes
watch(searchQuery, (newQuery) => {
  performSearch(newQuery);
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
          const operationType = updated.operation_type?.toUpperCase();

          if (operationType === 'EXPORT') {
            // For EXPORT operations, keep dialog open so user can download
            useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EXPORT_ALL.COMPLETED'));
          } else {
            // For UPLOAD operations, auto-dismiss
            useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.SUCCESS_MESSAGE'));
            const requestId = activeProcessing.value.id;
            activeProcessing.value = null;

            // Mark as dismissed in background
            store.dispatch('bulkProcessingRequests/dismiss', requestId).catch(error => {
              console.error('Error dismissing bulk request:', error);
            });
          }
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
    file_name: 'Processing...',
    operation_type: 'UPLOAD'
  };

  startPolling();
};

const handleExportAll = async () => {
  try {
    const response = await store.dispatch('productCatalogs/exportAll');

    // Set active processing for export
    activeProcessing.value = {
      id: response.bulk_request_id,
      status: 'PENDING',
      progress: 0,
      total_records: 0,
      processed_records: 0,
      failed_records: 0,
      file_name: `product_catalog_full_export_${new Date().toISOString().split('T')[0]}.xlsx`,
      operation_type: 'EXPORT'
    };

    startPolling();

    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EXPORT_ALL.STARTED'));
  } catch (error) {
    // Handle rate limit error
    if (error.isRateLimited) {
      useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EXPORT_ALL.RATE_LIMITED', { seconds: error.retryAfter }));
    } else {
      useAlert(error.message || t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EXPORT_ALL.ERROR'));
    }
  }
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

    // Save operation type before clearing
    const wasExport = activeProcessing.value.operation_type?.toUpperCase() === 'EXPORT';

    // Now attempt to cancel
    await store.dispatch('bulkProcessingRequests/cancel', activeProcessing.value.id);

    // Stop polling
    stopPolling();

    // Clear active processing
    activeProcessing.value = null;

    // Show appropriate message based on operation type
    const cancelMessage = wasExport
      ? t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EXPORT_ALL.CANCELLED')
      : t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.CANCELLED');
    useAlert(cancelMessage);
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

const handleCloseProcessingStatus = async () => {
  // Only allow closing if status is final (not PENDING or PROCESSING)
  if (activeProcessing.value) {
    const statusUpper = activeProcessing.value.status?.toUpperCase();
    if (['COMPLETED', 'FAILED', 'PARTIALLY_COMPLETED', 'CANCELLED'].includes(statusUpper)) {
      const requestId = activeProcessing.value.id;

      // Refresh products first to show latest data
      await store.dispatch('productCatalogs/get', { page: meta.value.current_page, per_page: 50 });

      // Close dialog after refresh
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

const handleToggleVisibility = async (product) => {
  try {
    await store.dispatch('productCatalogs/toggleVisibility', product.id);
    useAlert(product.is_visible
      ? t('KNOWLEDGE_BASE.PRODUCT_CATALOG.VISIBILITY.HIDDEN')
      : t('KNOWLEDGE_BASE.PRODUCT_CATALOG.VISIBILITY.SHOWN')
    );
  } catch (error) {
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.VISIBILITY.ERROR'));
  }
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
  isDownloadingTemplate.value = true;
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
  } finally {
    isDownloadingTemplate.value = false;
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

const navigateToUploadHistory = () => {
  router.push({ name: 'knowledge_base_upload_history' });
};

const handleExportDownloadComplete = () => {
  // Close the dialog immediately after download starts
  // The backend handles file cleanup and marking as dismissed
  activeProcessing.value = null;
  useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EXPORT_SUCCESS', { count: '' }));
};
</script>
