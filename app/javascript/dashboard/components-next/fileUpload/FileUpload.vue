<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  accept: {
    type: String,
    default: '*',
  },
  multiple: {
    type: Boolean,
    default: false,
  },
  maxSizeMB: {
    type: Number,
    default: 10,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  placeholder: {
    type: String,
    default: '',
  },
  uploadText: {
    type: String,
    default: '',
  },
  dragText: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['file-selected', 'file-error']);

const { t } = useI18n();
const fileInput = ref(null);
const isDragOver = ref(false);

const acceptTypes = computed(() => props.accept);
const maxSize = computed(() => props.maxSizeMB * 1024 * 1024);

const handleFileClick = () => {
  if (!props.disabled) {
    fileInput.value?.click();
  }
};

const validateFile = file => {
  // Check file size
  if (file.size > maxSize.value) {
    const errorMsg = `File "${file.name}" is too large. Maximum size is ${props.maxSizeMB}MB.`;
    emit('file-error', errorMsg);
    return false;
  }

  // Check file type if specified
  if (
    props.accept !== '*' &&
    !file.type.match(new RegExp(props.accept.replace('*', '.*')))
  ) {
    const errorMsg = `File type not supported. Only ${props.accept} files are allowed.`;
    emit('file-error', errorMsg);
    return false;
  }

  return true;
};

const handleFileChange = event => {
  const files = event.target.files;
  if (files && files.length > 0) {
    const file = files[0];
    if (validateFile(file)) {
      emit('file-selected', file);
    }
  }
  // Reset input value to allow selecting the same file again
  event.target.value = '';
};

const handleDragOver = event => {
  event.preventDefault();
  if (!props.disabled) {
    isDragOver.value = true;
  }
};

const handleDragLeave = event => {
  event.preventDefault();
  // Only set to false if we're leaving the drop zone completely
  if (!event.currentTarget.contains(event.relatedTarget)) {
    isDragOver.value = false;
  }
};

const handleDrop = event => {
  event.preventDefault();
  isDragOver.value = false;

  if (props.disabled) return;

  const files = event.dataTransfer.files;
  if (files && files.length > 0) {
    const file = files[0];
    if (validateFile(file)) {
      emit('file-selected', file);
    }
  }
};

const displayText = computed(() => {
  if (isDragOver.value && props.dragText) {
    return props.dragText;
  }
  return props.uploadText || props.placeholder;
});
</script>

<template>
  <div
    class="file-upload-zone"
    :class="{
      'drag-over': isDragOver,
      disabled: disabled,
    }"
    @dragover="handleDragOver"
    @dragleave="handleDragLeave"
    @drop="handleDrop"
    @click="handleFileClick"
  >
    <input
      ref="fileInput"
      type="file"
      :accept="acceptTypes"
      :multiple="multiple"
      :disabled="disabled"
      class="hidden"
      @change="handleFileChange"
    />

    <div class="upload-content">
      <div class="upload-icon">
        <svg
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          class="text-n-slate-8"
        >
          <path
            d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z"
            fill="currentColor"
          />
        </svg>
      </div>
      <div class="upload-text">
        <p class="text-sm font-medium text-n-slate-11">
          {{ displayText }}
        </p>
        <p class="text-xs text-n-slate-8 mt-1">
          Maximum file size: {{ maxSizeMB }}MB
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.file-upload-zone {
  @apply border-2 border-dashed border-n-slate-6 rounded-lg p-6;
  @apply bg-n-alpha-2 hover:bg-n-alpha-3 cursor-pointer;
  @apply transition-all duration-200 ease-in-out;
  @apply flex flex-col items-center justify-center text-center;
  min-height: 120px;
}

.file-upload-zone:hover {
  @apply border-n-slate-7;
}

.file-upload-zone.drag-over {
  @apply border-primary-500 bg-primary-50/50;
}

.file-upload-zone.disabled {
  @apply opacity-50 cursor-not-allowed;
  @apply hover:bg-n-alpha-2 hover:border-n-slate-6;
}

.upload-content {
  @apply flex flex-col items-center gap-3;
}

.upload-icon {
  @apply p-2 rounded-full bg-n-alpha-3;
}
</style>
