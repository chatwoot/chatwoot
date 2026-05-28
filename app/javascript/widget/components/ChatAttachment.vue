<script>
import FileUpload from 'vue-upload-component';
import Spinner from 'shared/components/Spinner.vue';
import {
  checkFileSizeLimit,
  resolveMaximumFileUploadSize,
} from 'shared/helpers/FileHelper';
import {
  ALLOWED_FILE_TYPES,
  MAXIMUM_ATTACHMENTS,
} from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { DirectUpload } from 'activestorage';
import { mapGetters } from 'vuex';
import { emitter } from 'shared/helpers/mitt';
import { useAttachments } from '../composables/useAttachments';

// vue-upload-component emits one event per file; wait briefly to group one picker/paste action into a single message.
const UPLOAD_BATCH_DELAY = 50;

export default {
  components: { FluentIcon, FileUpload, Spinner },
  props: {
    onAttach: {
      type: Function,
      default: () => {},
    },
  },
  setup() {
    const { canHandleAttachments } = useAttachments();
    return { canHandleAttachments };
  },
  data() {
    return {
      activeUploadBatches: 0,
      isUploading: false,
      pendingFiles: [],
      uploadBatchTimer: null,
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    fileUploadSizeLimit() {
      return resolveMaximumFileUploadSize(
        this.globalConfig.maximumFileUploadSize
      );
    },
    allowedFileTypes() {
      return ALLOWED_FILE_TYPES;
    },
  },
  mounted() {
    document.addEventListener('paste', this.handleClipboardPaste);
  },
  unmounted() {
    document.removeEventListener('paste', this.handleClipboardPaste);
    if (this.uploadBatchTimer) {
      clearTimeout(this.uploadBatchTimer);
    }
  },
  methods: {
    handleClipboardPaste(e) {
      // If file picker is not enabled, do not allow paste
      if (!this.canHandleAttachments) return;

      const items = (e.clipboardData || e.originalEvent.clipboardData).items;
      // items is a DataTransferItemList object which does not have forEach method
      const itemsArray = Array.from(items);
      itemsArray.forEach(item => {
        if (item.kind === 'file') {
          e.preventDefault();
          const file = item.getAsFile();
          this.$refs.upload.add(file);
        }
      });
    },
    getFileType(fileType) {
      return fileType.includes('image') ? 'image' : 'file';
    },
    onFileUpload(file) {
      if (!file) {
        return;
      }

      this.pendingFiles.push(file);
      this.scheduleUploadBatch();
    },
    scheduleUploadBatch() {
      if (this.uploadBatchTimer) {
        clearTimeout(this.uploadBatchTimer);
      }

      this.uploadBatchTimer = setTimeout(
        () => this.flushUploadBatch(),
        UPLOAD_BATCH_DELAY
      );
    },
    flushUploadBatch() {
      const files = [...this.pendingFiles];
      this.pendingFiles = [];
      this.uploadBatchTimer = null;

      if (!files.length) {
        return;
      }

      if (this.globalConfig.directUploadsEnabled) {
        this.onDirectFileUpload(files);
      } else {
        this.onIndirectFileUpload(files);
      }
    },
    getUploadableFiles(files) {
      const validFiles = files.filter(file =>
        checkFileSizeLimit(file, this.fileUploadSizeLimit)
      );

      if (validFiles.length !== files.length) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('FILE_SIZE_LIMIT', {
            MAXIMUM_FILE_UPLOAD_SIZE: this.fileUploadSizeLimit,
          }),
        });
      }

      if (validFiles.length > MAXIMUM_ATTACHMENTS) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('MAXIMUM_ATTACHMENTS_LIMIT', {
            MAXIMUM_ATTACHMENTS,
          }),
        });
        return validFiles.slice(0, MAXIMUM_ATTACHMENTS);
      }

      return validFiles;
    },
    startUploadBatch() {
      this.activeUploadBatches += 1;
      this.isUploading = true;
    },
    finishUploadBatch() {
      this.activeUploadBatches = Math.max(this.activeUploadBatches - 1, 0);
      this.isUploading = this.activeUploadBatches > 0;
    },
    async onDirectFileUpload(files) {
      const validFiles = this.getUploadableFiles(files);

      if (!validFiles.length) {
        return;
      }

      this.startUploadBatch();
      try {
        const attachments = await Promise.all(
          validFiles.map(file => this.uploadFileDirectly(file))
        );
        const successfulAttachments = attachments.filter(Boolean);

        if (successfulAttachments.length) {
          await this.attachFiles(successfulAttachments);
        }
      } finally {
        this.finishUploadBatch();
      }
    },
    uploadFileDirectly(file) {
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
            emitter.emit(BUS_EVENTS.SHOW_ALERT, {
              message: error,
            });
            resolve(null);
          } else {
            resolve({
              file: blob.signed_id,
              ...this.getLocalFileAttributes(file),
            });
          }
        });
      });
    },
    async onIndirectFileUpload(files) {
      const validFiles = this.getUploadableFiles(files);

      if (!validFiles.length) {
        return;
      }

      const attachments = validFiles.map(file => ({
        file: file.file,
        ...this.getLocalFileAttributes(file),
      }));

      this.startUploadBatch();
      try {
        await this.attachFiles(attachments);
      } finally {
        this.finishUploadBatch();
      }
    },
    async attachFiles(attachments) {
      try {
        await this.onAttach(attachments);
      } catch (error) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: error?.message || error,
        });
      }
    },
    getLocalFileAttributes(file) {
      return {
        thumbUrl: window.URL.createObjectURL(file.file),
        fileType: this.getFileType(file.type),
      };
    },
  },
};
</script>

<template>
  <FileUpload
    ref="upload"
    :size="4096 * 2048"
    :accept="allowedFileTypes"
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
