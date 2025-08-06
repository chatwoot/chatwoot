<template>
  <div class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-6">
    <div class="mb-6">
      <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-2">
        {{ $t('HELP_CENTER.CONTENT_GENERATION.TITLE') }}
      </h3>
      <p class="text-sm text-slate-600 dark:text-slate-400">
        {{ $t('HELP_CENTER.CONTENT_GENERATION.DESCRIPTION') }}
      </p>
    </div>

    <!-- Upload Section -->
    <div class="mb-8">
      <h4 class="text-base font-medium text-slate-900 dark:text-slate-100 mb-4">
        {{ $t('HELP_CENTER.CONTENT_GENERATION.UPLOAD_TITLE') }}
      </h4>
      
      <div
        class="border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-lg p-6 text-center"
        :class="{
          'border-woot-500 bg-woot-25': isDragOver,
          'border-green-500 bg-green-25': uploadSuccess
        }"
        @drop="handleDrop"
        @dragover="handleDragOver"
        @dragleave="handleDragLeave"
      >
        <div v-if="!isUploading && !uploadSuccess">
          <DocumentPlusIcon class="mx-auto h-12 w-12 text-slate-400 mb-4" />
          <p class="text-sm text-slate-600 dark:text-slate-300 mb-2">
            {{ $t('HELP_CENTER.CONTENT_GENERATION.DRAG_DROP') }}
          </p>
          <input
            ref="fileInput"
            type="file"
            accept=".pdf"
            class="hidden"
            @change="handleFileSelect"
          >
          <button
            type="button"
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-woot-700 bg-woot-100 hover:bg-woot-200"
            @click="$refs.fileInput.click()"
          >
            {{ $t('HELP_CENTER.CONTENT_GENERATION.SELECT_FILE') }}
          </button>
        </div>

        <div v-else-if="isUploading" class="py-4">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-woot-500 mx-auto mb-2"></div>
          <p class="text-sm text-slate-600">{{ $t('HELP_CENTER.CONTENT_GENERATION.UPLOADING') }}</p>
        </div>

        <div v-else-if="uploadSuccess" class="py-4">
          <CheckCircleIcon class="mx-auto h-8 w-8 text-green-500 mb-2" />
          <p class="text-sm text-green-600">{{ $t('HELP_CENTER.CONTENT_GENERATION.UPLOAD_SUCCESS') }}</p>
        </div>
      </div>

      <div v-if="uploadError" class="mt-4 p-3 bg-red-50 border border-red-200 rounded-md">
        <p class="text-sm text-red-800">{{ uploadError }}</p>
      </div>
    </div>

    <!-- Generated Content Section -->
    <div v-if="generatedResponses.length > 0" class="mb-8">
      <div class="flex items-center justify-between mb-4">
        <h4 class="text-base font-medium text-slate-900 dark:text-slate-100">
          {{ $t('HELP_CENTER.CONTENT_GENERATION.GENERATED_CONTENT') }}
        </h4>
        <button
          v-if="selectedResponses.length > 0"
          class="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded text-white bg-woot-500 hover:bg-woot-600"
          @click="publishSelectedContent"
          :disabled="isPublishing"
        >
          <template v-if="isPublishing">
            <div class="animate-spin rounded-full h-4 w-4 border-b border-white mr-2"></div>
            {{ $t('HELP_CENTER.CONTENT_GENERATION.PUBLISHING') }}
          </template>
          <template v-else>
            {{ $t('HELP_CENTER.CONTENT_GENERATION.PUBLISH_SELECTED') }} ({{ selectedResponses.length }})
          </template>
        </button>
      </div>

      <div class="space-y-3 max-h-96 overflow-y-auto">
        <div
          v-for="response in generatedResponses"
          :key="response.id"
          class="border border-slate-200 dark:border-slate-600 rounded-lg p-4 hover:bg-slate-50 dark:hover:bg-slate-700"
        >
          <div class="flex items-start space-x-3">
            <input
              type="checkbox"
              :value="response.id"
              v-model="selectedResponses"
              class="mt-1 rounded border-slate-300 text-woot-500 focus:ring-woot-500"
            >
            <div class="flex-1 min-w-0">
              <h5 class="text-sm font-medium text-slate-900 dark:text-slate-100 mb-1">
                {{ response.question }}
              </h5>
              <p class="text-xs text-slate-600 dark:text-slate-400 line-clamp-2">
                {{ response.answer }}
              </p>
              <div class="mt-2 text-xs text-slate-500">
                {{ $t('HELP_CENTER.CONTENT_GENERATION.FROM_DOCUMENT') }}: {{ response.documentable?.name }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!isLoading" class="text-center py-8">
      <DocumentIcon class="mx-auto h-12 w-12 text-slate-400 mb-4" />
      <p class="text-slate-600 dark:text-slate-400">
        {{ $t('HELP_CENTER.CONTENT_GENERATION.NO_CONTENT') }}
      </p>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="text-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-woot-500 mx-auto mb-2"></div>
      <p class="text-slate-600">{{ $t('HELP_CENTER.CONTENT_GENERATION.LOADING') }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import {
  DocumentPlusIcon,
  DocumentIcon,
  CheckCircleIcon,
} from '@heroicons/vue/24/outline';

import PdfDocumentsAPI from '../../../../api/helpCenter/pdfDocuments';

const props = defineProps({
  portalSlug: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['content-published']);

const { t } = useI18n();
const route = useRoute();
const pdfDocumentsApi = new PdfDocumentsAPI();

// Reactive data
const generatedResponses = ref([]);
const selectedResponses = ref([]);
const isLoading = ref(false);
const isUploading = ref(false);
const isPublishing = ref(false);
const uploadSuccess = ref(false);
const uploadError = ref('');
const isDragOver = ref(false);

// Methods
const loadGeneratedContent = async () => {
  try {
    isLoading.value = true;
    const response = await pdfDocumentsApi.getGeneratedContent(props.portalSlug);
    generatedResponses.value = response.data.responses || [];
  } catch (error) {
    console.error('Failed to load generated content:', error);
  } finally {
    isLoading.value = false;
  }
};

const handleFileSelect = (event) => {
  const file = event.target.files[0];
  if (file) {
    uploadFile(file);
  }
};

const handleDrop = (event) => {
  event.preventDefault();
  isDragOver.value = false;
  
  const files = event.dataTransfer.files;
  if (files.length > 0) {
    uploadFile(files[0]);
  }
};

const handleDragOver = (event) => {
  event.preventDefault();
  isDragOver.value = true;
};

const handleDragLeave = (event) => {
  event.preventDefault();
  isDragOver.value = false;
};

const uploadFile = async (file) => {
  if (!validateFile(file)) return;

  try {
    isUploading.value = true;
    uploadError.value = '';

    const formData = new FormData();
    formData.append('pdf_file', file);

    await pdfDocumentsApi.uploadContent(props.portalSlug, formData);
    
    uploadSuccess.value = true;
    
    // Wait a bit then reload content
    setTimeout(async () => {
      uploadSuccess.value = false;
      await loadGeneratedContent();
    }, 2000);

  } catch (error) {
    uploadError.value = error.response?.data?.error || t('HELP_CENTER.CONTENT_GENERATION.UPLOAD_ERROR');
  } finally {
    isUploading.value = false;
  }
};

const validateFile = (file) => {
  if (file.type !== 'application/pdf') {
    uploadError.value = t('HELP_CENTER.CONTENT_GENERATION.INVALID_FILE_TYPE');
    return false;
  }
  
  if (file.size > 512 * 1024 * 1024) {
    uploadError.value = t('HELP_CENTER.CONTENT_GENERATION.FILE_TOO_LARGE');
    return false;
  }
  
  return true;
};

const publishSelectedContent = async () => {
  if (selectedResponses.value.length === 0) return;

  try {
    isPublishing.value = true;
    
    await pdfDocumentsApi.publishContent(props.portalSlug, selectedResponses.value);
    
    // Remove published responses from the list
    generatedResponses.value = generatedResponses.value.filter(
      response => !selectedResponses.value.includes(response.id)
    );
    
    selectedResponses.value = [];
    emit('content-published');
    
  } catch (error) {
    console.error('Failed to publish content:', error);
  } finally {
    isPublishing.value = false;
  }
};

// Lifecycle
onMounted(() => {
  loadGeneratedContent();
});
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>