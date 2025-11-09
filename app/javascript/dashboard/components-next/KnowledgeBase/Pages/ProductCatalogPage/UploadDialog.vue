<template>
  <div class="w-[28rem] z-50 absolute top-10 right-0 bg-n-alpha-3 backdrop-blur-[100px] p-6 rounded-xl border border-n-weak shadow-md flex flex-col gap-6">
    <div class="flex items-start justify-between">
      <div>
        <h3 class="text-base font-medium text-n-slate-12">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.DESCRIPTION') }}
        </p>
      </div>
      <button
        class="text-n-slate-11 hover:text-n-slate-12"
        @click="emit('close')"
      >
        <i class="i-lucide-x w-5 h-5" />
      </button>
    </div>

    <div class="flex flex-col gap-4">
      <!-- File Input -->
      <div
        class="border-2 border-dashed border-n-slate-6 rounded-lg p-6 text-center cursor-pointer hover:border-n-blue-9 hover:bg-n-blue-2 transition-colors"
        :class="{ 'border-n-blue-9 bg-n-blue-2': selectedFile }"
        @click="triggerFileInput"
        @dragover.prevent
        @drop.prevent="handleDrop"
      >
        <input
          ref="fileInputRef"
          type="file"
          accept=".xlsx"
          class="hidden"
          @change="handleFileSelect"
        />

        <div v-if="!selectedFile" class="flex flex-col items-center gap-2">
          <i class="i-lucide-upload w-8 h-8 text-n-slate-11" />
          <p class="text-sm font-medium text-n-slate-12">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.SELECT_FILE') }}
          </p>
          <p class="text-xs text-n-slate-11">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.FILE_FORMAT') }}
          </p>
        </div>

        <div v-else class="flex items-center gap-3">
          <i class="i-lucide-file-spreadsheet w-8 h-8 text-n-green-11" />
          <div class="flex-1 text-left">
            <p class="text-sm font-medium text-n-slate-12">
              {{ selectedFile.name }}
            </p>
            <p class="text-xs text-n-slate-11">
              {{ formatFileSize(selectedFile.size) }}
            </p>
          </div>
          <button
            class="text-n-slate-11 hover:text-n-red-11"
            @click.stop="clearFile"
          >
            <i class="i-lucide-x w-5 h-5" />
          </button>
        </div>
      </div>

      <!-- Column Mapping Info -->
      <div class="bg-n-blue-2 border border-n-blue-6 rounded-lg p-3">
        <p class="text-xs text-n-blue-11">
          Column mapping (A-L): ID,
          <span class="text-n-orange-11 font-semibold underline">Industry</span>,
          <span class="text-n-orange-11 font-semibold underline">Product Name</span>,
          <span class="text-n-orange-11 font-semibold underline">Type</span>,
          Subcategory, List Price,
          <span class="text-n-orange-11 font-semibold underline">Payment Options (semicolon-separated)</span>,
          Description, External Links (semicolon-separated), PDF URLs (semicolon-separated), Photo URLs (semicolon-separated), Video URLs (semicolon-separated)
        </p>
      </div>

      <!-- Progress Bar -->
      <div v-if="isUploading || uploadStatus" class="space-y-2">
        <div class="flex items-center justify-between text-sm">
          <span class="text-n-slate-11">{{ statusMessage }}</span>
          <span class="text-n-slate-12">{{ uploadProgress }}%</span>
        </div>
        <div class="w-full bg-n-slate-3 rounded-full h-2">
          <div
            class="bg-n-blue-9 h-2 rounded-full transition-all duration-300"
            :class="{
              'bg-n-green-9': uploadStatus === 'success',
              'bg-n-red-9': uploadStatus === 'error'
            }"
            :style="{ width: `${uploadProgress}%` }"
          />
        </div>

        <!-- Processing Status -->
        <div v-if="uploadStatus === 'processing'" class="bg-n-blue-2 border border-n-blue-6 rounded-lg p-3">
          <p class="text-xs text-n-blue-11">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.PROCESSING_MESSAGE') }}
          </p>
        </div>

        <!-- Success Message -->
        <div v-if="uploadStatus === 'success'" class="bg-n-green-2 border border-n-green-6 rounded-lg p-3">
          <p class="text-xs text-n-green-11">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.SUCCESS_MESSAGE') }}
          </p>
        </div>

        <!-- Error Message -->
        <div v-if="uploadStatus === 'error'" class="bg-n-red-2 border border-n-red-6 rounded-lg p-3">
          <p class="text-xs text-n-red-11">
            {{ errorMessage || $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.ERROR') }}
          </p>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex gap-3">
        <Button
          variant="outline"
          :label="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.CANCEL')"
          class="flex-1"
          @click="emit('close')"
        />
        <Button
          :label="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.UPLOAD_BTN')"
          :disabled="!selectedFile || isUploading"
          :is-loading="isUploading"
          class="flex-1"
          @click="handleUpload"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  isProcessing: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['close', 'upload-success']);
const { t } = useI18n();
const store = useStore();

// Check for active processing on mount
onMounted(async () => {
  if (props.isProcessing) {
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.ALREADY_PROCESSING'));
    emit('close');
  }
});

const fileInputRef = ref(null);
const selectedFile = ref(null);
const uploadProgress = ref(0);
const uploadStatus = ref(null); // null | 'processing' | 'success' | 'error'
const errorMessage = ref(null);

const uiFlags = useMapGetter('productCatalogs/getUIFlags');
const isUploading = computed(() => uiFlags.value.isUploading || props.isProcessing);

const statusMessage = computed(() => {
  if (uploadStatus.value === 'processing') {
    return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.PROCESSING');
  }
  if (uploadStatus.value === 'success') {
    return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.COMPLETED');
  }
  if (uploadStatus.value === 'error') {
    return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.FAILED');
  }
  return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.UPLOADING');
});

const triggerFileInput = () => {
  fileInputRef.value?.click();
};

const handleFileSelect = event => {
  const file = event.target.files[0];
  if (file) {
    validateAndSetFile(file);
  }
};

const handleDrop = event => {
  const file = event.dataTransfer.files[0];
  if (file) {
    validateAndSetFile(file);
  }
};

const validateAndSetFile = file => {
  if (!file.name.endsWith('.xlsx')) {
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.ERROR'));
    return;
  }
  selectedFile.value = file;
};

const clearFile = () => {
  selectedFile.value = null;
  uploadProgress.value = 0;
};

const formatFileSize = bytes => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${Math.round(bytes / Math.pow(k, i) * 100) / 100} ${sizes[i]}`;
};

const handleUpload = async () => {
  if (!selectedFile.value) return;

  try {
    uploadProgress.value = 0;
    uploadStatus.value = null;
    errorMessage.value = null;

    // Simulate progress (since we don't have real upload progress from FormData)
    const progressInterval = setInterval(() => {
      if (uploadProgress.value < 90) {
        uploadProgress.value += 10;
      }
    }, 200);

    const response = await store.dispatch('productCatalogs/bulkUpload', selectedFile.value);

    clearInterval(progressInterval);
    uploadProgress.value = 100;

    // Emit success with bulk_request_id
    emit('upload-success', response.bulk_request_id);
  } catch (error) {
    uploadStatus.value = 'error';
    errorMessage.value = error.message || t('KNOWLEDGE_BASE.PRODUCT_CATALOG.UPLOAD.ERROR');
    useAlert(errorMessage.value);
  }
};
</script>
