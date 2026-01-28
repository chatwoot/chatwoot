<!--
/**
 * FileUpload Component - Handles file upload with preview for media templates
 *
 * @param {Object|null} modelValue - Media upload data containing file information
 * @param {string} modelValue.blobId - ActiveStorage blob identifier
 * @param {string} modelValue.blobKey - ActiveStorage blob key for backend references
 * @param {string} modelValue.fileUrl - Full URL for file preview/display
 * @param {string} modelValue.fileName - Original filename with extension
 * @param {string} modelValue.contentType - MIME type (e.g., 'image/jpeg', 'video/mp4', 'application/pdf')
 * @param {boolean} modelValue.uploading - Upload state flag (managed by parent)
 *
 * @param {string} accept - File type filter (e.g., 'image/jpeg,image/jpg,image/png')
 * @param {number} maxSize - Maximum file size in MB (default: 8MB)
 * @param {string} label - Display label for the upload area
 * @param {'IMAGE'|'VIDEO'|'DOCUMENT'} format - Header format type from parent component
 * @param {boolean} uploading - Upload in progress state (managed by parent)
 * @param {string} error - Error message (managed by parent)
 *
 * @emits update:modelValue - Emitted when file is uploaded with media data
 * @emits uploadStart - Emitted when upload process begins
 * @emits uploadError - Emitted when upload fails with error message
 */
-->

<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { MEDIA_FORMATS } from 'dashboard/helper/templateHelper';

const props = defineProps({
  modelValue: {
    type: Object,
    default: () => null,
  },
  accept: {
    type: String,
    default: 'image/*,video/*',
  },
  maxSize: {
    type: Number,
    default: 8,
  },
  label: {
    type: String,
    default: '',
  },
  format: {
    type: String,
    default: 'IMAGE',
    validator: value => MEDIA_FORMATS.includes(value),
  },
  uploading: {
    type: Boolean,
    default: false,
  },
  error: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue', 'uploadStart', 'uploadError']);

const { t } = useI18n();

const fileInput = ref(null);

// Derive upload state from props instead of managing internal state
const uploadState = computed(() => {
  if (props.error) return 'error';
  if (props.uploading) return 'uploading';
  if (props.modelValue?.blobId) return 'uploaded';
  return 'idle';
});

const statusLabel = computed(() => {
  const states = {
    idle: t('SETTINGS.TEMPLATES.MEDIA.UPLOAD_LABEL'),
    uploading: t('SETTINGS.TEMPLATES.MEDIA.UPLOADING'),
    uploaded:
      props.modelValue?.fileName || t('SETTINGS.TEMPLATES.MEDIA.UPLOADED'),
    error: t('SETTINGS.TEMPLATES.MEDIA.UPLOAD_ERROR'),
  };
  return states[uploadState.value];
});

const statusIcon = computed(() => {
  const icons = {
    idle: 'i-lucide-upload',
    uploading: null,
    uploaded: 'i-lucide-check-circle',
    error: 'i-lucide-x-circle',
  };
  return icons[uploadState.value];
});

const handleFileSelect = async event => {
  const file = event.target.files?.[0];
  if (!file) return;

  // Validate file size
  if (file.size > props.maxSize * 1024 * 1024) {
    useAlert(t('SETTINGS.TEMPLATES.MEDIA.SIZE_ERROR', { size: props.maxSize }));
    return;
  }
  const isImage = file.type.startsWith('image/');
  const isVideo = file.type.startsWith('video/');
  const isDocument = file.type === 'application/pdf';

  if (!isImage && !isVideo && !isDocument) {
    useAlert(t('SETTINGS.TEMPLATES.MEDIA.TYPE_ERROR'));
    return;
  }
  emit('uploadStart');

  try {
    const { fileUrl, blobId, blobKey } = await uploadFile(file);
    emit('update:modelValue', {
      blobId,
      blobKey,
      fileUrl,
      fileName: file.name,
      contentType: file.type,
    });
  } catch (error) {
    emit('uploadError', t('SETTINGS.TEMPLATES.MEDIA.UPLOAD_FAILED'));
  }
};

const removeFile = () => {
  if (fileInput.value) {
    fileInput.value.value = '';
  }
  emit('update:modelValue', null);
};
</script>

<template>
  <div class="template-media-upload">
    <label v-if="label" class="block text-sm font-medium text-n-slate-11 mb-2">
      {{ label }}
    </label>

    <div class="upload-area">
      <input
        ref="fileInput"
        type="file"
        :accept="accept"
        class="hidden"
        @change="handleFileSelect"
      />

      <!-- Upload State: Idle or Error -->
      <Button
        v-if="uploadState === 'idle' || uploadState === 'error'"
        variant="outline"
        :color="uploadState === 'error' ? 'ruby' : 'slate'"
        size="lg"
        class="upload-dropzone w-full h-32 flex-col gap-2"
        @click="$refs.fileInput.click()"
      >
        <Icon :icon="statusIcon" class="text-2xl" />
        <div class="text-center">
          <p class="text-sm">{{ statusLabel }}</p>
          <p class="text-xs text-n-slate-11 mt-1">
            {{ t('SETTINGS.TEMPLATES.MEDIA.HINT', { size: maxSize }) }}
          </p>
        </div>
      </Button>

      <!-- Upload State: Uploading -->
      <div
        v-else-if="uploadState === 'uploading'"
        class="flex items-center justify-center gap-3 p-4 border border-n-weak rounded-lg bg-n-solid-2"
      >
        <Spinner :size="20" />
        <p class="text-sm text-n-slate-11">{{ statusLabel }}</p>
      </div>

      <!-- Upload State: Uploaded -->
      <div v-else-if="uploadState === 'uploaded'" class="uploaded-file">
        <div class="file-preview">
          <img
            v-if="format === 'IMAGE' && modelValue?.fileUrl"
            :src="modelValue.fileUrl"
            :alt="modelValue.fileName"
            class="w-12 h-12 rounded object-cover border border-n-weak"
          />
          <video
            v-else-if="format === 'VIDEO' && modelValue?.fileUrl"
            :src="modelValue.fileUrl"
            class="w-12 h-12 rounded object-cover border border-n-weak"
            muted
          />
          <div
            v-else
            class="w-12 h-12 rounded bg-n-solid-3 flex items-center justify-center border border-n-weak"
          >
            <Icon
              :icon="format === 'VIDEO' ? 'i-lucide-video' : 'i-lucide-file'"
              class="text-n-slate-9 text-2xl"
            />
          </div>
        </div>

        <div class="file-info">
          <p class="text-sm font-medium text-n-slate-12 truncate">
            {{ modelValue?.fileName }}
          </p>
          <p class="text-xs text-n-slate-11">
            {{
              format === 'IMAGE'
                ? t('SETTINGS.TEMPLATES.MEDIA.IMAGE')
                : format === 'VIDEO'
                  ? t('SETTINGS.TEMPLATES.MEDIA.VIDEO')
                  : t('SETTINGS.TEMPLATES.MEDIA.DOCUMENT')
            }}
          </p>
        </div>

        <Button
          variant="ghost"
          color="slate"
          size="sm"
          icon="i-lucide-x"
          @click="removeFile"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.template-media-upload {
  @apply w-full;
}

.upload-dropzone {
  @apply border-2 border-dashed !important;
}

.uploaded-file {
  @apply flex items-center gap-3;
  @apply border border-n-weak rounded-lg p-3;
  @apply bg-n-solid-2;
}

.file-preview {
  @apply flex-shrink-0;
}

.file-info {
  @apply flex-1 min-w-0;
}
</style>
