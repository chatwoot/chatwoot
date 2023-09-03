import { MESSAGE_TYPE } from 'widget/helpers/constants';
import getUuid from '../../../helpers/uuid';

export const createTemporaryMessage = ({
  attachments,
  content,
  conversationId,
}) => {
  const timestamp = new Date().getTime() / 1000;
  const id = getUuid();
  return {
    id,
    content,
    attachments,
    status: 'in_progress',
    created_at: timestamp,
    conversation_id: conversationId,
    echo_id: id,
    message_type: MESSAGE_TYPE.INCOMING,
  };
};

export const createTemporaryAttachmentMessage = ({
  thumbUrl,
  fileType,
  content,
  conversationId,
}) => {
  const attachment = {
    thumb_url: thumbUrl,
    data_url: thumbUrl,
    file_type: fileType,
    status: 'in_progress',
  };
  const message = createTemporaryMessage({
    attachments: [attachment],
    content,
    conversationId,
  });
  return message;
};

export const createAttachmentParams = ({ attachment }) => {
  const { referrerURL = '' } = window;
  const timestamp = new Date().toString();
  const { file } = attachment;

  const formData = new FormData();
  formData.append('message[attachments][]', file, file.name);
  formData.append('message[referer_url]', referrerURL);
  formData.append('message[timestamp]', timestamp);
  return formData;
};
