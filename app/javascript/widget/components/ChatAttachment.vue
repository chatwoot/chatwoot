<script>
import FileUpload from 'vue-upload-component';
import Spinner from 'shared/components/Spinner.vue';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import {
  MAXIMUM_FILE_UPLOAD_SIZE,
  ALLOWED_FILE_TYPES,
} from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { DirectUpload } from 'activestorage';
import { mapGetters } from 'vuex';
import { emitter } from 'shared/helpers/mitt';

export default {
  components: { FluentIcon, FileUpload, Spinner },
  props: {
    onAttach: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return { isUploading: false };
  },
  computed: {
    ...mapGetters({ 
      globalConfig: 'globalConfig/get',
      attachmentCount: 'conversation/getAttachmentCount',
      attachmentLimit: 'conversation/getAttachmentLimit',
      remainingAttachments: 'conversation/getRemainingAttachments',
      isAttachmentLimitReached: 'conversation/isAttachmentLimitReached'
    }),
    fileUploadSizeLimit() {
      return MAXIMUM_FILE_UPLOAD_SIZE;
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
  },
  methods: {
    handleClipboardPaste(e) {
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
    async onFileUpload(file) {
      // Check attachment limit before upload
      if (this.isAttachmentLimitReached) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('ATTACHMENT_LIMIT_REACHED', {
            ATTACHMENT_LIMIT: this.attachmentLimit,
          }),
        });
        return;
      }

      if (this.globalConfig.directUploadsEnabled) {
        await this.onDirectFileUpload(file);
      } else {
        await this.onIndirectFileUpload(file);
      }
    },
    async onDirectFileUpload(file) {
      if (!file) {
        return;
      }
      this.isUploading = true;
      try {
        if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
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

          upload.create((error, blob) => {
            if (error) {
              emitter.emit(BUS_EVENTS.SHOW_ALERT, {
                message: error,
              });
            } else {
              this.onAttach({
                file: blob.signed_id,
                ...this.getLocalFileAttributes(file),
              });
            }
          });
        } else {
          emitter.emit(BUS_EVENTS.SHOW_ALERT, {
            message: this.$t('FILE_SIZE_LIMIT', {
              MAXIMUM_FILE_UPLOAD_SIZE: this.fileUploadSizeLimit,
            }),
          });
        }
      } catch (error) {
        // Error
      }
      this.isUploading = false;
    },
    async onIndirectFileUpload(file) {
      if (!file) {
        return;
      }
      this.isUploading = true;
      try {
        if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
          await this.onAttach({
            file: file.file,
            ...this.getLocalFileAttributes(file),
          });
        } else {
          emitter.emit(BUS_EVENTS.SHOW_ALERT, {
            message: this.$t('FILE_SIZE_LIMIT', {
              MAXIMUM_FILE_UPLOAD_SIZE: this.fileUploadSizeLimit,
            }),
          });
        }
      } catch (error) {
        // Error
      }
      this.isUploading = false;
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
  <div v-if="!isAttachmentLimitReached">
    <FileUpload
      ref="upload"
      :size="4096 * 2048"
      :accept="allowedFileTypes"
      :multiple="remainingAttachments > 1"
      :maximum="remainingAttachments"
      :data="{
        direct_upload_url: '/api/v1/widget/direct_uploads',
        direct_upload: true,
      }"
      @input-file="onFileUpload"
    >
      <button 
        class="min-h-8 min-w-8 flex items-center justify-center"
        :title="$t('ATTACHMENT_COUNT_INFO', { 
          current: attachmentCount, 
          limit: attachmentLimit 
        })"
      >
        <FluentIcon v-if="!isUploading" icon="attach" />
        <Spinner v-if="isUploading" size="small" />
      </button>
    </FileUpload>
  </div>
  <div v-else class="min-h-8 min-w-8 flex items-center justify-center opacity-50">
    <FluentIcon icon="attach" />
  </div>
</template>
