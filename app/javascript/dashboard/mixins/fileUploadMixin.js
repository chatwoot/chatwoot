import {
  MAXIMUM_FILE_UPLOAD_SIZE,
  MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL,
  ALLOWED_FILE_TYPES,
  MAXIMUM_FILE_UPLOAD_SIZE_FOR_WHATSAPP,
  ALLOWED_FILE_TYPES_FOR_FACEBOOK,
  MAXIMUM_FILE_UPLOAD_SIZE_FOR_FACEBOOK,
} from 'shared/constants/messages';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { DirectUpload } from 'activestorage';
import { INBOX_TYPES } from 'shared/mixins/inboxMixin';

export default {
  methods: {
    onFileUpload(file) {
      if (!file) return;
      
      const fileExtension = `.${file.name.split('.').pop()}`.toLowerCase();

      if (this.channelType !== INBOX_TYPES.FB) {
        if (!ALLOWED_FILE_TYPES.includes(fileExtension)) {
          this.showAlert(
            `Please select a valid file format, accepted formats are: ${ALLOWED_FILE_TYPES}`
          );
          return;
        }
      }

      if (this.channelType === INBOX_TYPES.API) {
        const fileUploadSize =
          MAXIMUM_FILE_UPLOAD_SIZE_FOR_WHATSAPP[fileExtension];
        if (!checkFileSizeLimit(file, fileUploadSize)) {
          this.showAlert(
            `File Size exceeds the ${fileUploadSize}MB attachment limit`
          );
          return;
        }
      }

      if (this.channelType === INBOX_TYPES.FB) {
        if (!ALLOWED_FILE_TYPES_FOR_FACEBOOK.includes(fileExtension)) {
          this.showAlert(
            `Please select a valid file format, accepted formats are: ${ALLOWED_FILE_TYPES_FOR_FACEBOOK}`
          );
          return;
        }

        const fileUploadSize =
          MAXIMUM_FILE_UPLOAD_SIZE_FOR_FACEBOOK[fileExtension];
        if (!checkFileSizeLimit(file, fileUploadSize)) {
          this.showAlert(
            `File Size exceeds the ${fileUploadSize}MB attachment limit`
          );
          return;
        }
      }

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
            this.showAlert(error);
          } else {
            this.attachFile({ file, blob });
          }
        });
      } else {
        this.showAlert(
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
        this.showAlert(
          this.$t('CONVERSATION.FILE_SIZE_LIMIT', {
            MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE,
          })
        );
      }
    },
  },
};
