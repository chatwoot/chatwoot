import { MESSAGE_TYPE } from 'widget/helpers/constants';
import getUuid from '../../../helpers/uuid';

export const createTemporaryMessage = ({ attachments, content }) => {
  const timestamp = new Date().getTime() / 1000;
  return {
    id: getUuid(),
    content,
    attachments,
    status: 'in_progress',
    created_at: timestamp,
    message_type: MESSAGE_TYPE.INCOMING,
  };
};

export const createTemporaryAttachmentMessage = ({
  thumbUrl,
  fileType,
  content,
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
  });
  return message;
};
