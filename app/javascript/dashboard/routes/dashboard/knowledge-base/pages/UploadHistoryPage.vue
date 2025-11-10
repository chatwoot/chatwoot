<template>
  <div class="flex-1 overflow-auto bg-n-background">
    <KnowledgeBaseLayout
      :header-title="$t('KNOWLEDGE_BASE.UPLOAD_HISTORY.HEADER_TITLE')"
    >
      <div
        v-if="isInitialLoading"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>

      <div v-else-if="bulkRequests.length === 0" class="flex flex-col items-center justify-center py-20">
        <i class="i-lucide-history w-16 h-16 text-n-slate-9 mb-4" />
        <h3 class="text-lg font-medium text-n-slate-12 mb-2">
          {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.EMPTY_STATE.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11">
          {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.EMPTY_STATE.SUBTITLE') }}
        </p>
      </div>

      <div v-else class="space-y-6">
        <!-- Upload History Table -->
        <div class="bg-n-background rounded-lg border border-n-weak overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead class="bg-n-slate-2 border-b border-n-weak">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                    {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.TABLE.FILE_NAME') }}
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                    {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.TABLE.STATUS') }}
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                    {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.TABLE.UPLOADED_BY') }}
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                    {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.TABLE.DATE') }}
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                    {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.TABLE.TOTAL') }}
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                    {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.TABLE.PROCESSED') }}
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                    {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.TABLE.FAILED') }}
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                    {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.TABLE.ACTIONS') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-n-weak">
                <tr
                  v-for="request in bulkRequests"
                  :key="request.id"
                  class="hover:bg-n-slate-2 transition-colors"
                >
                  <td class="px-4 py-4">
                    <div class="flex items-center gap-2">
                      <i class="i-lucide-file-spreadsheet w-4 h-4 text-n-slate-11" />
                      <span class="text-sm font-medium text-n-slate-12">{{ request.file_name }}</span>
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium"
                      :class="getStatusClass(request.status)"
                    >
                      <i
                        class="w-3 h-3"
                        :class="getStatusIcon(request.status)"
                      />
                      {{ $t(`KNOWLEDGE_BASE.BULK_REQUESTS.STATUS.${request.status.toUpperCase()}`) }}
                    </span>
                  </td>
                  <td class="px-4 py-4">
                    <div class="text-sm text-n-slate-12">
                      {{ request.user?.name || 'Unknown' }}
                    </div>
                    <div class="text-xs text-n-slate-11">
                      {{ request.user?.email || '-' }}
                    </div>
                  </td>
                  <td class="px-4 py-4">
                    <span class="text-sm text-n-slate-11">{{ formatDate(request.created_at) }}</span>
                  </td>
                  <td class="px-4 py-4">
                    <span class="text-sm text-n-slate-12">{{ request.total_records || 0 }}</span>
                  </td>
                  <td class="px-4 py-4">
                    <span class="text-sm text-n-green-11 font-medium">{{ request.processed_records || 0 }}</span>
                  </td>
                  <td class="px-4 py-4">
                    <span class="text-sm text-n-red-11 font-medium">{{ request.failed_records || 0 }}</span>
                  </td>
                  <td class="px-4 py-4">
                    <button
                      v-if="hasErrors(request)"
                      class="inline-flex items-center gap-2 px-3 py-1.5 bg-n-red-9 text-white rounded-lg hover:bg-n-red-10 transition-colors text-sm font-medium"
                      @click="downloadErrors(request)"
                    >
                      <i class="i-lucide-download w-3.5 h-3.5" />
                      {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.DOWNLOAD_ERRORS') }}
                    </button>
                    <span v-else class="text-sm text-n-slate-11">-</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Pagination -->
        <div v-if="meta.total_pages > 1" class="flex items-center justify-between px-4 py-3 bg-n-solid-1 rounded-lg">
          <div class="text-sm text-n-slate-11">
            {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.PAGINATION.SHOWING') }}
            <span class="font-medium text-n-slate-12">{{ (meta.current_page - 1) * meta.per_page + 1 }}</span>
            {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.PAGINATION.TO') }}
            <span class="font-medium text-n-slate-12">{{ Math.min(meta.current_page * meta.per_page, meta.total_count) }}</span>
            {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.PAGINATION.OF') }}
            <span class="font-medium text-n-slate-12">{{ meta.total_count }}</span>
            {{ $t('KNOWLEDGE_BASE.UPLOAD_HISTORY.PAGINATION.RESULTS') }}
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
    </KnowledgeBaseLayout>
  </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import KnowledgeBaseLayout from 'dashboard/components-next/KnowledgeBase/KnowledgeBaseLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import BulkProcessingRequestsAPI from 'dashboard/api/bulkProcessingRequests';

const { t } = useI18n();
const store = useStore();

const isInitialLoading = ref(true);
const bulkRequests = ref([]);
const meta = ref({
  current_page: 1,
  total_pages: 1,
  total_count: 0,
  per_page: 50,
});

const visiblePages = computed(() => {
  const current = meta.value.current_page;
  const total = meta.value.total_pages;
  const pages = [];

  if (total <= 7) {
    for (let i = 1; i <= total; i++) {
      pages.push(i);
    }
  } else {
    pages.push(1);

    if (current <= 3) {
      for (let i = 2; i <= 5; i++) {
        pages.push(i);
      }
      pages.push('ellipsis1');
      pages.push(total);
    } else if (current >= total - 2) {
      pages.push('ellipsis1');
      for (let i = total - 4; i <= total; i++) {
        pages.push(i);
      }
    } else {
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
  await fetchBulkRequests(1);
});

const fetchBulkRequests = async (page = 1) => {
  try {
    const response = await BulkProcessingRequestsAPI.getAll({
      page,
      per_page: 50,
      entity_type: 'ProductCatalog'
    });

    bulkRequests.value = response.data.data;
    meta.value = response.data.meta;
  } catch (error) {
    console.error('Error fetching bulk requests:', error);
  } finally {
    // Only show initial loading spinner on first load
    if (isInitialLoading.value) {
      isInitialLoading.value = false;
    }
  }
};

const handlePageChange = async (page) => {
  if (page < 1 || page > meta.value.total_pages || page === meta.value.current_page) {
    return;
  }
  await fetchBulkRequests(page);
  window.scrollTo({ top: 0, behavior: 'smooth' });
};

const getStatusClass = (status) => {
  const statusUpper = status?.toUpperCase();
  switch (statusUpper) {
    case 'COMPLETED':
      return 'bg-n-green-2 text-n-green-11 border border-n-green-6';
    case 'FAILED':
      return 'bg-n-red-2 text-n-red-11 border border-n-red-6';
    case 'PROCESSING':
      return 'bg-n-blue-2 text-n-blue-11 border border-n-blue-6';
    case 'PENDING':
      return 'bg-n-orange-2 text-n-orange-11 border border-n-orange-6';
    case 'PARTIALLY_COMPLETED':
      return 'bg-n-yellow-2 text-n-yellow-11 border border-n-yellow-6';
    case 'CANCELLED':
      return 'bg-n-slate-2 text-n-slate-11 border border-n-slate-6';
    default:
      return 'bg-n-slate-2 text-n-slate-11 border border-n-slate-6';
  }
};

const getStatusIcon = (status) => {
  const statusUpper = status?.toUpperCase();
  switch (statusUpper) {
    case 'COMPLETED':
      return 'i-lucide-check-circle';
    case 'FAILED':
      return 'i-lucide-x-circle';
    case 'PROCESSING':
      return 'i-lucide-loader-circle animate-spin';
    case 'PENDING':
      return 'i-lucide-clock';
    case 'PARTIALLY_COMPLETED':
      return 'i-lucide-alert-circle';
    case 'CANCELLED':
      return 'i-lucide-ban';
    default:
      return 'i-lucide-help-circle';
  }
};

const formatDate = (dateString) => {
  const date = new Date(dateString);
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date);
};

const hasErrors = (request) => {
  const statusUpper = request.status?.toUpperCase();
  if (!['FAILED', 'PARTIALLY_COMPLETED'].includes(statusUpper)) {
    return false;
  }

  // Check if error_details has content
  if (Array.isArray(request.error_details) && request.error_details.length > 0) {
    return true;
  }

  // Also check if it's a string that's not empty or "[]"
  if (typeof request.error_details === 'string') {
    if (request.error_details === '[]' || request.error_details.trim() === '') {
      return false;
    }
    try {
      const parsed = JSON.parse(request.error_details);
      return Array.isArray(parsed) && parsed.length > 0;
    } catch (e) {
      return request.error_details.trim() !== '';
    }
  }

  return request.failed_records > 0;
};

const downloadErrors = async (request) => {
  try {
    const response = await BulkProcessingRequestsAPI.downloadErrors(request.id);

    const blob = new Blob([response.data], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('download', `errors_${request.file_name.replace('.xlsx', '')}_${new Date().toISOString().split('T')[0]}.csv`);
    link.setAttribute('href', url);
    link.click();
    URL.revokeObjectURL(url);
  } catch (error) {
    console.error('Failed to download errors:', error);
  }
};
</script>
