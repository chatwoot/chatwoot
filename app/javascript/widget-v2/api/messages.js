import { client } from './client';

export const fetchMessages = (displayId, { before } = {}) =>
  client
    .get(`/api/v2/widget/conversations/${displayId}/messages`, {
      params: { before },
    })
    .then(response => response.data);

export const createMessage = (displayId, { content, echoId, replyTo }) =>
  client
    .post(`/api/v2/widget/conversations/${displayId}/messages`, {
      message: { content, echo_id: echoId, reply_to: replyTo },
    })
    .then(response => response.data);

export const createAttachmentMessage = (displayId, { attachment, echoId }) => {
  const formData = new FormData();
  formData.append('message[attachments][]', attachment);
  formData.append('message[echo_id]', echoId);
  return client
    .post(`/api/v2/widget/conversations/${displayId}/messages`, formData)
    .then(response => response.data);
};

export const updateMessage = (displayId, messageId, payload) =>
  client
    .patch(
      `/api/v2/widget/conversations/${displayId}/messages/${messageId}`,
      payload
    )
    .then(response => response.data);
