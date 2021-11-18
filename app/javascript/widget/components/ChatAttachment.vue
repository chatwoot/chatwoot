<template>
  <file-upload
    :size="4096 * 2048"
    accept="image/*, application/pdf, audio/mpeg, video/mp4, audio/ogg, text/csv"
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
import { MAXIMUM_FILE_UPLOAD_SIZE } from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
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
    fileUploadSizeLimit() {
      return MAXIMUM_FILE_UPLOAD_SIZE;
    },
  },
  methods: {
    getFileType(fileType) {
      return fileType.includes('image') ? 'image' : 'file';
    },
    async onFileUpload(file) {
      if (!file) {
        return;
      }
      this.isUploading = true;
      try {
        if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
          const thumbUrl = window.URL.createObjectURL(file.file);
          await this.onAttach({
            fileType: this.getFileType(file.type),
            file: file.file,
            thumbUrl,
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
  },
};
</script>
<style lang="scss">
.file-uploads .attachment-button + label {
  cursor: pointer;
}
</style>
