import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { getMaxUploadSizeByChannel } from '@chatwoot/utils';
import { DirectUpload } from 'activestorage';
import { MAXIMUM_FILE_UPLOAD_SIZE } from 'shared/constants/messages';

export default {
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },

  methods: {
    maxSizeFor(mime) {
      // Use default file size limit for private notes
      if (this.isOnPrivateNote) {
        return MAXIMUM_FILE_UPLOAD_SIZE;
      }

      return getMaxUploadSizeByChannel({
        channelType: this.inbox?.channel_type,
        medium: this.inbox?.medium, // e.g. 'sms' | 'whatsapp'
        mime, // e.g. 'image/png'
      });
    },
    alertOverLimit(maxSizeMB) {
      useAlert(
        this.$t('CONVERSATION.FILE_SIZE_LIMIT', {
          MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE: maxSizeMB,
        })
      );
    },
    onFileUpload(file) {
      if (this.globalConfig.directUploadsEnabled) {
        this.onDirectFileUpload(file);
      } else {
        this.onIndirectFileUpload(file);
      }
    },

    onDirectFileUpload(file) {
      if (!file) return;

      const mime = file.file?.type || file.type;
      const maxSizeMB = this.maxSizeFor(mime);

      if (!checkFileSizeLimit(file, maxSizeMB)) {
        this.alertOverLimit(maxSizeMB);
        return;
      }

      const upload = new DirectUpload(
        file.file,
        `/api/v1/accounts/${this.accountId}/conversations/${this.currentChat.id}/direct_uploads`,
        {
          directUploadWillCreateBlobWithXHR: xhr => {
            xhr.setRequestHeader(
              'api_access_token',
              this.currentUser.access_token
            );
          },
        }
      );

      upload.create((error, blob) => {
        if (error) {
          useAlert(error);
        } else {
          this.attachFile({ file, blob });
        }
      });
    },

    onIndirectFileUpload(file) {
      if (!file) return;

      const mime = file.file?.type || file.type;
      const maxSizeMB = this.maxSizeFor(mime);

      if (!checkFileSizeLimit(file, maxSizeMB)) {
        this.alertOverLimit(maxSizeMB);
        return;
      }

      this.attachFile({ file });
    },
  },
};
