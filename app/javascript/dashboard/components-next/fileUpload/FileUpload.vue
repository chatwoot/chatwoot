<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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

const emit = defineEmits(['fileSelected', 'fileError']);
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
    const errorMsg = t(
      'CAPTAIN.DOCUMENTS.CREATE.FORM.FILE_UPLOAD.ERROR_TOO_LARGE',
      {
        fileName: file.name,
        maxSize: props.maxSizeMB,
      }
    );
    emit('fileError', errorMsg);
    return false;
  }

  // Check file type if specified
  if (
    props.accept !== '*' &&
    !file.type.match(new RegExp(props.accept.replace(/\*/g, '.*')))
  ) {
    const errorMsg = t(
      'CAPTAIN.DOCUMENTS.CREATE.FORM.FILE_UPLOAD.ERROR_TYPE_NOT_SUPPORTED',
      {
        acceptedTypes: props.accept,
      }
    );
    emit('fileError', errorMsg);
    return false;
  }

  return true;
};

const handleFileChange = event => {
  const files = event.target.files;
  if (files && files.length > 0) {
    const file = files[0];
    if (validateFile(file)) {
      emit('fileSelected', file);
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
      emit('fileSelected', file);
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
    class="border-2 border-dashed border-n-slate-6 rounded-lg p-6 bg-n-alpha-2 hover:bg-n-alpha-3 cursor-pointer transition-all duration-200 ease-in-out flex flex-col items-center justify-center text-center min-h-[120px] hover:border-n-slate-7"
    :class="{
      'border-n-blue-9 bg-n-blue-2/50': isDragOver,
      'opacity-50 cursor-not-allowed hover:bg-n-alpha-2 hover:border-n-slate-6':
        disabled,
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

    <div class="flex flex-col items-center gap-3">
      <div class="p-2 rounded-full bg-n-alpha-3">
        <Icon icon="i-lucide-file-up" class="size-6 text-n-slate-8" />
      </div>
      <div>
        <p class="text-sm font-medium text-n-slate-11">
          {{ displayText }}
        </p>
        <p class="text-xs text-n-slate-8 mt-1">
          {{
            $t('CAPTAIN.DOCUMENTS.CREATE.FORM.FILE_UPLOAD.MAX_SIZE', {
              size: maxSizeMB,
            })
          }}
        </p>
      </div>
    </div>
  </div>
</template>
