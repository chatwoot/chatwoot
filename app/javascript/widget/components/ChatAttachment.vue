<script>
import FileUpload from 'vue-upload-component';
import { getContrastingTextColor } from '@chatwoot/utils';
import Spinner from 'shared/components/Spinner.vue';
import {
  checkFileSizeLimit,
  resolveMaximumFileUploadSize,
} from 'shared/helpers/FileHelper';
import { ALLOWED_FILE_TYPES } from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { DirectUpload } from 'activestorage';
import { mapGetters } from 'vuex';
import { emitter } from 'shared/helpers/mitt';
import { useAttachments } from '../composables/useAttachments';
import { useScreenCapture } from '../composables/useScreenCapture';
import { useDarkMode } from '../composables/useDarkMode';
import { isEditableImage } from 'shared/helpers/imageEditor';
import ImageEditor from 'shared/components/ImageEditor.vue';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  components: { FluentIcon, FileUpload, ImageEditor, Spinner },
  props: {
    onAttach: {
      type: Function,
      default: () => {},
    },
  },
  emits: ['uploadsChange'],
  setup() {
    const { canHandleAttachments } = useAttachments();
    const { isScreenCaptureSupported, captureScreen } = useScreenCapture();
    const { prefersDarkMode } = useDarkMode();
    const {
      attachmentEditorEnabled,
      screenCaptureEnabled,
      screenCaptureEditorEnabled,
      sendAttachmentsWithMessage,
    } = window.chatwootWebChannel;
    return {
      canHandleAttachments,
      captureScreen,
      prefersDarkMode,
      attachmentEditorEnabled,
      screenCaptureEditorEnabled,
      sendAttachmentsWithMessage,
      showCaptureButton: isScreenCaptureSupported && screenCaptureEnabled,
    };
  },
  data() {
    // A paste can hold several images; the editor shows them one at a time.
    return {
      isUploading: false,
      uploadsInFlight: 0,
      imageQueue: [],
      editedCount: 0,
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      widgetColor: 'appConfig/getWidgetColor',
    }),
    fileUploadSizeLimit() {
      return resolveMaximumFileUploadSize(
        this.globalConfig.maximumFileUploadSize
      );
    },
    allowedFileTypes() {
      return ALLOWED_FILE_TYPES;
    },
    imageToEdit() {
      return this.imageQueue[0];
    },
    // App.vue sets --widget-color on the document root, which the teleported editor also sees.
    confirmClass() {
      const isDarkText =
        getContrastingTextColor(this.widgetColor) === '#000000';
      return [
        'bg-[var(--widget-color)]',
        isDarkText ? 'text-n-black' : 'text-white',
      ];
    },
    hasImageToEdit() {
      return Boolean(this.imageToEdit);
    },
  },
  watch: {
    // A direct upload calls onAttach only when it finishes; the composer waits for it.
    uploadsInFlight(count) {
      this.$emit('uploadsChange', count);
    },
    // The page shows the widget full screen while the editor is open.
    hasImageToEdit(isFullscreen) {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({ event: 'setFullscreen', isFullscreen });
      }
    },
  },
  mounted() {
    document.addEventListener('paste', this.handleClipboardPaste);
  },
  unmounted() {
    document.removeEventListener('paste', this.handleClipboardPaste);
    // The footer can go away with the editor open, such as when the conversation is resolved.
    if (this.hasImageToEdit && IFrameHelper.isIFrame()) {
      IFrameHelper.sendMessage({ event: 'setFullscreen', isFullscreen: false });
    }
  },
  methods: {
    handleClipboardPaste(e) {
      // If file picker is not enabled, do not allow paste
      if (!this.canHandleAttachments) return;
      // The editor is open; a paste would queue an image the user does not see.
      if (this.imageToEdit) return;

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
      if (file && this.attachmentEditorEnabled && isEditableImage(file.type)) {
        this.imageQueue.push(file.file);
        return;
      }
      this.uploadFile(file);
    },
    nextImage() {
      this.imageQueue.shift();
      this.editedCount += 1;
    },
    onEditorSave(file) {
      this.nextImage();
      this.uploadRawFile(file);
    },
    uploadRawFile(file) {
      this.uploadFile({
        file,
        name: file.name,
        type: file.type,
        size: file.size,
      });
    },
    onEditorCancel() {
      this.nextImage();
    },
    async onCaptureScreen() {
      try {
        const file = await this.captureScreen();
        if (!file) return;
        if (this.screenCaptureEditorEnabled) this.imageQueue.push(file);
        else this.uploadRawFile(file);
      } catch (error) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('SCREEN_CAPTURE.ERROR'),
        });
      }
    },
    async uploadFile(file) {
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
        if (checkFileSizeLimit(file, this.fileUploadSizeLimit)) {
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

          this.uploadsInFlight += 1;
          upload.create((error, blob) => {
            this.uploadsInFlight -= 1;
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
        if (checkFileSizeLimit(file, this.fileUploadSizeLimit)) {
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
        fileName: file.name,
      };
    },
  },
};
</script>

<template>
  <div class="flex items-center">
    <FileUpload
      ref="upload"
      :size="4096 * 2048"
      :accept="allowedFileTypes"
      :data="{
        direct_upload_url: '/api/v1/widget/direct_uploads',
        direct_upload: true,
      }"
      @input-file="onFileUpload"
    >
      <button class="min-h-8 min-w-8 flex items-center justify-center">
        <FluentIcon v-if="!isUploading.image" icon="attach" />
        <Spinner v-if="isUploading" size="small" />
      </button>
    </FileUpload>
    <button
      v-if="showCaptureButton"
      class="min-h-8 min-w-8 flex items-center justify-center"
      :aria-label="$t('SCREEN_CAPTURE.BUTTON')"
      :title="$t('SCREEN_CAPTURE.BUTTON')"
      @click="onCaptureScreen"
    >
      <span class="i-lucide-camera size-5" />
    </button>
    <ImageEditor
      v-if="imageToEdit"
      :key="editedCount"
      :file="imageToEdit"
      :confirm-class="confirmClass"
      :max-size-mb="fileUploadSizeLimit"
      :confirm-label="sendAttachmentsWithMessage ? $t('IMAGE_EDITOR.DONE') : ''"
      :is-dark="prefersDarkMode"
      @save="onEditorSave"
      @cancel="onEditorCancel"
    />
  </div>
</template>
