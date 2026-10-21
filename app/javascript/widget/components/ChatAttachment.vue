<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import FileUpload from 'vue-upload-component';
import { DirectUpload } from 'activestorage';
import Spinner from 'shared/components/Spinner.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import {
  checkFileSizeLimit,
  isFileTypeAllowedForChannel,
  resolveMaximumFileUploadSize,
} from 'shared/helpers/FileHelper';
import {
  ALLOWED_FILE_TYPES,
  MAXIMUM_ATTACHMENTS,
} from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useAttachments } from '../composables/useAttachments';

const props = defineProps({
  onAttach: {
    type: Function,
    default: () => {},
  },
});

// vue-upload-component emits one event per file; wait briefly to group one picker/paste action into a single message.
const UPLOAD_BATCH_DELAY = 50;

const { t } = useI18n();
const { canHandleAttachments } = useAttachments();
const globalConfig = useMapGetter('globalConfig/get');

const uploadRef = ref(null);
const activeUploads = ref(0);
const isUploading = computed(() => activeUploads.value > 0);
let pendingFiles = [];
let uploadBatchTimer = null;

const fileUploadSizeLimit = computed(() =>
  resolveMaximumFileUploadSize(globalConfig.value.maximumFileUploadSize)
);

const getFileType = fileType => (fileType.includes('image') ? 'image' : 'file');

const getLocalFileAttributes = file => ({
  thumbUrl: window.URL.createObjectURL(file.file),
  fileType: getFileType(file.type),
});

const getUploadableFiles = files => {
  const filesWithAllowedTypes = files.filter(file =>
    isFileTypeAllowedForChannel(file.file, {
      channelType: 'Channel::WebWidget',
    })
  );

  if (filesWithAllowedTypes.length !== files.length) {
    emitter.emit(BUS_EVENTS.SHOW_ALERT, {
      message: t('FILE_TYPE_NOT_SUPPORTED'),
    });
  }

  const validFiles = filesWithAllowedTypes.filter(file =>
    checkFileSizeLimit(file, fileUploadSizeLimit.value)
  );

  if (validFiles.length !== filesWithAllowedTypes.length) {
    emitter.emit(BUS_EVENTS.SHOW_ALERT, {
      message: t('FILE_SIZE_LIMIT', {
        MAXIMUM_FILE_UPLOAD_SIZE: fileUploadSizeLimit.value,
      }),
    });
  }

  return validFiles;
};

const splitIntoUploadBatches = items =>
  Array.from(
    { length: Math.ceil(items.length / MAXIMUM_ATTACHMENTS) },
    (_, index) =>
      items.slice(
        index * MAXIMUM_ATTACHMENTS,
        (index + 1) * MAXIMUM_ATTACHMENTS
      )
  );

const processBatchesSequentially = (batches, processBatch) =>
  batches.reduce(
    (promise, batch) => promise.then(() => processBatch(batch)),
    Promise.resolve()
  );

const trackUpload = async upload => {
  activeUploads.value += 1;
  try {
    await upload();
  } finally {
    activeUploads.value -= 1;
  }
};

const attachFiles = async attachments => {
  try {
    await props.onAttach(attachments);
  } catch (error) {
    emitter.emit(BUS_EVENTS.SHOW_ALERT, {
      message: error?.message || error,
    });
  }
};

const uploadFileDirectly = file => {
  const { websiteToken } = window.chatwootWebChannel;
  const upload = new DirectUpload(
    file.file,
    `/api/v1/widget/direct_uploads?website_token=${websiteToken}`,
    {
      directUploadWillCreateBlobWithXHR: xhr => {
        xhr.setRequestHeader('X-Auth-Token', window.authToken);
      },
    }
  );

  return new Promise(resolve => {
    upload.create((error, blob) => {
      if (error) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, { message: error });
        resolve(null);
      } else {
        resolve({ file: blob.signed_id, ...getLocalFileAttributes(file) });
      }
    });
  });
};

const onDirectFileUpload = async files => {
  const validFiles = getUploadableFiles(files);
  if (!validFiles.length) return;

  await trackUpload(() =>
    processBatchesSequentially(
      splitIntoUploadBatches(validFiles),
      async uploadBatch => {
        const attachments = await Promise.all(
          uploadBatch.map(file => uploadFileDirectly(file))
        );
        const successfulAttachments = attachments.filter(Boolean);

        if (successfulAttachments.length) {
          await attachFiles(successfulAttachments);
        }
      }
    )
  );
};

const onIndirectFileUpload = async files => {
  const validFiles = getUploadableFiles(files);
  if (!validFiles.length) return;

  await trackUpload(() =>
    processBatchesSequentially(
      splitIntoUploadBatches(validFiles),
      uploadBatch =>
        attachFiles(
          uploadBatch.map(file => ({
            file: file.file,
            ...getLocalFileAttributes(file),
          }))
        )
    )
  );
};

const flushUploadBatch = () => {
  const files = pendingFiles;
  pendingFiles = [];
  uploadBatchTimer = null;

  if (!files.length) return;

  if (globalConfig.value.directUploadsEnabled) {
    onDirectFileUpload(files);
  } else {
    onIndirectFileUpload(files);
  }
};

const onFileUpload = file => {
  if (!file) return;

  pendingFiles.push(file);
  clearTimeout(uploadBatchTimer);
  uploadBatchTimer = setTimeout(flushUploadBatch, UPLOAD_BATCH_DELAY);
};

const handleClipboardPaste = e => {
  // If file picker is not enabled, do not allow paste
  if (!canHandleAttachments.value) return;

  const { items } = e.clipboardData || e.originalEvent.clipboardData;
  // items is a DataTransferItemList object which does not have forEach method
  Array.from(items).forEach(item => {
    if (item.kind === 'file') {
      e.preventDefault();
      uploadRef.value.add(item.getAsFile());
    }
  });
};

onMounted(() => {
  document.addEventListener('paste', handleClipboardPaste);
});

onUnmounted(() => {
  document.removeEventListener('paste', handleClipboardPaste);
  clearTimeout(uploadBatchTimer);
});
</script>

<template>
  <FileUpload
    ref="uploadRef"
    :size="4096 * 2048"
    :accept="ALLOWED_FILE_TYPES"
    multiple
    :data="{
      direct_upload_url: '/api/v1/widget/direct_uploads',
      direct_upload: true,
    }"
    @input-file="onFileUpload"
  >
    <button class="min-h-8 min-w-8 flex items-center justify-center">
      <FluentIcon v-if="!isUploading" icon="attach" />
      <Spinner v-if="isUploading" size="small" />
    </button>
  </FileUpload>
</template>
