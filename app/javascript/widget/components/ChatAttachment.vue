<template>
  <file-upload
    :size="4096 * 2048"
    :accept="allowedFileTypes"
    :data="{
      direct_upload_url: '/rails/active_storage/direct_uploads',
      direct_upload: true,
    }"
    @input-file="onFileUpload"
  >
    <button class="icon-button flex items-center justify-center">
      <fluent-icon v-if="!isUploading.image" icon="attach" />
      <spinner v-if="isUploading" size="small" />
    </button>
  </file-upload>
</template>

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
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    fileUploadSizeLimit() {
      return MAXIMUM_FILE_UPLOAD_SIZE;
    },
    allowedFileTypes() {
      return ALLOWED_FILE_TYPES;
    },
  },
  methods: {
    getFileType(fileType) {
      return fileType.includes('image') ? 'image' : 'file';
    },
    async onFileUpload(file) {
      if (this.globalConfig.directUploadsEnabled) {
        this.onDirectFileUpload(file);
      } else {
        this.onIndirectFileUpload(file);
      }
    },
    async onDirectFileUpload(file) {
      if (!file) {
        return;
      }
      this.isUploading = true;
      try {
        if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
          const upload = new DirectUpload(
            file.file,
            '/rails/active_storage/direct_uploads',
            null,
            file.file.name
          );

          upload.create((error, blob) => {
            if (error) {
              window.bus.$emit(BUS_EVENTS.SHOW_ALERT, {
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
          window.bus.$emit(BUS_EVENTS.SHOW_ALERT, {
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
          window.bus.$emit(BUS_EVENTS.SHOW_ALERT, {
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
