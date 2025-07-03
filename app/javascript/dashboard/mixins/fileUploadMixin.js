import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import {
  MAXIMUM_FILE_UPLOAD_SIZE,
  MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL,
} from 'shared/constants/messages';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { DirectUpload } from 'activestorage';

export default {
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  methods: {
    onFileUpload(file) {
      if (this.globalConfig.directUploadsEnabled) {
        this.onDirectFileUpload(file);
      } else {
        this.onIndirectFileUpload(file);
      }
    },
    onDirectFileUpload(file) {
      const MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE = this.isATwilioSMSChannel
        ? MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL
        : MAXIMUM_FILE_UPLOAD_SIZE;

      if (!file) {
        return;
      }
      if (checkFileSizeLimit(file, MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE)) {
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
      } else {
        useAlert(
          this.$t('CONVERSATION.FILE_SIZE_LIMIT', {
            MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE,
          })
        );
      }
    },
    onIndirectFileUpload(file) {
      const MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE = this.isATwilioSMSChannel
        ? MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL
        : MAXIMUM_FILE_UPLOAD_SIZE;
      if (!file) {
        return;
      }
      if (checkFileSizeLimit(file, MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE)) {
        this.attachFile({ file });
      } else {
        useAlert(
          this.$t('CONVERSATION.FILE_SIZE_LIMIT', {
            MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE,
          })
        );
      }
    },
  },
};
