<template>
  <div class="bottom-box">
    <file-upload
      ref="upload"
      v-tooltip.top-end="$t('CANNED_MGMT.CANNED_BOTTOM_PANEL.TIP_ATTACH_ICON')"
      input-id="cannedAttachment"
      :size="4096 * 4096"
      :accept="allowedFileTypes"
      :multiple="enableMultipleFileUpload"
      :drop="enableDragAndDrop"
      :drop-directory="false"
      :data="{
        direct_upload_url: '/rails/active_storage/direct_uploads',
        direct_upload: true,
      }"
      @input-file="onFileUpload"
    >
      <woot-button
        v-if="showFileUpload"
        class-names="button--upload"
        :title="$t('CANNED_MGMT.CANNED_BOTTOM_PANEL.TIP_ATTACH_ICON')"
        icon="attach"
        emoji="📎"
        color-scheme="secondary"
        variant="smooth"
        size="small"
      />
      <span
        v-if="showAttachHelpText"
        class="text-slate-500 ltr:ml-1 rtl:mr-1 font-medium text-xs dark:text-slate-400"
      >
        {{ $t('CANNED_MGMT.CANNED_BOTTOM_PANEL.ATTACHMENTS.HELP_TEXT') }}
      </span>
    </file-upload>
  </div>
</template>
<script>
import FileUpload from 'vue-upload-component';
import { ALLOWED_FILE_TYPES } from 'shared/constants/messages';
import * as ActiveStorage from 'activestorage';

export default {
  name: 'CannedBottomPanel',
  components: { FileUpload },
  props: {
    onFileUpload: {
      type: Function,
      default: () => {},
    },
    enableMultipleFileUpload: {
      type: Boolean,
      default: true,
    },
    enableDragAndDrop: {
      type: Boolean,
      default: true,
    },
    showFileUpload: {
      type: Boolean,
      default: false,
    },
    showAttachHelpText: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    allowedFileTypes() {
      // TODO: Need to check when mapping to a message
      // if (this.isATwilioWhatsAppChannel) {
      //   return ALLOWED_FILE_TYPES_FOR_TWILIO_WHATSAPP;
      // }
      // if (this.isALineChannel) {
      //   return ALLOWED_FILE_TYPES_FOR_LINE;
      // }
      return ALLOWED_FILE_TYPES;
    },
  },
  mounted() {
    ActiveStorage.start();
  },
};
</script>

<style lang="scss" scoped>
.bottom-box {
  @apply flex py-3 gap-2;
}
::v-deep .file-uploads {
  label {
    @apply cursor-pointer;
  }
  &:hover button {
    @apply dark:bg-slate-800 bg-slate-100;
  }
}
</style>
