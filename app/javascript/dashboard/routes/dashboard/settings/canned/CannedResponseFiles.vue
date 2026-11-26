<script setup>
import { computed, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDropZone } from '@vueuse/core';
import { getAllowedFileTypesByChannel, getFileInfo } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import {
  checkFileSizeLimit,
  formatBytes,
  isFileTypeAllowedForChannel,
  resolveMaximumFileUploadSize,
} from 'shared/helpers/FileHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import FileIcon from 'dashboard/components-next/icon/FileIcon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

// A reply sends every file of the response in one message, which carries 15
const MAX_FILES = 15;

// A file has no `signed_id` until its upload finishes
const files = defineModel({ type: Array, required: true });

const { t } = useI18n();
const globalConfig = useMapGetter('globalConfig/get');

const dropZone = useTemplateRef('dropZone');
const fileInput = useTemplateRef('fileInput');

const maxFileSize = computed(() =>
  resolveMaximumFileUploadSize(globalConfig.value.maximumFileUploadSize)
);

const fileRows = computed(() =>
  files.value.map((file, index) => {
    const extension = getFileInfo(file.filename).type;
    const size = formatBytes(file.byte_size, 1);
    return {
      file,
      key: file.signed_id || `uploading-${index}`,
      extension,
      isImage: file.content_type.startsWith('image/'),
      isUploading: !file.signed_id,
      details: extension ? `${extension.toUpperCase()} · ${size}` : size,
    };
  })
);

const isAllowed = file => {
  if (!isFileTypeAllowedForChannel(file)) {
    useAlert(
      t('CANNED_MGMT.FILES.TYPE_NOT_SUPPORTED', { fileName: file.name })
    );
    return false;
  }
  if (!checkFileSizeLimit(file, maxFileSize.value)) {
    useAlert(
      t('CONVERSATION.FILE_SIZE_LIMIT', {
        MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE: maxFileSize.value,
      })
    );
    return false;
  }
  return true;
};

const uploadPendingFile = async ({ upload, ...details }) => {
  try {
    const { blobId, fileUrl } = await uploadFile(upload);
    return { ...details, signed_id: blobId, file_url: fileUrl };
  } catch (error) {
    useAlert(t('CANNED_MGMT.FILES.UPLOAD_ERROR', { fileName: upload.name }));
    return null;
  }
};

const addFiles = async selectedFiles => {
  const allowedFiles = Array.from(selectedFiles ?? []).filter(isAllowed);
  const remaining = MAX_FILES - files.value.length;
  if (allowedFiles.length > remaining) {
    useAlert(t('CANNED_MGMT.FILES.LIMIT', { count: MAX_FILES }));
  }

  const pendingFiles = allowedFiles.slice(0, remaining).map(file => ({
    filename: file.name,
    content_type: file.type,
    byte_size: file.size,
    upload: file,
  }));
  if (!pendingFiles.length) return;

  // The model only reflects a write once the parent re-renders, so a selection
  // is added in one write and settled in another instead of file by file.
  files.value = [...files.value, ...pendingFiles];
  const uploadedFiles = await Promise.all(pendingFiles.map(uploadPendingFile));

  const uploadedByFile = new Map(
    pendingFiles.map(({ upload }, index) => [upload, uploadedFiles[index]])
  );
  files.value = files.value
    .map(file =>
      uploadedByFile.has(file.upload) ? uploadedByFile.get(file.upload) : file
    )
    .filter(Boolean);
};

const onFileInputChange = event => {
  addFiles(event.target.files);
  event.target.value = '';
};

const removeFile = file => {
  files.value = files.value.filter(item => item !== file);
};

const { isOverDropZone } = useDropZone(dropZone, { onDrop: addFiles });
</script>

<template>
  <div class="flex flex-col gap-1">
    <span class="mb-0.5 text-heading-3 text-n-slate-12">
      {{ t('CANNED_MGMT.FILES.LABEL') }}
    </span>
    <div
      ref="dropZone"
      class="flex flex-wrap items-center gap-2 rounded-lg outline-dashed outline-1 outline-offset-4 transition-colors"
      :class="isOverDropZone ? 'outline-n-brand' : 'outline-transparent'"
    >
      <div
        v-for="row in fileRows"
        :key="row.key"
        class="flex items-center gap-2 max-w-full p-1.5 rounded-lg border border-n-strong bg-n-alpha-1"
      >
        <span
          class="grid flex-shrink-0 overflow-hidden rounded-md size-9 place-content-center bg-n-alpha-2 text-n-slate-11"
        >
          <Spinner v-if="row.isUploading" :size="16" />
          <img
            v-else-if="row.isImage"
            :src="row.file.file_url"
            :alt="row.file.filename"
            class="object-cover size-9"
          />
          <FileIcon v-else :file-type="row.extension" class="size-5" />
        </span>
        <div class="flex flex-col min-w-0">
          <span
            class="truncate text-body-main text-n-slate-12 max-w-48"
            :title="row.file.filename"
          >
            {{ row.file.filename }}
          </span>
          <span class="text-label-small text-n-slate-11">
            {{
              row.isUploading ? t('CANNED_MGMT.FILES.UPLOADING') : row.details
            }}
          </span>
        </div>
        <Button
          v-tooltip.top="t('CANNED_MGMT.FILES.REMOVE')"
          type="button"
          ghost
          slate
          xs
          icon="i-lucide-x"
          class="flex-shrink-0"
          @click="removeFile(row.file)"
        />
      </div>
      <Button
        type="button"
        faded
        slate
        sm
        icon="i-lucide-paperclip"
        :label="t('CANNED_MGMT.FILES.ADD')"
        @click="fileInput.click()"
      />
      <input
        ref="fileInput"
        type="file"
        multiple
        :accept="getAllowedFileTypesByChannel()"
        class="sr-only"
        @change="onFileInputChange"
      />
    </div>
  </div>
</template>
