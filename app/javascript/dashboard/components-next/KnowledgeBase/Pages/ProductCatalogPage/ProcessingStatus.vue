<template>
  <div class="bg-n-blue-2 border border-n-blue-6 rounded-xl p-6 mb-6">
    <div class="flex items-start gap-4">
      <!-- Icon -->
      <div class="flex-shrink-0">
        <i
          class="w-10 h-10"
          :class="{
            'i-lucide-loader-circle animate-spin text-n-blue-11': statusUpper === 'PROCESSING',
            'i-lucide-check-circle text-n-green-11': statusUpper === 'COMPLETED',
            'i-lucide-x-circle text-n-red-11': statusUpper === 'FAILED',
            'i-lucide-clock text-n-orange-11': statusUpper === 'PENDING',
            'i-lucide-ban text-n-slate-11': statusUpper === 'CANCELLED'
          }"
        />
      </div>

      <!-- Content -->
      <div class="flex-1 min-w-0">
        <div class="flex items-center justify-between mb-2">
          <h3 class="text-base font-medium text-n-slate-12">
            {{ statusTitle }}
          </h3>
          <div class="flex items-center gap-2">
            <span class="text-sm text-n-slate-11">
              {{ fileName }}
            </span>
            <!-- Close button for completed/failed/cancelled statuses -->
            <button
              v-if="['COMPLETED', 'FAILED', 'PARTIALLY_COMPLETED', 'CANCELLED'].includes(statusUpper)"
              class="text-n-slate-11 hover:text-n-slate-12 transition-colors"
              @click="$emit('close')"
            >
              <i class="i-lucide-x w-5 h-5" />
            </button>
          </div>
        </div>

        <p class="text-sm text-n-slate-11 mb-4">
          {{ statusMessage }}
        </p>

        <!-- Progress Bar -->
        <div v-if="showProgress" class="mb-4">
          <div class="flex items-center justify-between text-xs text-n-slate-11 mb-2">
            <span>{{ $t('KNOWLEDGE_BASE.BULK_REQUESTS.PROGRESS') }}</span>
            <span>{{ progress }}%</span>
          </div>
          <div class="w-full bg-n-slate-3 rounded-full h-2">
            <div
              class="h-2 rounded-full transition-all duration-300"
              :class="{
                'bg-n-blue-9': statusUpper === 'PROCESSING' || statusUpper === 'PENDING',
                'bg-n-green-9': statusUpper === 'COMPLETED',
                'bg-n-red-9': statusUpper === 'FAILED',
                'bg-n-slate-9': statusUpper === 'CANCELLED'
              }"
              :style="{ width: `${progress}%` }"
            />
          </div>
        </div>

        <!-- Stats -->
        <div v-if="showStats" class="flex gap-6 text-sm">
          <div>
            <span class="text-n-slate-11">{{ $t('KNOWLEDGE_BASE.BULK_REQUESTS.TOTAL_RECORDS') }}:</span>
            <span class="text-n-slate-12 font-medium ml-1">{{ totalRecords }}</span>
          </div>
          <div>
            <span class="text-n-slate-11">{{ $t('KNOWLEDGE_BASE.BULK_REQUESTS.PROCESSED') }}:</span>
            <span class="text-n-green-11 font-medium ml-1">{{ processedRecords }}</span>
          </div>
          <div v-if="failedRecords > 0">
            <span class="text-n-slate-11">{{ $t('KNOWLEDGE_BASE.BULK_REQUESTS.FAILED') }}:</span>
            <span class="text-n-red-11 font-medium ml-1">{{ failedRecords }}</span>
          </div>
        </div>

        <!-- Error Message -->
        <div v-if="statusUpper === 'FAILED' && hasErrors" class="mt-4 p-3 bg-n-red-2 border border-n-red-6 rounded-lg">
          <p class="text-sm text-n-red-11">{{ errorMessage }}</p>
        </div>

        <!-- Download Errors Button -->
        <div v-if="hasErrors" class="mt-4">
          <button
            class="inline-flex items-center gap-2 px-4 py-2 bg-n-red-9 text-white rounded-lg hover:bg-n-red-10 transition-colors text-sm font-medium"
            @click="downloadErrors"
          >
            <i class="i-lucide-download w-4 h-4" />
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.DOWNLOAD_ERRORS') }}
          </button>
        </div>

        <!-- Success Message -->
        <div v-if="statusUpper === 'COMPLETED' && !hasErrors" class="mt-4 p-3 bg-n-green-2 border border-n-green-6 rounded-lg">
          <p class="text-sm text-n-green-11">{{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.ALL_PROCESSED_SUCCESSFULLY') }}</p>
        </div>
      </div>

      <!-- Cancel Button (only for PENDING/PROCESSING) -->
      <button
        v-if="canCancel"
        class="flex-shrink-0 text-n-slate-11 hover:text-n-red-11 transition-colors"
        @click="$emit('cancel')"
      >
        <i class="i-lucide-x w-5 h-5" />
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import BulkProcessingRequestsAPI from 'dashboard/api/bulkProcessingRequests';

const props = defineProps({
  status: {
    type: String,
    required: true,
    validator: value => ['PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'PARTIALLY_COMPLETED', 'CANCELLED', 'pending', 'processing', 'completed', 'failed', 'partially_completed', 'cancelled'].includes(value)
  },
  fileName: {
    type: String,
    required: true
  },
  progress: {
    type: Number,
    default: 0
  },
  totalRecords: {
    type: Number,
    default: 0
  },
  processedRecords: {
    type: Number,
    default: 0
  },
  failedRecords: {
    type: Number,
    default: 0
  },
  errorMessage: {
    type: String,
    default: null
  },
  errorDetails: {
    type: [Array, String],
    default: () => []
  },
  bulkRequestId: {
    type: Number,
    required: true
  }
});

defineEmits(['cancel', 'close']);

const { t } = useI18n();
const store = useStore();

const statusUpper = computed(() => props.status?.toUpperCase());

const statusTitle = computed(() => {
  return t(`KNOWLEDGE_BASE.BULK_REQUESTS.STATUS.${statusUpper.value}`);
});

const statusMessage = computed(() => {
  switch (statusUpper.value) {
    case 'PENDING':
      return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.PROCESSING_MESSAGE');
    case 'PROCESSING':
      return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.PROCESSING_MESSAGE');
    case 'COMPLETED':
      return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.SUCCESS_MESSAGE');
    case 'PARTIALLY_COMPLETED':
      return `${props.processedRecords} of ${props.totalRecords} records processed successfully`;
    case 'FAILED':
      return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.ERROR');
    case 'CANCELLED':
      return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.CANCELLED');
    default:
      return '';
  }
});

const showProgress = computed(() => {
  return ['PENDING', 'PROCESSING'].includes(statusUpper.value) || props.progress > 0;
});

const showStats = computed(() => {
  return props.totalRecords > 0 && ['PROCESSING', 'COMPLETED', 'PARTIALLY_COMPLETED', 'FAILED'].includes(statusUpper.value);
});

const canCancel = computed(() => {
  return ['PENDING', 'PROCESSING'].includes(statusUpper.value);
});

const hasErrors = computed(() => {
  if (!['FAILED', 'PARTIALLY_COMPLETED'].includes(statusUpper.value)) {
    return false;
  }

  // Check if error_details has content
  if (Array.isArray(props.errorDetails) && props.errorDetails.length > 0) {
    return true;
  }

  // Also check if it's a string that's not empty or "[]"
  if (typeof props.errorDetails === 'string') {
    if (props.errorDetails === '[]' || props.errorDetails.trim() === '') {
      return false;
    }
    // Try to parse JSON string
    try {
      const parsed = JSON.parse(props.errorDetails);
      return Array.isArray(parsed) && parsed.length > 0;
    } catch (e) {
      // If not valid JSON, check if non-empty string
      return props.errorDetails.trim() !== '';
    }
  }

  // Fallback to failedRecords check
  return props.failedRecords > 0;
});

const downloadErrors = async () => {
  try {
    // Use the API client which has authentication configured
    const response = await BulkProcessingRequestsAPI.downloadErrors(props.bulkRequestId);

    // Create a blob from CSV text and trigger download
    const blob = new Blob([response.data], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('download', `errors_${props.fileName.replace('.xlsx', '')}_${new Date().toISOString().split('T')[0]}.csv`);
    link.setAttribute('href', url);
    link.click();
    URL.revokeObjectURL(url);
  } catch (error) {
    console.error('Failed to download errors:', error);
  }
};
</script>
