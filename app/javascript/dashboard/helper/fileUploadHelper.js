import {
  MAXIMUM_FILE_UPLOAD_SIZE,
  MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL,
} from 'shared/constants/messages';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { DirectUpload } from 'activestorage';

export const onDirectFileUpload = (
  file,
  isATwilioSMSChannel,
  attachFile,
  showAlert,
  accountID,
  currentChatID
) => {
  const MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE = isATwilioSMSChannel
    ? MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL
    : MAXIMUM_FILE_UPLOAD_SIZE;

  if (!file) {
    return;
  }
  if (checkFileSizeLimit(file, MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE)) {
    const upload = new DirectUpload(
      file.file,
      `/api/v1/accounts/${accountID}/conversations/${currentChatID}/direct_uploads`,
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
        showAlert({ error });
      } else {
        attachFile({ file, blob });
      }
    });
  } else {
    showAlert({ maxSize: MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE });
  }
};

export const onIndirectFileUpload = (
  file,
  isATwilioSMSChannel,
  attachFile,
  showAlert
) => {
  const MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE = isATwilioSMSChannel
    ? MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL
    : MAXIMUM_FILE_UPLOAD_SIZE;

  if (!file) {
    return;
  }

  if (checkFileSizeLimit(file, MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE)) {
    attachFile({ file });
  } else {
    showAlert({ maxSize: MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE });
  }
};
